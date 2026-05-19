import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pool_model.dart';
import '../../data/repositories/pool_repository.dart';

final poolListProvider = StateNotifierProvider<PoolListNotifier, AsyncValue<List<PoolModel>>>((ref) {
  return PoolListNotifier();
});

class PoolListNotifier extends StateNotifier<AsyncValue<List<PoolModel>>> {
  final PoolRepository _repo = PoolRepository();

  PoolListNotifier() : super(const AsyncValue.data([]));

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final pools = await _repo.getAll();
      state = AsyncValue.data(pools);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> add(String name, int totalLanes) async {
    await _repo.create(name, totalLanes);
    await load();
  }
}

final lanesProvider = FutureProvider.family<List<LaneModel>, String>((ref, poolId) async {
  final repo = PoolRepository();
  return repo.getLanes(poolId);
});
