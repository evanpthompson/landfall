/// Steps in the first-run setup wizard, in order.
///
/// [serverUrl] is the first step — the operator enters the server's URL.
enum SetupWizardStep { serverUrl, location, linkAccount, done }

sealed class SetupWizardState {
  const SetupWizardState();
}

/// Wizard is idle at the given step, ready for user input.
final class SetupWizardAt extends SetupWizardState {
  const SetupWizardAt(this.step, {this.serverUrl = ''});

  final SetupWizardStep step;

  /// The server URL confirmed in step 1; carried forward for later steps.
  final String serverUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetupWizardAt &&
          step == other.step &&
          serverUrl == other.serverUrl;

  @override
  int get hashCode => Object.hash(step, serverUrl);
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
