import 'package:landfall_shared/landfall_shared.dart';

abstract class CompanionRepository {
  Future<CompanionEntity> getOrCreateForDisplay(String displayId);
}
