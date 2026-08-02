// lib/core/models/dto/week_dto.dart
class WeekDto {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final List<ActivityDto> activities;
  final DateTime createdAt;

  WeekDto({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.activities,
    required this.createdAt,
  });

  factory WeekDto.fromJson(Map<String, dynamic> json) {
    return WeekDto(
      id: json['id'],
      userId: json['userId'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      activities: (json['activities'] as List)
          .map((activity) => ActivityDto.fromJson(activity))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'activities': activities.map((activity) => activity.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ActivityDto {
  final String id;
  final String name;
  final String? globalGoalId; // ID глобальной цели
  final int plannedHours;
  final Map<String, double> spentHours; // {"hourIndex": spentHours}

  ActivityDto({
    required this.id,
    required this.name,
    this.globalGoalId,
    required this.plannedHours,
    required this.spentHours,
  });

  factory ActivityDto.fromJson(Map<String, dynamic> json) {
    final spentHoursMap = json['spentHours'] as Map<String, dynamic>;
    final spentHours = spentHoursMap.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return ActivityDto(
      id: json['id'],
      name: json['name'],
      globalGoalId: json['globalGoalId'],
      plannedHours: json['plannedHours'],
      spentHours: spentHours,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'globalGoalId': globalGoalId,
      'plannedHours': plannedHours,
      'spentHours': spentHours,
    };
  }
}

// Запрос на обновление часов
class UpdateHoursRequest {
  final String activityId;
  final int hourIndex;
  final double spentHours;

  UpdateHoursRequest({
    required this.activityId,
    required this.hourIndex,
    required this.spentHours,
  });

  Map<String, dynamic> toJson() {
    return {
      'activityId': activityId,
      'hourIndex': hourIndex,
      'spentHours': spentHours,
    };
  }
}