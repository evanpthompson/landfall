import '../models/license/integration_pack_info.dart';

abstract class PackRepository {
  Future<List<IntegrationPackInfo>> listPacks();
  Future<List<IntegrationPackInfo>> getOwnedPacks();
}
