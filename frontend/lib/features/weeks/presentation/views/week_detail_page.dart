// lib/features/weeks/presentation/views/week_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_manager/core/models/dto/week_dto.dart';
import '../../../../../../core/widgets/hour_square.dart';
import '../cubit/week_detail_cubit.dart';

import '../../data/repositories/week_repository.dart';

class WeekDetailPage extends StatelessWidget {
  final String weekId;

  const WeekDetailPage({super.key, required this.weekId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WeekDetailCubit(
        repository: context.read<WeekRepository>(),
      )..loadWeek(weekId),
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<WeekDetailCubit, WeekDetailState>(
            builder: (context, state) {
              if (state is WeekDetailLoaded) {
                return Text(
                  'Неделя ${_formatDate(state.week.startDate)} - '
                      '${_formatDate(state.week.endDate)}',
                );
              }
              return const Text('Загрузка...');
            },
          ),
        ),
        body: BlocConsumer<WeekDetailCubit, WeekDetailState>(
          listener: (context, state) {
            // Показываем ошибки
            if (state is WeekDetailError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is WeekDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is WeekDetailError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        context.read<WeekDetailCubit>().loadWeek(weekId);
                      },
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }

            if (state is WeekDetailLoaded) {
              return _buildWeekContent(context, state.week);
            }

            return const Center(child: Text('Нет данных'));
          },
        ),
      ),
    );
  }

  Widget _buildWeekContent(BuildContext context, WeekDto week) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Статистика недели
          _buildWeekStats(week),
          const SizedBox(height: 24),

          // Список активностей
          ...week.activities.map((activity) => _buildActivityCard(
            context,
            activity,
            week.id,
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildWeekStats(WeekDto week) {
    final totalPlanned = week.activities.fold(
        0, (sum, activity) => sum + activity.plannedHours);

    final totalSpent = week.activities.fold(0.0, (sum, activity) {
      final spent = activity.spentHours.values.fold(0.0, (s, h) => s + h);
      return sum + spent;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  '${totalSpent.toInt()}/$totalPlanned',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text('часов'),
              ],
            ),
            Column(
              children: [
                Text(
                  '${((totalSpent / totalPlanned) * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text('выполнено'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(
      BuildContext context,
      ActivityDto activity,
      String weekId,
      ) {
    final cubit = context.read<WeekDetailCubit>();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок активности
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  activity.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_calculateSpentHours(activity)}/${activity.plannedHours} ч',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Прогресс-бар
            LinearProgressIndicator(
              value: _calculateSpentHours(activity) / activity.plannedHours,
            ),

            const SizedBox(height: 16),

            // Квадраты часов
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                activity.plannedHours,
                    (hourIndex) => HourSquare(
                  initialStatus: _getStatus(activity, hourIndex),
                  onStatusChanged: (status) {
                    final spentHours = _convertStatusToHours(status);
                    cubit.updateHour(
                      weekId: weekId,
                      activityId: activity.id,
                      hourIndex: hourIndex,
                      spentHours: spentHours,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  double _calculateSpentHours(ActivityDto activity) {
    return activity.spentHours.values.fold(0.0, (sum, hours) => sum + hours);
  }

  SquareStatus _getStatus(ActivityDto activity, int hourIndex) {
    final spent = activity.spentHours[hourIndex.toString()] ?? 0.0;
    if (spent >= 1.0) return SquareStatus.full;
    if (spent >= 0.5) return SquareStatus.half;
    return SquareStatus.empty;
  }

  double _convertStatusToHours(SquareStatus status) {
    switch (status) {
      case SquareStatus.empty:
        return 0.0;
      case SquareStatus.half:
        return 0.5;
      case SquareStatus.full:
        return 1.0;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}';
  }
}
