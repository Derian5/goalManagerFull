// lib/features/auth/presentation/views/auth_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Контроллеры для входа
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Контроллеры для регистрации
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();

  // Флаги для показа/скрытия пароля
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Очищаем ошибки при переключении вкладок
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        context.read<AuthCubit>().clearError();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  void _login() {
    final cubit = context.read<AuthCubit>();
    cubit.login(
      _loginEmailController.text.trim(),
      _loginPasswordController.text,
    );
  }

  void _register() {
    final cubit = context.read<AuthCubit>();
    cubit.register(
      username: _registerEmailController.text.trim(),
      password: _registerPasswordController.text,
      name: _registerNameController.text.trim(),
      confirmPassword: _registerConfirmPasswordController.text,
    );
  }

  void _switchToLogin() {
    _tabController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }

        if (state is RegistrationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          _switchToLogin();

          // Очищаем поля регистрации
          _registerNameController.clear();
          _registerEmailController.clear();
          _registerPasswordController.clear();
          _registerConfirmPasswordController.clear();
        }

        if (state is AuthSuccess) {
          // TODO: Переход на главный экран
          print('Ты зашёл, ура! Тебя зовут: ${state.user.name}');
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Goal Manager v0.2.3 beta'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Вход'),
                Tab(text: 'Регистрация'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // ВКЛАДКА ВХОДА
              _buildLoginTab(context, state),

              // ВКЛАДКА РЕГИСТРАЦИИ
              _buildRegisterTab(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginTab(BuildContext context, AuthState state) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Приветики!!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Войдите в свой аккаунт',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // Поле username
            TextField(
              controller: _loginEmailController,
              decoration: const InputDecoration(
                labelText: 'Логин',
                prefixIcon: Icon(Icons.login),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
              enabled: state is! AuthLoading,
            ),
            const SizedBox(height: 16),

            // Поле пароля
            TextField(
              controller: _loginPasswordController,
              decoration: InputDecoration(
                labelText: 'Пароль',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureLoginPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureLoginPassword = !_obscureLoginPassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              obscureText: _obscureLoginPassword,
              enabled: state is! AuthLoading,
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 24),

            // Кнопка входа
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: state is AuthLoading ? null : _login,
                child: state is AuthLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text('Войти'),
              ),
            ),
            const SizedBox(height: 16),

            // Ссылка "Забыли пароль?"
            TextButton(
              onPressed: () {
                // TODO: Реализовать восстановление пароля
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Функция восстановления пароля в разработке')),
                );
              },
              child: const Text('Забыли пароль? Жаль'),
            ),
          ],
        ),
      ),
    );
  }
//TODO Убрать Email и оставить только логин
  Widget _buildRegisterTab(BuildContext context, AuthState state) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Создайте аккаунт',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Зарегистрируйтесь, чтобы начать использовать приложение и начать наслаждаться жизнью',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Поле имени
            TextField(
              controller: _registerNameController,
              decoration: const InputDecoration(
                labelText: 'Имя',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
                hintText: 'Введите ваше имя',
              ),
              enabled: state is! AuthLoading,
            ),
            const SizedBox(height: 16),

            // Поле username
            TextField(
              controller: _registerEmailController,
              decoration: const InputDecoration(
                labelText: 'Логин',
                prefixIcon: Icon(Icons.login),
                border: OutlineInputBorder(),
                hintText: 'Введите ваш уникальный логин',
              ),
              keyboardType: TextInputType.text,
              enabled: state is! AuthLoading,
            ),
            const SizedBox(height: 16),

            // Поле пароля
            TextField(
              controller: _registerPasswordController,
              decoration: InputDecoration(
                labelText: 'Пароль',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureRegisterPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureRegisterPassword = !_obscureRegisterPassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
                hintText: 'Минимум 6 символов',
              ),
              obscureText: _obscureRegisterPassword,
              enabled: state is! AuthLoading,
            ),
            const SizedBox(height: 16),

            // Поле подтверждения пароля
            TextField(
              controller: _registerConfirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Подтвердите пароль',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              obscureText: _obscureConfirmPassword,
              enabled: state is! AuthLoading,
              onSubmitted: (_) => _register(),
            ),

            const SizedBox(height: 8),

            // Подсказки для пароля
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPasswordRequirement(
                    'Минимум 6 символов',
                    _registerPasswordController.text.length >= 6,
                  ),
                  _buildPasswordRequirement(
                    'Пароли совпадают',
                    _registerPasswordController.text.isNotEmpty &&
                        _registerPasswordController.text == _registerConfirmPasswordController.text,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Кнопка регистрации
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: state is AuthLoading ? null : _register,
                child: state is AuthLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text('Зарегистрироваться'),
              ),
            ),
            const SizedBox(height: 16),

            // Условия использования
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Регистрируясь, вы будете просто умницей',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // Уже есть аккаунт?
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Уже есть аккаунт? Ну так залетай'),
                TextButton(
                  onPressed: _switchToLogin,
                  child: const Text('Залететь'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.circle,
          size: 16,
          color: isMet ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isMet ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

}
