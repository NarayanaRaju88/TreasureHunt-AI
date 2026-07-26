import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/providers/service_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/treasure_history_model.dart';
import '../models/treasure_model.dart';
import '../repositories/treasure_repository.dart';

/// Aggregated state for treasure discovery screens.
class TreasureState {
  const TreasureState({
    this.daily = const AsyncValue<TreasureModel?>.data(null),
    this.nearby = const <TreasureModel>[],
    this.searchResults = const <TreasureModel>[],
    this.isLoadingNearby = false,
    this.isSearching = false,
    this.isCollecting = false,
    this.error,
  });

  final AsyncValue<TreasureModel?> daily;
  final List<TreasureModel> nearby;
  final List<TreasureModel> searchResults;
  final bool isLoadingNearby;
  final bool isSearching;
  final bool isCollecting;
  final String? error;

  TreasureState copyWith({
    AsyncValue<TreasureModel?>? daily,
    List<TreasureModel>? nearby,
    List<TreasureModel>? searchResults,
    bool? isLoadingNearby,
    bool? isSearching,
    bool? isCollecting,
    String? error,
    bool clearError = false,
  }) {
    return TreasureState(
      daily: daily ?? this.daily,
      nearby: nearby ?? this.nearby,
      searchResults: searchResults ?? this.searchResults,
      isLoadingNearby: isLoadingNearby ?? this.isLoadingNearby,
      isSearching: isSearching ?? this.isSearching,
      isCollecting: isCollecting ?? this.isCollecting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Coordinates treasure loading, searching and collection.
class TreasureNotifier extends StateNotifier<TreasureState> {
  TreasureNotifier(this._repo, this._ref) : super(const TreasureState());

  final TreasureRepository _repo;
  final Ref _ref;

  String? get _uid => _ref.read(currentUserProvider).user?.id;

  /// Loads (and lazily generates) the user's daily treasure at the given
  /// coordinates. Enriches it with AI story/facts in the background.
  Future<void> loadDailyTreasure({
    required double lat,
    required double lng,
    bool forceRegenerate = false,
  }) async {
    final uid = _uid;
    if (uid == null) {
      state = state.copyWith(
        daily: AsyncValue.error(
          const AuthException('Sign in to unlock your daily treasure.'),
          StackTrace.current,
        ),
      );
      return;
    }

    state = state.copyWith(daily: const AsyncValue<TreasureModel?>.loading());
    try {
      final interests = _ref.read(currentUserProvider).user?.interests ??
          const <String>[];
      var treasure = await _repo.getDailyTreasure(
        uid: uid,
        lat: lat,
        lng: lng,
        interests: interests,
        forceRegenerate: forceRegenerate,
      );
      state = state.copyWith(daily: AsyncValue.data(treasure));

      // Enrich asynchronously; update state again when done.
      final enriched = await _repo.enrichTreasure(treasure);
      if (mounted && enriched != treasure) {
        state = state.copyWith(daily: AsyncValue.data(enriched));
      }
    } on AppException catch (e, st) {
      state = state.copyWith(daily: AsyncValue.error(e, st));
    } catch (e, st) {
      state = state.copyWith(daily: AsyncValue.error(e, st));
    }
  }

  /// Loads treasures near the given coordinates.
  Future<void> loadNearby({
    required double lat,
    required double lng,
    String? categoryKey,
  }) async {
    state = state.copyWith(isLoadingNearby: true, clearError: true);
    try {
      final list = await _repo.getNearbyTreasures(
        lat: lat,
        lng: lng,
        categoryKey: categoryKey,
      );
      state = state.copyWith(nearby: list, isLoadingNearby: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoadingNearby: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoadingNearby: false, error: e.toString());
    }
  }

  /// AI natural-language search.
  Future<void> searchTreasures({
    required String query,
    required double lat,
    required double lng,
  }) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: const <TreasureModel>[]);
      return;
    }
    state = state.copyWith(isSearching: true, clearError: true);
    try {
      final results = await _repo.searchTreasures(
        query: query,
        lat: lat,
        lng: lng,
      );
      state = state.copyWith(searchResults: results, isSearching: false);
    } on AppException catch (e) {
      state = state.copyWith(isSearching: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: e.toString());
    }
  }

  void clearSearch() =>
      state = state.copyWith(searchResults: const <TreasureModel>[]);

  /// Collects a treasure and returns the resulting history record (or `null`).
  Future<TreasureHistoryModel?> collectTreasure(
    TreasureModel treasure, {
    double walkingDistance = 0,
    String? userPhotoUrl,
  }) async {
    final uid = _uid;
    if (uid == null) {
      state = state.copyWith(error: 'Sign in to collect treasures.');
      return null;
    }
    state = state.copyWith(isCollecting: true, clearError: true);
    try {
      final history = await _repo.collectTreasure(
        uid: uid,
        treasure: treasure,
        walkingDistance: walkingDistance,
        userPhotoUrl: userPhotoUrl,
      );

      // Reflect collection in local state (daily + nearby lists).
      final collected = treasure.copyWith(
        isCollected: true,
        collectedAt: history.collectedAt,
      );
      final updatedNearby = state.nearby
          .map((t) => t.id == treasure.id ? collected : t)
          .toList();
      final updatedDaily = state.daily.maybeWhen(
        data: (d) => d?.id == treasure.id
            ? AsyncValue<TreasureModel?>.data(collected)
            : state.daily,
        orElse: () => state.daily,
      );
      state = state.copyWith(
        isCollecting: false,
        nearby: updatedNearby,
        daily: updatedDaily,
      );
      return history;
    } on AppException catch (e) {
      state = state.copyWith(isCollecting: false, error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(isCollecting: false, error: e.toString());
      return null;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

/// Primary treasure state provider.
final treasureProvider =
    StateNotifierProvider<TreasureNotifier, TreasureState>((ref) {
  return TreasureNotifier(ref.watch(treasureRepositoryProvider), ref);
});

/// Derived: the daily treasure as an [AsyncValue].
final dailyTreasureProvider = Provider<AsyncValue<TreasureModel?>>((ref) {
  return ref.watch(treasureProvider.select((s) => s.daily));
});

/// Derived: the current nearby treasure list.
final treasureListProvider = Provider<List<TreasureModel>>((ref) {
  return ref.watch(treasureProvider.select((s) => s.nearby));
});

/// Derived: current search results.
final treasureSearchResultsProvider = Provider<List<TreasureModel>>((ref) {
  return ref.watch(treasureProvider.select((s) => s.searchResults));
});

/// User discovery history (auto-fetched for the signed-in user).
final treasureHistoryProvider =
    FutureProvider.autoDispose<List<TreasureHistoryModel>>((ref) async {
  final uid = ref.watch(currentUserProvider).user?.id;
  if (uid == null) return const <TreasureHistoryModel>[];
  final repo = ref.watch(treasureRepositoryProvider);
  return repo.getHistory(uid);
});
