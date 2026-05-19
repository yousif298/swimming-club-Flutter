import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';

final customerListProvider = StateNotifierProvider<CustomerListNotifier, AsyncValue<List<CustomerModel>>>((ref) {
  return CustomerListNotifier();
});

class CustomerListNotifier extends StateNotifier<AsyncValue<List<CustomerModel>>> {
  final CustomerRepository _repo = CustomerRepository();

  CustomerListNotifier() : super(const AsyncValue.data([]));

  Future<void> load({String? search}) async {
    state = const AsyncValue.loading();
    try {
      final customers = await _repo.getAll(search: search);
      state = AsyncValue.data(customers);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> add(String fullName, String phone, String? address) async {
    await _repo.create(fullName, phone, address);
    await load();
  }
}
