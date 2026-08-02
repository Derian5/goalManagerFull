// lib/core/widgets/week_card.dart
import 'package:flutter/material.dart';
import '../models/dto/week_dto.dart';

class WeekCard extends StatelessWidget {
  final WeekDto week;
  final VoidCallback onTap;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const WeekCard({
    super.key,
    required this.week,
    required this.onTap,
    required this.onCopy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Вычисляем статистику
    final stats = _calculateStats(week);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с датами
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateRange(week.startDate, week.endDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'copy':
                          onCopy();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 20),
                            SizedBox(width: 8),
                            Text('Скопировать'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Удалить', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Статистика
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    'Цели',
                    '${week.activities.length}',
                    Icons.flag,
                  ),
                  _buildStatItem(
                    context,
                    'Часы',
                    '${stats['completedHours']}/${stats['totalHours']}',
                    Icons.access_time,
                  ),
                  _buildStatItem(
                    context,
                    'Прогресс',
                    '${stats['progress']}%',
                    Icons.trending_up,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Прогресс-бар
              LinearProgressIndicator(
                value: stats['progress'] / 100,
                backgroundColor: Colors.grey[200],
                color: _getProgressColor(stats['progress']),
              ),

              const SizedBox(height: 8),

              // Дата создания
              Text(
                'Создано: ${_formatDate(week.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context,
      String title,
      String value,
      IconData icon,
      ) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _calculateStats(WeekDto week) {
    int totalHours = 0;
    double completedHours = 0;

    for (final activity in week.activities) {
      totalHours += activity.plannedHours;
      completedHours += activity.spentHours.values.fold(0.0, (sum, h) => sum + h);
    }

    final progress = totalHours > 0 ? (completedHours / totalHours) * 100 : 0;

    return {
      'totalHours': totalHours,
      'completedHours': completedHours.toInt(),
      'progress': progress.round(),
    };
  }

  Color _getProgressColor(double progress) {
    if (progress >= 75) return Colors.green;
    if (progress >= 50) return Colors.orange;
    return Colors.red;
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final startStr = '${start.day}.${start.month}';
    final endStr = '${end.day}.${end.month}.${end.year}';
    return '$startStr - $endStr';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дней назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}