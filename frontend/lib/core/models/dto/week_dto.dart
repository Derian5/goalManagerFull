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
    final activitiesJson = json['activities'];

    return WeekDto(
      id: json['id']?.toString() ?? '',
      userId: (json['userId'] ?? json['user_id'])?.toString() ?? '',
      startDate: DateTime.parse(json['startDate'] ?? json['start_date']),
      endDate: DateTime.parse(json['endDate'] ?? json['end_date']),
      activities: (activitiesJson is List ? activitiesJson : const [])
          .map((activity) => ActivityDto.fromJson(
                Map<String, dynamic>.from(activity as Map),
              ))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
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
    final spentHoursJson = json['spentHours'] ?? json['spent_hours'];
    final spentHoursMap = spentHoursJson is Map<String, dynamic>
        ? spentHoursJson
        : <String, dynamic>{};
    final spentHours = spentHoursMap.map(
      (key, value) => MapEntry(key, value is num ? value.toDouble() : 0.0),
    );

    return ActivityDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      globalGoalId:
          (json['globalGoalId'] ?? json['global_goal_id'])?.toString(),
      plannedHours: json['plannedHours'] ?? json['planned_hours'] ?? 0,
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
