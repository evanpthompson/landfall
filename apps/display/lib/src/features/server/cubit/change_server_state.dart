part of 'change_server_cubit.dart';

sealed class ChangeServerState {
  const ChangeServerState();
}

/// Awaiting input. [error] holds the message from the last failed attempt.
final class ChangeServerEditing extends ChangeServerState {
  const ChangeServerEditing({this.error});

  final String? error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeServerEditing && error == other.error;

  @override
  int get hashCode => error.hashCode;
}

/// Checking the submitted URL's reachability.
final class ChangeServerValidating extends ChangeServerState {
  const ChangeServerValidating();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ChangeServerValidating;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// The new URL passed validation and was persisted; the UI should relaunch.
final class ChangeServerSaved extends ChangeServerState {
  const ChangeServerSaved(this.serverUrl);

  final String serverUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeServerSaved && serverUrl == other.serverUrl;

  @override
  int get hashCode => serverUrl.hashCode;
}
