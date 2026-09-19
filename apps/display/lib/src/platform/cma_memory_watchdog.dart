import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A snapshot of the kernel CMA (Contiguous Memory Allocator) pool, in kB.
///
/// On the Raspberry Pi the `vc4` GPU has no IOMMU, so every GPU buffer —
/// framebuffers and decoded image textures alike — is allocated from CMA.
/// When CMA fills, `dmabuf` export starts failing ("Failed to export gem bo
/// to dmabuf") and image rendering breaks. This type lets the app watch the
/// pool and react before that happens.
@immutable
class CmaStatus {
  const CmaStatus({required this.totalKb, required this.freeKb});

  final int totalKb;
  final int freeKb;

  /// Free fraction in `[0, 1]`. A zero-sized pool reads as `1.0` (treated as
  /// "not under pressure") so callers on CMA-less kernels never trip.
  double get freeFraction => totalKb <= 0 ? 1.0 : freeKb / totalKb;

  /// Parses the contents of `/proc/meminfo`. Returns null when either
  /// `CmaTotal` or `CmaFree` is absent — e.g. a kernel built without CMA, or
  /// a non-Linux host where the file does not exist.
  static CmaStatus? parseMeminfo(String meminfo) {
    int? total;
    int? free;
    for (final line in const LineSplitter().convert(meminfo)) {
      if (line.startsWith('CmaTotal:')) {
        total = _firstInt(line);
      } else if (line.startsWith('CmaFree:')) {
        free = _firstInt(line);
      }
    }
    if (total == null || free == null) return null;
    return CmaStatus(totalKb: total, freeKb: free);
  }

  static int? _firstInt(String line) {
    final match = RegExp(r'(\d+)').firstMatch(line);
    return match == null ? null : int.parse(match.group(1)!);
  }
}

/// Reads the current CMA snapshot, or null if it cannot be determined.
typedef CmaReader = CmaStatus? Function();

/// Releases memory the app is holding (decoded image textures) so the kernel
/// can reclaim the underlying CMA regions.
typedef MemoryReclaimer = void Function();

/// Watches the kernel CMA pool and, when free memory drops to a configurable
/// fraction of the pool, releases the app's image textures so CMA can be
/// reclaimed.
///
/// CMA itself cannot be "garbage collected" from userspace — it is kernel
/// managed. What the app *can* do is drop the references that pin it: clear
/// Flutter's image cache and signal the engine to purge unlocked GPU/Skia
/// resources. Once those textures are unreferenced the kernel frees the
/// regions. This is a defensive backstop; the primary fix is decoding photos
/// at display resolution (see `kMaxPhotoDecodeEdge` in `photo_frame_card`).
///
/// Reclaiming is deliberately rare. On the Pi the framebuffer itself is CMA,
/// so free memory can sit under the pressure threshold indefinitely; firing on
/// every tick meant purging and re-uploading every texture every 15 seconds,
/// which is the stall this class exists to prevent, plus a photo that
/// re-decodes so often it looks broken. Two brakes prevent that:
///
/// * a **cooldown** — at most one reclaim per [reclaimCooldown];
/// * **hysteresis** — after firing, the watchdog re-arms early only once free
///   memory climbs back above [recoveryThreshold], so hovering at the
///   threshold counts as one episode rather than many.
class CmaMemoryWatchdog {
  CmaMemoryWatchdog({
    double pressureThreshold = 0.15,
    double recoveryThreshold = 0.25,
    Duration reclaimCooldown = const Duration(minutes: 5),
    CmaReader? read,
    MemoryReclaimer? reclaim,
    DateTime Function()? now,
  })  : assert(
          pressureThreshold > 0 && pressureThreshold < 1,
          'pressureThreshold must be a fraction in (0, 1)',
        ),
        assert(
          recoveryThreshold >= pressureThreshold,
          'recoveryThreshold must be at or above pressureThreshold',
        ),
        _threshold = pressureThreshold,
        _recoveryThreshold = recoveryThreshold,
        _cooldown = reclaimCooldown,
        _read = read ?? _readProcMeminfo,
        _reclaim = reclaim ?? _defaultReclaim,
        _now = now ?? DateTime.now;

  final double _threshold;
  final double _recoveryThreshold;
  final Duration _cooldown;
  final CmaReader _read;
  final MemoryReclaimer _reclaim;
  final DateTime Function() _now;
  Timer? _timer;

  /// When the reclaimer last ran. Null until it has run once.
  DateTime? _lastReclaimAt;

  /// False while inside a pressure episode that has already been reclaimed.
  bool _armed = true;

  /// Reads CMA once and, if free memory is at or below [pressureThreshold] of
  /// the pool, runs the reclaimer. Returns true if reclamation fired.
  ///
  /// Returns false — without reclaiming — when the pool is unreadable (a
  /// non-Linux host or a CMA-less kernel reads as null, so this is safe to
  /// call anywhere), when there is no pressure, or when the cooldown since the
  /// last reclaim has not elapsed.
  bool tick() {
    final status = _read();
    if (status == null) return false;

    if (status.freeFraction > _threshold) {
      // Recovered past the upper threshold: the next dip is a new episode and
      // may reclaim immediately.
      if (status.freeFraction >= _recoveryThreshold) _armed = true;
      return false;
    }

    if (!_armed && !_cooldownElapsed()) return false;

    _reclaim();
    _lastReclaimAt = _now();
    _armed = false;
    return true;
  }

  bool _cooldownElapsed() {
    final last = _lastReclaimAt;
    if (last == null) return true;
    return _now().difference(last) >= _cooldown;
  }

  /// Begins polling [tick] on [interval]. Idempotent: a second call while
  /// already running is ignored.
  void start({Duration interval = const Duration(seconds: 15)}) {
    _timer ??= Timer.periodic(interval, (_) => tick());
  }

  /// Stops polling. Safe to call when not started.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static CmaStatus? _readProcMeminfo() {
    if (kIsWeb || !Platform.isLinux) return null;
    try {
      return CmaStatus.parseMeminfo(
        File('/proc/meminfo').readAsStringSync(),
      );
    } catch (_) {
      return null;
    }
  }

  static void _defaultReclaim() {
    dev.log(
      'CMA pressure: releasing cached image textures',
      name: 'landfall.cma',
    );
    // Only the cache, not the live set: clearing live images drops the photo
    // currently on screen, which is then decoded again immediately. That
    // costs a visible blank frame and frees nothing for longer than an
    // instant.
    PaintingBinding.instance.imageCache.clear();
    // Drops decoded-image references and asks the engine to purge unlocked
    // GPU/Skia resources back to CMA. The Linux embedder never fires a
    // low-memory signal on its own, so we trigger the same path manually.
    WidgetsBinding.instance.handleMemoryPressure();
  }
}
