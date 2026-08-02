// lib/features/weeks/data/repositories/week_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/dto/week_dto.dart';

class WeekRepository {
  final ApiService apiService;

  WeekRepository({required this.apiService});

  Future<List<WeekDto>> getWeeks() async {
    try {
      return await apiService.getWeeks();
    } catch (e) {
      debugPrint('WeekRepository getWeeks error: $e');
      rethrow;
    }
  }

  Future<WeekDto> getWeek(String weekId) async {
    try {
      return await apiService.getWeek(weekId);
    } catch (e) {
      debugPrint('WeekRepository getWeek error: $e');
      rethrow;
    }
  }

  Future<WeekDto> createWeek(WeekDto week) async {
    try {
      return await apiService.createWeek(week);
    } catch (e) {
      debugPrint('WeekRepository createWeek error: $e');
      debugPrint(jsonEncode(week.toJson()));
      rethrow;
    }
  }

  Future<WeekDto> updateWeekHours(
      String weekId,
      UpdateHoursRequest request,
      ) async {
    try {

      return await apiService.updateWeekHours(weekId, request);
    } catch (e) {
      debugPrint(weekId + " " + jsonEncode(request.toJson()));
      debugPrint('WeekRepository updateWeekHours error: $e');
      rethrow;
    }
  }
  Future<void> deleteWeek(String weekId) async {
    try {
      await apiService.deleteWeek(weekId);
    } catch (e) {
      debugPrint('WeekRepository deleteWeek error: $e');
      rethrow;
    }
  }
}