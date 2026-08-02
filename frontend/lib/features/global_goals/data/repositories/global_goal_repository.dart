import 'package:flutter/foundation.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/dto/global_goal_dto.dart';
import 'dart:async';

class GlobalGoalRepository {
  final ApiService apiService;

  GlobalGoalRepository({required this.apiService});

  Future<GlobalGoalsResponse> getGlobalGoals({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
  }) async {
    try {
      return await apiService.getGlobalGoals(
        page: page,
        limit: limit,
        search: search,
        category: category,
      );
    } catch (e) {
      debugPrint('GlobalGoalRepository getGlobalGoals error: $e');
      rethrow;
    }
  }

  Future<GlobalGoalDto> getGlobalGoal(String goalId) async {
    try {
      return await apiService.getGlobalGoal(goalId);
    } catch (e) {
      debugPrint('GlobalGoalRepository getGlobalGoal error: $e');
      rethrow;
    }
  }

  Future<GlobalGoalDto> createGlobalGoal(CreateGlobalGoalRequest request) async {
    try {
      return await apiService.createGlobalGoal(request);
    } catch (e) {
      debugPrint('GlobalGoalRepository createGlobalGoal error: $e');
      rethrow;
    }
  }

  Future<GlobalGoalDto> updateGlobalGoal(
      String goalId,
      CreateGlobalGoalRequest request,
      ) async {
    try {
      return await apiService.updateGlobalGoal(goalId, request);
    } catch (e) {
      debugPrint('GlobalGoalRepository updateGlobalGoal error: $e');
      rethrow;
    }
  }

  Future<void> deleteGlobalGoal(String goalId) async {
    try {
      await apiService.deleteGlobalGoal(goalId);
    } catch (e) {
      debugPrint('GlobalGoalRepository deleteGlobalGoal error: $e');
      rethrow;
    }
  }

  Future<List<GlobalGoalDto>> getGlobalGoalsForWeek(String weekId) async {
    try {
      return await apiService.getGlobalGoalsForWeek(weekId);
    } catch (e) {
      debugPrint('GlobalGoalRepository getGlobalGoalsForWeek error: $e');
      rethrow;
    }
  }

  // Метод для получения целей, которые можно добавить в неделю
  Future<List<GlobalGoalDto>> getAvailableGoalsForWeek(String weekId) async {
    try {
      // Получаем все цели пользователя
      final allGoals = await apiService.getGlobalGoals();

      // Получаем цели, уже добавленные в неделю
      final weekGoals = await apiService.getGlobalGoalsForWeek(weekId);

      // Фильтруем: оставляем только те, которые ещё не добавлены
      final weekGoalIds = weekGoals.map((goal) => goal.id).toSet();

      return allGoals.goals
          .where((goal) => !weekGoalIds.contains(goal.id))
          .toList();
    } catch (e) {
      debugPrint('GlobalGoalRepository getAvailableGoalsForWeek error: $e');
      rethrow;
    }
  }
}