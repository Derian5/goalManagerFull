import 'dart:ui';

import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4A6FA5);    // Основной синий
  static const Color secondary = Color(0xFF166088);  // Тёмный синий
  static const Color accent = Color(0xFFDB5461);     // Акцентный красный
  static const Color background = Color(0xFFF5F5F5); // Фоновый серый
  static const Color text = Color(0xFF333333);       // Текст
  static const Color success = Color(0xFF4CAF50);    // Зелёный для успеха
  static const Color warning = Color(0xFFFF9800);    // Оранжевый для предупреждений

  // Цвета для статусов квадратов
  static const Color squareEmpty = Colors.white;
  static const Color squareHalf = Color(0x804A6FA5); // Полупрозрачный синий
  static const Color squareFull = Color(0xFF4A6FA5); // Полностью синий
}