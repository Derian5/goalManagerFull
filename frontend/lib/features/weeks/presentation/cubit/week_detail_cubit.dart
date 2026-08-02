// lib/features/weeks/presentation/cubit/week_detail_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/week_repository.dart';
import '../../../../core/models/dto/week_dto.dart';

// Состояния
abstract class WeekDetailState {
  const WeekDetailState();
}

class WeekDetailInitial extends WeekDetailState {}
class WeekDetailLoading extends WeekDetailState {}
class WeekDetailLoaded extends WeekDetailState {
  final WeekDto week;
  const WeekDetailLoaded(this.week);
}
class WeekDetailError extends WeekDetailState {
  final String message;
  const WeekDetailError(this.message);
}

// Cubit
class WeekDetailCubit extends Cubit<WeekDetailState> {
  final WeekRepository _repository;

  WeekDetailCubit({required WeekRepository repository})
      : _repository = repository,
        super(WeekDetailInitial());

  Future<void> loadWeek(String weekId) async {
    emit(WeekDetailLoading());

    try {
      final week = await _repository.getWeek(weekId);
      emit(WeekDetailLoaded(week));
    } catch (e) {
      emit(WeekDetailError(e.toString()));
    }
  }

  Future<void> updateHour({
    required String weekId,
    required String activityId,
    required int hourIndex,
    required double spentHours,
  }) async {
    final currentState = state;
    if (currentState is! WeekDetailLoaded) return;

    try {
      // Оптимистичное обновление UI
      final updatedWeek = _updateWeekOptimistically(
        currentState.week,
        activityId,
        hourIndex,
        spentHours,
      );
      emit(WeekDetailLoaded(updatedWeek));

      // Отправляем на сервер
      await _repository.updateWeekHours(
        weekId,
        UpdateHoursRequest(
          activityId: activityId,
          hourIndex: hourIndex,
          spentHours: spentHours,
        ),
      );

      // Получаем актуальные данные с сервера
      final freshWeek = await _repository.getWeek(weekId);
      emit(WeekDetailLoaded(freshWeek));

    } catch (e) {
      // В случае ошибки откатываем изменения
      emit(WeekDetailLoaded(currentState.week));
      // Можно показать snackbar с ошибкой
      emit(WeekDetailError('Не удалось сохранить: ${e.toString()}'));
    }
  }

  WeekDto _updateWeekOptimistically(
      WeekDto week,
      String activityId,
      int hourIndex,
      double spentHours,
      ) {
    final updatedActivities = week.activities.map((activity) {
      if (activity.id == activityId) {
        final updatedSpentHours = Map<String, double>.from(activity.spentHours);
        updatedSpentHours[hourIndex.toString()] = spentHours;

        return ActivityDto(
          id: activity.id,
          name: activity.name,
          globalGoalId: activity.globalGoalId,
          plannedHours: activity.plannedHours,
          spentHours: updatedSpentHours,
        );
      }
      return activity;
    }).toList();

    return WeekDto(
      id: week.id,
      userId: week.userId,
      startDate: week.startDate,
      endDate: week.endDate,
      activities: updatedActivities,
      createdAt: week.createdAt,
    );
  }
}