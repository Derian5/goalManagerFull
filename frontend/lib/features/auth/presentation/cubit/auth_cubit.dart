// lib/features/auth/presentation/cubit/auth_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/models/dto/auth_dto.dart';

// Состояния
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final UserDto user;
  const AuthSuccess(this.user);
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class RegistrationSuccess extends AuthState {
  final String message;
  const RegistrationSuccess(this.message);
}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit({required AuthRepository repository})
      : _repository = repository,
        super(AuthInitial());

  Future<void> login(String username, String password) async {
    emit(AuthLoading());

    try {
      final response = await _repository.login(username, password);
      emit(AuthSuccess(response.user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> register({
    required String username,
    required String password,
    required String name,
    required String confirmPassword,
  }) async {
    // Валидация на клиенте
    if (username.isEmpty || password.isEmpty || name.isEmpty) {
      emit(AuthError('Все поля обязательны для заполнения'));
      return;
    }

    if (password != confirmPassword) {
      emit(AuthError('Пароли не совпадают'));
      return;
    }

    if (password.length < 6) {
      emit(AuthError('Пароль должен содержать минимум 6 символов'));
      return;
    }

    if (username.isEmpty) {
      emit(AuthError('Введите логин'));
      return;
    }

    emit(AuthLoading());

    try {
      await _repository.register(username, password, name);
      emit(RegistrationSuccess(
          'Регистрация прошла успешно! Теперь вы можете войти.'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    emit(AuthInitial());
  }

  void clearError() {
    if (state is AuthError) {
      emit(AuthInitial());
    }
  }
}
