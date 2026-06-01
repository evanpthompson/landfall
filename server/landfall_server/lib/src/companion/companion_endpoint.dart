import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../net/lan_base_url.dart';

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
  /// Delegates to [resolveLanBaseUrl] so the companion page and the
  /// device-auth `/device` page can never drift on how the LAN-reachable
  /// host is resolved. The phone scanning the QR must be on the same LAN as
  /// the host; the URL is not designed to be internet-reachable.
  Future<String> getCompanionBaseUrl(Session session) => resolveLanBaseUrl();

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
