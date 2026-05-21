import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({this.status = AuthStatus.unknown, this.user, this.error});

  AuthState copyWith({AuthStatus? status, User? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider), ref.read(storageServiceProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final StorageService _storage;

  AuthNotifier(this._authService, this._storage) : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final hasToken = await _storage.hasToken();
    if (hasToken) {
      state = state.copyWith(status: AuthStatus.authenticated);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> register(String phone, String code, String password) async {
    try {
      final data = await _authService.register(phone, code, password);
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> login(String phone, String password) async {
    try {
      final data = await _authService.login(phone, password);
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
