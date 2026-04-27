import 'package:landfall_client/landfall_client.dart';
import 'package:landfall_shared/landfall_shared.dart';

/// Production [LicenseRepository] backed by [LicenseEndpoint].
class ServerpodLicenseRepository implements LicenseRepository {
  const ServerpodLicenseRepository(this._client);

  final Client _client;

  @override
  Future<LicenseStatus> getLicenseStatus() async {
    final response = await _client.license.getLicenseStatus();
    return _fromResponse(response);
  }

  @override
  Future<LicenseStatus> activateLicense(String key) async {
    final response = await _client.license.activateLicense(key);
    return _fromResponse(response);
  }

  LicenseStatus _fromResponse(LicenseStatusResponse r) {
    return LicenseStatus(
      tier: LicenseTier.fromString(r.tier),
      activatedAt: r.activatedAt,
      maskedKey: r.maskedKey,
    );
  }
}
