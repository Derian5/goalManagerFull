// lib/features/global_goals/presentation/views/global_goals_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/dto/global_goal_dto.dart';
import '../cubit/global_goal_cubit.dart';
import 'goal_editor_dialog.dart';

class GlobalGoalsPage extends StatefulWidget {
  const GlobalGoalsPage({super.key});

  @override
  State<GlobalGoalsPage> createState() => _GlobalGoalsPageState();
}

class _GlobalGoalsPageState extends State<GlobalGoalsPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GlobalGoalCubit>().loadGoals();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      context.read<GlobalGoalCubit>().loadGoals();
    }
  }

  void _showCreateGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => GoalEditorDialog(
        onSave: (request) {
          context.read<GlobalGoalCubit>().createGoal(request);
        },
      ),
    );
  }

  void _showEditGoalDialog(GlobalGoalDto goal) {
    showDialog(
      context: context,
      builder: (context) => GoalEditorDialog(
        goal: goal,
        onSave: (request) {
          context.read<GlobalGoalCubit>().updateGoal(goal.id, request);
        },
      ),
    );
  }

  void _deleteGoal(String goalId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить цель?'),
        content: const Text('Вы уверены, что хотите удалить эту цель?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              context.read<GlobalGoalCubit>().deleteGoal(goalId);
              Navigator.pop(context);
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
        title: const Text('Глобальные цели'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateGoalDialog,
            tooltip: 'Добавить цель',
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск целей...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<GlobalGoalCubit>().loadGoals(refresh: true);
                  },
                )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  context.read<GlobalGoalCubit>().loadGoals(refresh: true);
                }
              },
              onSubmitted: (value) {
                context.read<GlobalGoalCubit>().searchGoals(value);
              },
            ),
          ),

          // Список целей
          Expanded(
            child: BlocConsumer<GlobalGoalCubit, GlobalGoalState>(
              listener: (context, state) {
                if (state is GlobalGoalError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                if (state is GlobalGoalLoading &&
                    (state is! GlobalGoalsLoaded || (state as GlobalGoalsLoaded).goals.isEmpty)) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is GlobalGoalError &&
                    (state is! GlobalGoalsLoaded || (state as GlobalGoalsLoaded).goals.isEmpty)) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            context.read<GlobalGoalCubit>().loadGoals(refresh: true);
                          },
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  );
                }

                List<GlobalGoalDto> goals = [];
                bool isLoadingMore = false;

                if (state is GlobalGoalsLoaded) {
                  goals = state.goals;
                } else if (state is GlobalGoalLoading) {
                  // Сохраняем предыдущие цели во время загрузки
                  final currentState = context.read<GlobalGoalCubit>().state;
                  if (currentState is GlobalGoalsLoaded) {
                    goals = currentState.goals;
                    isLoadingMore = true;
                  }
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: goals.length + (isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= goals.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final goal = goals[index];
                    return _buildGoalCard(context, goal);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, GlobalGoalDto goal) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _parseColor(goal.color),
          child: Text(
            goal.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          goal.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: goal.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (goal.description != null && goal.description!.isNotEmpty)
              Text(
                goal.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (goal.category != null && goal.category!.isNotEmpty)
              Chip(
                label: Text(goal.category!),
                visualDensity: VisualDensity.compact,
              ),
            Text(
              'Создано: ${_formatDate(goal.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditGoalDialog(goal);
                break;
              case 'delete':
                _deleteGoal(goal.id);
                break;
              case 'toggle':
              // TODO: Добавить переключение активности
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Редактировать'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(Icons.toggle_on, size: 20),
                  SizedBox(width: 8),
                  Text('Активировать/деактивировать'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Удалить', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Переход к деталям цели
        },
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue; // Цвет по умолчанию
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}