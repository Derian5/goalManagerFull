// lib/core/models/dto/global_goal_dto.dart
class GlobalGoalDto {
  final String id;
  final String userId;
  final String name;
  final String? description;    // nullable
  final String? category;       // nullable
  final String color;
  final DateTime createdAt;
  final DateTime? updatedAt;    // nullable
  final bool isActive;

  GlobalGoalDto({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.category,
    this.color = "#4A6FA5",
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory GlobalGoalDto.fromJson(Map<String, dynamic> json) {
    return GlobalGoalDto(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],  // может быть null
      category: json['category'],        // может быть null
      color: json['color'] ?? "#4A6FA5",
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      isActive: json['isActive'] ?? true,
    );
  }
}

// Запрос на создание/обновление глобальной цели
class CreateGlobalGoalRequest {
  final String name;
  final String? description;
  final String? category;
  final String color;

  CreateGlobalGoalRequest({
    required this.name,
    this.description,
    this.category,
    this.color = "#4A6FA5",
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'color': color,
    };
  }
}

// Класс для ответа с пагинацией
class GlobalGoalsResponse {
  final List<GlobalGoalDto> goals;
  final int total;
  final int page;
  final int limit;

  GlobalGoalsResponse({
    required this.goals,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory GlobalGoalsResponse.fromJson(Map<String, dynamic> json) {
    return GlobalGoalsResponse(
      goals: (json['goals'] as List)
          .map((goal) => GlobalGoalDto.fromJson(goal))
          .toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
    );
  }
}