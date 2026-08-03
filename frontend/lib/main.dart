// Обновляем lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

// Core
import 'core/services/api_service.dart';

// Features
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/views/auth_page.dart';

import 'features/global_goals/data/repositories/global_goal_repository.dart';
import 'features/global_goals/presentation/cubit/global_goal_cubit.dart';
import 'features/global_goals/presentation/views/global_goals_page.dart';

import 'features/weeks/data/repositories/week_repository.dart';
import 'features/weeks/presentation/cubit/week_list_cubit.dart';
import 'features/weeks/presentation/views/week_list_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Создаём экземпляры сервисов и репозиториев
    final apiService = ApiService();

    final authRepository = AuthRepository(apiService: apiService);
    final globalGoalRepository = GlobalGoalRepository(apiService: apiService);
    final weekRepository = WeekRepository(apiService: apiService);

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<GlobalGoalRepository>.value(value: globalGoalRepository),
        Provider<WeekRepository>.value(value: weekRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (context) => AuthCubit(
              repository: context.read<AuthRepository>(),
            ),
          ),
          BlocProvider<GlobalGoalCubit>(
            create: (context) => GlobalGoalCubit(
              repository: context.read<GlobalGoalRepository>(),
            ),
          ),
          BlocProvider<WeekListCubit>(
            create: (context) => WeekListCubit(
              repository: context.read<WeekRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Time Manager',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          home: const AuthWrapper(),
          routes: {
            '/auth': (context) => const AuthPage(),
            '/goals': (context) => const GlobalGoalsPage(),
            '/weeks': (context) => const WeekListPage(),
          },
        ),
      ),
    );
  }
}

// Проверяем, авторизован ли пользователь
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          // При успешной авторизации переходим на главный экран
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const MainApp(),
              ),
            );
          });
        }
      },
      child: FutureBuilder<bool>(
        future: context.read<ApiService>().isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data == true) {
            return const MainApp(); // Пользователь уже авторизован
          } else {
            return const AuthPage(); // Пользователь не авторизован
          }
        },
      ),
    );
  }
}

// Создаём MainApp для авторизованных пользователей
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  // Список страниц
  final List<Widget> _pages = [
    const WeekListPage(),
    const GlobalGoalsPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Недели',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: 'Цели',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle,
                  size: 72, color: Colors.blueGrey),
              const SizedBox(height: 16),
              const Text(
                'Вы вошли в Goal Manager',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Если сессия устарела или хотите сменить аккаунт, выйдите и войдите заново.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Выйти из аккаунта'),
                  onPressed: () async {
                    await context.read<AuthCubit>().logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const AuthPage()),
                      (_) => false,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
