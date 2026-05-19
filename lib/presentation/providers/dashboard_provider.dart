import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/repositories/dashboard_repository.dart';

final dashboardProvider = StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardModel>>((ref) {
  return DashboardNotifier();
});

class DashboardNotifier extends StateNotifier<AsyncValue<DashboardModel>> {
  final DashboardRepository _repo = DashboardRepository();

  DashboardNotifier() : super(AsyncValue.data(DashboardModel()));

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repo.getDashboard();
      state = AsyncValue.data(data);
    } catch (e) {
      state = AsyncValue.data(DashboardModel());
    }
  }
}
