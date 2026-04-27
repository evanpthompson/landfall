import 'package:landfall_shared/src/models/license/license_status.dart';

abstract class LicenseRepository {
  Future<LicenseStatus> getLicenseStatus();
  Future<LicenseStatus> activateLicense(String key);
}
