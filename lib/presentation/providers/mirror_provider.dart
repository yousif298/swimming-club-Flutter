import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/mirror_model.dart';
import '../../data/repositories/booking_repository.dart';

class MirrorState {
  final AsyncValue<MirrorViewModel?> data;
  final String? selectedBookingTypeId;
  MirrorState({required this.data, this.selectedBookingTypeId});
}

final mirrorProvider = StateNotifierProvider<MirrorNotifier, MirrorState>((ref) {
  return MirrorNotifier();
});

class MirrorNotifier extends StateNotifier<MirrorState> {
  final BookingRepository _repo = BookingRepository();
  String? _currentPoolId;
  DateTime? _currentDate;

  MirrorNotifier() : super(MirrorState(data: const AsyncValue.data(null)));

  Future<void> load(String poolId, DateTime date, {String? bookingTypeId}) async {
    _currentPoolId = poolId;
    _currentDate = date;
    state = MirrorState(data: const AsyncValue.loading(), selectedBookingTypeId: bookingTypeId);
    try {
      final mirror = await _repo.getMirrorView(poolId, date, bookingTypeId: bookingTypeId);
      state = MirrorState(data: AsyncValue.data(mirror), selectedBookingTypeId: bookingTypeId);
    } catch (e) {
      state = MirrorState(data: AsyncValue.error(e, StackTrace.current), selectedBookingTypeId: bookingTypeId);
    }
  }

  void setBookingTypeFilter(String? bookingTypeId) {
    if (_currentPoolId != null && _currentDate != null) {
      load(_currentPoolId!, _currentDate!, bookingTypeId: bookingTypeId);
    }
  }
}
