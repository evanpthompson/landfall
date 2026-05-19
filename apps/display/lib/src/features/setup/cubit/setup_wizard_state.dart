import 'package:display/src/data/discovery/mdns_server_discovery.dart';

/// Steps in the first-run setup wizard, in order.
///
/// [discover] is step 1 — scans the LAN for Landfall servers via mDNS.
/// [serverUrl] is step 1b — manual URL fallback shown when discovery finds
/// nothing or the user chooses "Enter manually".
enum SetupWizardStep { discover, serverUrl, location, linkAccount, done }

sealed class SetupWizardState {
  const SetupWizardState();
}

/// Wizard is idle at the given step, ready for user input.
final class SetupWizardAt extends SetupWizardState {
  const SetupWizardAt(
    this.step, {
    this.serverUrl = '',
    this.discoveredServers = const [],
  });

  final SetupWizardStep step;

  /// The server URL confirmed in step 1; carried forward for later steps.
  final String serverUrl;

  /// Live list of servers found via mDNS. Populated while on the [discover]
  /// step; empty on all other steps.
  final List<DiscoveredServer> discoveredServers;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetupWizardAt &&
          step == other.step &&
          serverUrl == other.serverUrl &&
          _listsEqual(discoveredServers, other.discoveredServers);

  @override
  int get hashCode => Object.hash(step, serverUrl, discoveredServers);
}

bool _listsEqual<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The cubit is running an async operation (connectivity check or DB write).
final class SetupWizardValidating extends SetupWizardState {
  const SetupWizardValidating();

  @override
  bool operator ==(Object other) => other is SetupWizardValidating;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// An operation failed. The wizard returns to the given step with an error.
final class SetupWizardStepError extends SetupWizardState {
  const SetupWizardStepError(this.message, this.step);

  final String message;
  final SetupWizardStep step;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetupWizardStepError &&
          message == other.message &&
          step == other.step;

  @override
  int get hashCode => Object.hash(message, step);
}

/// Setup is complete. The app should rebuild [LandfallApp] with [serverUrl].
final class SetupWizardComplete extends SetupWizardState {
  const SetupWizardComplete({required this.serverUrl});

  final String serverUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetupWizardComplete && serverUrl == other.serverUrl;

  @override
  int get hashCode => serverUrl.hashCode;
}
