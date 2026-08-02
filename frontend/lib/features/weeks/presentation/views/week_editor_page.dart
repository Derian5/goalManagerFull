// lib/features/weeks/presentation/views/week_editor_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/dto/week_dto.dart';
import '../../../../core/models/dto/global_goal_dto.dart';
import '../../../global_goals/presentation/views/goal_editor_dialog.dart';
import '../cubit/week_list_cubit.dart';
import '../../../global_goals/data/repositories/global_goal_repository.dart';
import '../../../global_goals/presentation/cubit/global_goal_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class WeekEditorPage extends StatefulWidget {
  const WeekEditorPage({super.key});

  @override
  State<WeekEditorPage> createState() => _WeekEditorPageState();
}

class _WeekEditorPageState extends State<WeekEditorPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  final List<GlobalGoalDto> _selectedGoals = [];
  final Map<String, int> _plannedHours = {}; // goalId -> plannedHours

  @override
  void initState() {
    super.initState();
    // Загружаем глобальные цели
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GlobalGoalCubit>().loadGoals();
    });
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Автоматически устанавливаем конец недели (+6 дней)
        _endDate = picked.add(const Duration(days: 6));
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала выберите дату начала')),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!.add(const Duration(days: 6)),
      firstDate: _startDate!,
      lastDate: _startDate!.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _toggleGoalSelection(GlobalGoalDto goal) {
    setState(() {
      if (_selectedGoals.contains(goal)) {
        _selectedGoals.remove(goal);
        _plannedHours.remove(goal.id);
      } else {
        _selectedGoals.add(goal);
        _plannedHours[goal.id] = 5; // По умолчанию 5 часов
      }
    });
  }

  void _updatePlannedHours(String goalId, int hours) {
    setState(() {
      _plannedHours[goalId] = hours;
    });
  }

  void _createWeek() {
    if (!_validateForm()) return;

    // Получаем текущего пользователя из AuthCubit
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess) {
      // На случай, если вдруг авторизация потеряна
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка авторизации. Войдите заново.')),
      );
      Navigator.pushReplacementNamed(context, '/auth'); // если есть именованные маршруты
      return;
    }

    final userId = authState.user.id;

    // Создаём активности из выбранных целей
    final activities = _selectedGoals.map((goal) {
      return ActivityDto(
        id: '', // Сервер создаст ID
        name: goal.name,
        globalGoalId: goal.id,
        plannedHours: _plannedHours[goal.id] ?? 5,
        spentHours: {},
      );
    }).toList();

    // Создаём неделю
    final week = WeekDto(
      id: '', // Сервер создаст ID
      userId: userId, // теперь реальный ID
      startDate: _startDate!,
      endDate: _endDate!,
      activities: activities,
      createdAt: DateTime.now(),
    );

    // Сохраняем
    context.read<WeekListCubit>().createWeek(week);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Неделя создана')),
    );
  }

  bool _validateForm() {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите дату начала')),
      );
      return false;
    }

    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите дату окончания')),
      );
      return false;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Дата окончания должна быть после даты начала')),
      );
      return false;
    }

    if (_selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы одну цель')),
      );
      return false;
    }

    return true;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Не выбрано';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание недели'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Выбор дат
              const Text(
                'Даты недели',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      'Начало недели',
                      _startDate,
                          () => _selectStartDate(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      'Конец недели',
                      _endDate,
                          () => _selectEndDate(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Выбор целей
              const Text(
                'Выберите цели',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              BlocBuilder<GlobalGoalCubit, GlobalGoalState>(
                builder: (context, state) {
                  List<GlobalGoalDto> goals = [];

                  if (state is GlobalGoalsLoaded) {
                    goals = state.goals;
                  } else if (state is GlobalGoalLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is GlobalGoalError) {
                    return Center(
                      child: Column(
                        children: [
                          Text(state.message),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              context.read<GlobalGoalCubit>().loadGoals();
                            },
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (goals.isEmpty) {
                    return Column(
                      children: [
                        const Text('Нет созданных целей'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            final result = await showDialog<CreateGlobalGoalRequest>(
                              context: context,
                              builder: (context) => GoalEditorDialog(
                                onSave: (request) => Navigator.pop(context, request),
                              ),
                            );
                            if (result != null) {
                              // Создаём цель через GlobalGoalCubit
                              context.read<GlobalGoalCubit>().createGoal(result);
                              // После создания список целей обновится автоматически через BlocBuilder
                            }
                          },
                          child: const Text('Создать цель'),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      // Список целей
                      ...goals.map((goal) {
                        final isSelected = _selectedGoals.contains(goal);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected ? Colors.blue[50] : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _parseColor(goal.color),
                              child: Text(
                                goal.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(goal.name),
                            subtitle: goal.description != null
                                ? Text(goal.description!)
                                : null,
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleGoalSelection(goal),
                            ),
                            onTap: () => _toggleGoalSelection(goal),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Настройка часов для выбранных целей
              if (_selectedGoals.isNotEmpty) ...[
                const Text(
                  'Планируемые часы',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ..._selectedGoals.map((goal) {
                  final hours = _plannedHours[goal.id] ?? 5;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (goal.description != null)
                                  Text(
                                    goal.description!,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Слайдер или поле ввода для часов
                          SizedBox(
                            width: 150,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    if (hours > 1) {
                                      _updatePlannedHours(goal.id, hours - 1);
                                    }
                                  },
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '$hours',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    if (hours < 40) {
                                      _updatePlannedHours(goal.id, hours + 1);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

                // Итого часов
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Всего часов на неделю:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_plannedHours.values.fold(0, (sum, hours) => sum + hours)} ч',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Кнопка создания
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _createWeek,
                  child: const Text('Создать неделю'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(
      String label,
      DateTime? date,
      VoidCallback onTap,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Text(_formatDate(date)),
                const Spacer(),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}