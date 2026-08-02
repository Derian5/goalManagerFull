// lib/features/weeks/presentation/cubit/week_list_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/week_repository.dart';
import '../../../../core/models/dto/week_dto.dart';

// Состояния
abstract class WeekListState {
  const WeekListState();
}

class WeekListInitial extends WeekListState {}
class WeekListLoading extends WeekListState {}
class WeeksLoaded extends WeekListState {
  final List<WeekDto> weeks;
  const WeeksLoaded(this.weeks);
}
class WeekListError extends WeekListState {
  final String message;
  const WeekListError(this.message);
}
class WeekCreated extends WeekListState {
  final WeekDto week;
  const WeekCreated(this.week);
}
class WeekDeleted extends WeekListState {
  final String weekId;
  const WeekDeleted(this.weekId);
}

// Cubit для управления списком недель
class WeekListCubit extends Cubit<WeekListState> {
  final WeekRepository _repository;

  WeekListCubit({required WeekRepository repository})
      : _repository = repository,
        super(WeekListInitial());

  // Загрузка всех недель пользователя
  Future<void> loadWeeks() async {
    emit(WeekListLoading());

    try {
      final weeks = await _repository.getWeeks();
      // Сортируем по дате (самые новые первыми)
      weeks.sort((a, b) => b.startDate.compareTo(a.startDate));
      emit(WeeksLoaded(weeks));
    } catch (e) {
      emit(WeekListError(e.toString()));
    }
  }

  // Создание новой недели
  Future<void> createWeek(WeekDto week) async {
    try {
      emit(WeekListLoading());
      final createdWeek = await _repository.createWeek(week);

      // Обновляем список
      final currentState = state;
      if (currentState is WeeksLoaded) {
        final updatedWeeks = [createdWeek, ...currentState.weeks];
        updatedWeeks.sort((a, b) => b.startDate.compareTo(a.startDate));
        emit(WeekCreated(createdWeek));
        emit(WeeksLoaded(updatedWeeks));
      } else {
        await loadWeeks(); // Перезагружаем, если список пустой
      }
    } catch (e) {
      emit(WeekListError(e.toString()));
    }
  }

  // Удаление недели
  Future<void> deleteWeek(String weekId) async {
    try {
      emit(WeekListLoading());
      await _repository.deleteWeek(weekId);   // реальное удаление
      await loadWeeks();
    } catch (e) {
      emit(WeekListError(e.toString()));
    }
  }

  // Получение недели по ID
  WeekDto? getWeekById(String weekId) {
    final currentState = state;
    if (currentState is WeeksLoaded) {
      try {
        return currentState.weeks.firstWhere((week) => week.id == weekId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Копирование недели (создание на основе существующей)
  Future<void> copyWeek(String sourceWeekId) async {
    try {
      emit(WeekListLoading());

      // Получаем исходную неделю
      final sourceWeek = await _repository.getWeek(sourceWeekId);

      // Создаём новую неделю на основе старой
      final newStartDate = DateTime.now();
      final newEndDate = newStartDate.add(const Duration(days: 6));

      final newWeek = WeekDto(
        id: '', // Сервер создаст новый ID
        userId: sourceWeek.userId,
        startDate: newStartDate,
        endDate: newEndDate,
        activities: sourceWeek.activities.map((activity) {
          // Копируем активности, но обнуляем spentHours
          return ActivityDto(
            id: '', // Сервер создаст новый ID
            name: activity.name,
            globalGoalId: activity.globalGoalId,
            plannedHours: activity.plannedHours,
            spentHours: {}, // Начинаем с чистого листа
          );
        }).toList(),
        createdAt: DateTime.now(),
      );

      // Сохраняем новую неделю
      await createWeek(newWeek);
    } catch (e) {
      emit(WeekListError(e.toString()));
    }
  }
}