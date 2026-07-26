import '../models/treasure_model.dart';

abstract class TreasureRepository {
  Future<TreasureModel?> generateDailyTreasure({
    required double latitude,
    required double longitude,
    required String weather,
    required List<String> interests,
  });

  Future<List<TreasureModel>> getNearbyTreasures({
    required double latitude,
    required double longitude,
    required double radiusInKm,
  });

  Future<void> saveTreasure(TreasureModel treasure);
  Future<List<TreasureModel>> getSavedTreasures();
  Future<void> markTreasureAsCollected(String treasureId);
  Future<List<TreasureModel>> getCollectedTreasures();
}
