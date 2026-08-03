// lib/features/weeks/presentation/views/week_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_manager/core/models/dto/week_dto.dart';
import 'package:goal_manager/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goal_manager/features/auth/presentation/views/auth_page.dart';
import 'package:goal_manager/features/weeks/presentation/views/week_detail_page.dart';
import '../../../../core/widgets/week_card.dart';
import '../cubit/week_list_cubit.dart';
import 'week_editor_page.dart';

class WeekListPage extends StatefulWidget {
  const WeekListPage({super.key});

  @override
  State<WeekListPage> createState() => _WeekListPageState();
}

class _WeekListPageState extends State<WeekListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeekListCubit>().loadWeeks();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToWeekDetail(String weekId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeekDetailPage(weekId: weekId),
      ),
    );
    if (!mounted) return;
    context.read<WeekListCubit>().loadWeeks();
  }

  void _navigateToWeekEditor() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WeekEditorPage(),
      ),
    );
    if (!mounted) return;
    context.read<WeekListCubit>().loadWeeks();
  }

  String _cleanError(String message) {
    return message.replaceFirst('Exception: ', '');
  }

  void _copyWeek(String weekId) {
    context.read<WeekListCubit>().copyWeek(weekId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Неделя скопирована')),
    );
  }

  void _deleteWeek(String weekId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить неделю?'),
        content: const Text('Вы уверены, что хотите удалить эту неделю?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              context.read<WeekListCubit>().deleteWeek(weekId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Неделя удалена')),
              );
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои недели'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToWeekEditor,
            tooltip: 'Создать неделю',
          ),
        ],
      ),
      body: BlocConsumer<WeekListCubit, WeekListState>(
        listener: (context, state) {
          if (state is WeekListError) {
            final message = _cleanError(state.message);
            if (message.contains('Требуется авторизация')) {
              context.read<AuthCubit>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthPage()),
                (_) => false,
              );
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        },
        builder: (context, state) {
          if (state is WeekListLoading && state is! WeeksLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WeekListError && state is! WeeksLoaded) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_cleanError(state.message), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      context.read<WeekListCubit>().loadWeeks();
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          List<WeekDto> weeks = [];

          if (state is WeeksLoaded) {
            weeks = state.weeks;
          } else if (state is WeekListLoading) {
            // Сохраняем предыдущие недели во время загрузки
            final currentState = context.read<WeekListCubit>().state;
            if (currentState is WeeksLoaded) {
              weeks = currentState.weeks;
            }
          }

          if (weeks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Нет созданных недель',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Создайте свою первую неделю для планирования',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _navigateToWeekEditor,
                    child: const Text('Создать неделю'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await context.read<WeekListCubit>().loadWeeks();
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: weeks.length,
              itemBuilder: (context, index) {
                final week = weeks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: WeekCard(
                    week: week,
                    onTap: () => _navigateToWeekDetail(week.id),
                    onCopy: () => _copyWeek(week.id),
                    onDelete: () => _deleteWeek(week.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
