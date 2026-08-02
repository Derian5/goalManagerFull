// lib/features/global_goals/presentation/cubit/global_goal_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/global_goal_repository.dart';
import '../../../../core/models/dto/global_goal_dto.dart';


// Состояния
abstract class GlobalGoalState {
  const GlobalGoalState();
}

class GlobalGoalInitial extends GlobalGoalState {}
class GlobalGoalLoading extends GlobalGoalState {}
class GlobalGoalsLoaded extends GlobalGoalState {
  final List<GlobalGoalDto> goals;
  final bool hasMore;
  final int page;
  const GlobalGoalsLoaded({
    required this.goals,
    this.hasMore = true,
    this.page = 1,
  });
}
class GlobalGoalError extends GlobalGoalState {
  final String message;
  const GlobalGoalError(this.message);
}
class GlobalGoalCreated extends GlobalGoalState {
  final GlobalGoalDto goal;
  const GlobalGoalCreated(this.goal);
}
class GlobalGoalUpdated extends GlobalGoalState {
  final GlobalGoalDto goal;
  const GlobalGoalUpdated(this.goal);
}
class GlobalGoalDeleted extends GlobalGoalState {
  final String goalId;
  const GlobalGoalDeleted(this.goalId);
}

// Cubit
class GlobalGoalCubit extends Cubit<GlobalGoalState> {
  final GlobalGoalRepository _repository;
  final List<GlobalGoalDto> _allGoals = [];
  int _currentPage = 1;
  bool _hasMore = true;
  String? _currentSearch;
  String? _currentCategory;

  GlobalGoalCubit({required GlobalGoalRepository repository})
      : _repository = repository,
        super(GlobalGoalInitial());

  // Загрузка целей с пагинацией
  Future<void> loadGoals({
    bool refresh = false,
    String? search,
    String? category,
  }) async {
    try {
      if (refresh) {
        _allGoals.clear();
        _currentPage = 1;
        _hasMore = true;
        _currentSearch = search;
        _currentCategory = category;
        emit(GlobalGoalLoading());
      } else if (state is GlobalGoalLoading) {
        return;
      }

      if (!_hasMore && !refresh) return;

      final response = await _repository.getGlobalGoals(
        page: _currentPage,
        limit: 20,
        search: search ?? _currentSearch,
        category: category ?? _currentCategory,
      );

      _allGoals.addAll(response.goals);
      _hasMore = (_allGoals.length < response.total);
      _currentPage++;

      emit(GlobalGoalsLoaded(
        goals: List.from(_allGoals),
        hasMore: _hasMore,
        page: _currentPage - 1,
      ));
    } catch (e) {
      emit(GlobalGoalError(e.toString()));
    }
  }

  // Создание новой цели
  Future<void> createGoal(CreateGlobalGoalRequest request) async {
    try {
      emit(GlobalGoalLoading());
      final newGoal = await _repository.createGlobalGoal(request);

      // Добавляем в начало списка
      _allGoals.insert(0, newGoal);

      emit(GlobalGoalCreated(newGoal));
      emit(GlobalGoalsLoaded(
        goals: List.from(_allGoals),
        hasMore: _hasMore,
        page: _currentPage,
      ));
    } catch (e) {
      emit(GlobalGoalError(e.toString()));
    }
  }

  // Обновление цели
  Future<void> updateGoal(
      String goalId,
      CreateGlobalGoalRequest request,
      ) async {
    try {
      emit(GlobalGoalLoading());
      final updatedGoal = await _repository.updateGlobalGoal(goalId, request);

      // Обновляем в списке
      final index = _allGoals.indexWhere((goal) => goal.id == goalId);
      if (index != -1) {
        _allGoals[index] = updatedGoal;
      }

      emit(GlobalGoalUpdated(updatedGoal));
      emit(GlobalGoalsLoaded(
        goals: List.from(_allGoals),
        hasMore: _hasMore,
        page: _currentPage,
      ));
    } catch (e) {
      emit(GlobalGoalError(e.toString()));
    }
  }

  // Удаление цели
  Future<void> deleteGoal(String goalId) async {
    try {
      emit(GlobalGoalLoading());
      await _repository.deleteGlobalGoal(goalId);

      // Удаляем из списка
      _allGoals.removeWhere((goal) => goal.id == goalId);

      emit(GlobalGoalDeleted(goalId));
      emit(GlobalGoalsLoaded(
        goals: List.from(_allGoals),
        hasMore: _hasMore,
        page: _currentPage,
      ));
    } catch (e) {
      emit(GlobalGoalError(e.toString()));
    }
  }

  // Поиск целей
  Future<void> searchGoals(String query) async {
    await loadGoals(refresh: true, search: query);
  }

  // Фильтрация по категории
  Future<void> filterByCategory(String? category) async {
    await loadGoals(refresh: true, category: category);
  }

  // Получение цели по ID
  GlobalGoalDto? getGoalById(String goalId) {
    return _allGoals.firstWhere(
          (goal) => goal.id == goalId,
      orElse: () => throw Exception('Goal not found'),
    );
  }
}