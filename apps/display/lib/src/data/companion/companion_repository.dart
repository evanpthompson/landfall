import 'package:landfall_shared/landfall_shared.dart';

abstract class CompanionRepository {
  Future<CompanionEntity> getOrCreateForDisplay(String displayId);

  /// Returns the LAN-reachable base URL a phone should hit to scan the
  /// companion QR. Empty string when the server cannot derive one — the
  /// client falls back to its build-time `LANDFALL_WEB_SERVER_URL` define.
  Future<String> getCompanionBaseUrl();
}
