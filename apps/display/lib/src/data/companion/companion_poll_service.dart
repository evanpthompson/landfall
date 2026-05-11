import 'package:landfall_client/landfall_client.dart' as lf;

abstract class CompanionPollService {
  Future<lf.CompanionAction?> pollForEvents(
    String displayId, {
    int timeoutSeconds = 30,
  });
}

class ClientCompanionPollService implements CompanionPollService {
  ClientCompanionPollService(this._client);

  final lf.Client _client;

  @override
  Future<lf.CompanionAction?> pollForEvents(
    String displayId, {
    int timeoutSeconds = 30,
  }) =>
      _client.companion.pollForEvents(
        displayId,
        timeoutSeconds: timeoutSeconds,
      );
}
