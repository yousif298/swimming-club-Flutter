import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<bool>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<bool>> {
  final AuthRepository _repo = AuthRepository();

  AuthNotifier() : super(const AsyncValue.data(false));

  Future<bool> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repo.login(username, password);
      state = const AsyncValue.data(true);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(false);
  }
}
