import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/mirror_model.dart';
import '../../data/repositories/booking_repository.dart';

final mirrorProvider = StateNotifierProvider<MirrorNotifier, AsyncValue<MirrorViewModel?>>((ref) {
  return MirrorNotifier();
});

class MirrorNotifier extends StateNotifier<AsyncValue<MirrorViewModel?>> {
  final BookingRepository _repo = BookingRepository();

  MirrorNotifier() : super(const AsyncValue.data(null));

  Future<void> load(String poolId, DateTime date) async {
    state = const AsyncValue.loading();
    try {
      final mirror = await _repo.getMirrorView(poolId, date);
      state = AsyncValue.data(mirror);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final slotStatusProvider = FutureProvider.family<SlotStatusModel, ({String poolId, String laneId, String slotId, DateTime date})>((ref, params) async {
  final repo = BookingRepository();
  return repo.getSlotStatus(params.poolId, params.laneId, params.slotId, params.date);
});
