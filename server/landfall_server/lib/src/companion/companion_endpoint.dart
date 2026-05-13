import 'dart:async';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Companion server endpoint.
///
/// Owns the per-display companion entity (one row per display, seeded once)
/// and the phone→TV event delivery channel via long-polling.
///
/// Delivery model:
/// - TV calls [pollForEvents] which blocks until either an action arrives
///   or the timeout elapses (returns null on timeout).
/// - Phone calls [pushAction] which completes any pending poll for that
///   display, or enqueues the action if no TV is currently polling.
/// - State is in-memory: server restart drops pending actions and forces
///   TVs to reconnect their poll. Acceptable for alpha — actions are
///   ephemeral by design.
class CompanionEndpoint extends Endpoint {
  /// Per-display pending state. Lazily created, cleaned up when both the
  /// pending queue and the waiter list are empty.
  static final Map<String, _PendingState> _pending = {};

  /// Cap on the per-display pending queue. If a display has no active poll
  /// and actions pile up, drop the oldest after this many entries. Keeps
  /// memory bounded if a phone misbehaves.
  static const int _maxQueuePerDisplay = 10;

  /// Returns the companion entity for [displayId], creating it on first
  /// access. MVP seeds every display with Lumen — Phase 22+ will use the
  /// displayId hash to seed an xrandom draw across the full creature pool.
  Future<CompanionEntity> getOrCreateForDisplay(
    Session session,
    String displayId,
  ) async {
    final existing = await CompanionEntity.db.findFirstRow(
      session,
      where: (t) => t.displayId.equals(displayId),
    );
    if (existing != null) return existing;

    final entity = CompanionEntity(
      displayId: displayId,
      seed: displayId.hashCode,
      rarityTier: 'uncommon',
      speciesId: 'lumen',
      name: 'Lumen',
      traits: 'curious,gentle',
      evolutionStage: 0,
      createdAt: DateTime.now().toUtc(),
      assetCredit: '@changhaoliao via petdex (crafter.run)',
    );
    return CompanionEntity.db.insertRow(session, entity);
  }

  /// Long-polls for the next companion action targeted at [displayId].
  ///
  /// Returns the action as soon as one is pushed via [pushAction], or null
  /// if [timeoutSeconds] elapses with no action. Clients should immediately
  /// reissue the poll on either outcome.
  ///
  /// If actions are already queued for this display (pushed while no poll
  /// was active), the oldest is returned immediately.
  Future<CompanionAction?> pollForEvents(
    Session session,
    String displayId, {
    int timeoutSeconds = 30,
  }) async {
    final state = _pending.putIfAbsent(displayId, _PendingState.new);

    // Drain queued action immediately if one is waiting.
    if (state.queue.isNotEmpty) {
      final action = state.queue.removeAt(0);
      _maybeCleanup(displayId);
      return action;
    }

    final completer = Completer<CompanionAction?>();
    state.waiters.add(completer);

    final timer = Timer(Duration(seconds: timeoutSeconds), () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    try {
      return await completer.future;
    } finally {
      timer.cancel();
      state.waiters.remove(completer);
      _maybeCleanup(displayId);
    }
  }

  /// Pushes a [kind] action for [displayId], typically called from the
  /// phone web page tap handler.
  ///
  /// If a TV is currently long-polling for this display, the action is
  /// delivered to it immediately. Otherwise the action is queued
  /// (capped at [_maxQueuePerDisplay] — oldest dropped on overflow).
  Future<void> pushAction(
    Session session,
    String displayId,
    String kind,
  ) async {
    final action = CompanionAction(
      kind: kind,
      timestamp: DateTime.now().toUtc(),
    );

    final state = _pending.putIfAbsent(displayId, _PendingState.new);

    // Wake the oldest waiter, if any.
    while (state.waiters.isNotEmpty) {
      final waiter = state.waiters.removeAt(0);
      if (!waiter.isCompleted) {
        waiter.complete(action);
        _maybeCleanup(displayId);
        return;
      }
    }

    // No active poll — enqueue, drop oldest if over cap.
    state.queue.add(action);
    while (state.queue.length > _maxQueuePerDisplay) {
      state.queue.removeAt(0);
    }
  }

  /// Returns the base URL a phone should hit to load `/c/{displayId}`.
  ///
  /// Resolution order:
  ///   1. `LANDFALL_DOMAIN` env var (set by `firstboot.sh` on Pi images) →
  ///      `https://$LANDFALL_DOMAIN`. This is the Caddy-fronted hostname
  ///      that mDNS resolves on the household LAN.
  ///   2. The host's first non-loopback, non-link-local RFC1918 IPv4 address
  ///      with the default web port (`:8082`). Covers macOS / Fire TV
  ///      development where no Caddy is in front.
  ///   3. Empty string — the client falls back to its build-time
  ///      `LANDFALL_WEB_SERVER_URL` define.
  ///
  /// The phone scanning the QR must be on the same LAN as the host for
  /// either branch to work; the URL is not designed to be internet-reachable.
  Future<String> getCompanionBaseUrl(Session session) async {
    final domain = Platform.environment['LANDFALL_DOMAIN'];
    if (domain != null && domain.isNotEmpty) {
      return 'https://$domain';
    }
    final lan = await _firstLanIpv4();
    if (lan != null) {
      return 'http://$lan:8082';
    }
    return '';
  }

  static Future<String?> _firstLanIpv4() async {
    try {
      final ifaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );
      for (final iface in ifaces) {
        for (final addr in iface.addresses) {
          if (_isPrivateLanIpv4(addr.address)) {
            return addr.address;
          }
        }
      }
    } on SocketException {
      // No interfaces — degrade to fallback URL.
    }
    return null;
  }

  static bool _isPrivateLanIpv4(String address) {
    final parts = address.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((p) => p == null)) return false;
    final a = parts[0]!, b = parts[1]!;
    if (a == 10) return true;
    if (a == 172 && b >= 16 && b <= 31) return true;
    if (a == 192 && b == 168) return true;
    return false;
  }

  /// Test-only: clears the in-memory waiter/queue state. Lets unit tests
  /// run in isolation without cross-test bleed from the static map.
  static void resetForTests() => _pending.clear();

  void _maybeCleanup(String displayId) {
    final state = _pending[displayId];
    if (state == null) return;
    if (state.queue.isEmpty && state.waiters.isEmpty) {
      _pending.remove(displayId);
    }
  }
}

class _PendingState {
  final List<CompanionAction> queue = [];
  final List<Completer<CompanionAction?>> waiters = [];
}
