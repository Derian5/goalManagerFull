// lib/features/global_goals/presentation/views/goal_editor_dialog.dart
import 'package:flutter/material.dart';
import '../../../../core/models/dto/global_goal_dto.dart';

class GoalEditorDialog extends StatefulWidget {
  final GlobalGoalDto? goal;
  final Function(CreateGlobalGoalRequest) onSave;

  const GoalEditorDialog({
    super.key,
    this.goal,
    required this.onSave,
  });

  @override
  State<GoalEditorDialog> createState() => _GoalEditorDialogState();
}

class _GoalEditorDialogState extends State<GoalEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  // Цвета для выбора
  final List<Color> availableColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameController.text = widget.goal!.name;
      _descriptionController.text = widget.goal!.description ?? '';
      _categoryController.text = widget.goal!.category ?? '';
      _selectedColor = _parseColor(widget.goal!.color);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}';
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final request = CreateGlobalGoalRequest(
        name: _nameController.text,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        category: _categoryController.text.isNotEmpty
            ? _categoryController.text
            : null,
        color: _colorToHex(_selectedColor),
      );

      widget.onSave(request);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.goal == null ? 'Новая цель' : 'Редактировать цель'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Название цели
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название цели *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название цели';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Описание
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание (необязательно)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Категория
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Категория (необязательно)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Выбор цвета
              const Text('Выберите цвет:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                        border: _selectedColor.value == color.value
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saveGoal,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}