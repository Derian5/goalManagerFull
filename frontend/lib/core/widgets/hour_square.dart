import 'package:flutter/material.dart';

// Три состояния квадрата
enum SquareStatus { empty, half, full }

class HourSquare extends StatefulWidget {
  // Параметры, которые передаются при создании
  final SquareStatus initialStatus;
  final ValueChanged<SquareStatus> onStatusChanged;
  final double size;

  const HourSquare({
    super.key,
    required this.onStatusChanged,
    this.initialStatus = SquareStatus.empty,
    this.size = 40.0,
  });

  @override
  State<HourSquare> createState() => _HourSquareState();
}

class _HourSquareState extends State<HourSquare> {
  // Внутреннее состояние (private, начинается с _)
  late SquareStatus _status;

  @override
  void initState() {
    super.initState();
    // При создании устанавливаем начальный статус
    _status = widget.initialStatus;
  }

  @override
  void didUpdateWidget(covariant HourSquare oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStatus != widget.initialStatus) {
      _status = widget.initialStatus;
    }
  }

  void _cycleStatus() {
    // setState() говорит Flutter: "Перерисуй меня, я изменился"
    setState(() {
      // Циклически меняем статус: empty → half → full → empty
      switch (_status) {
        case SquareStatus.empty:
          _status = SquareStatus.half;
          break;
        case SquareStatus.half:
          _status = SquareStatus.full;
          break;
        case SquareStatus.full:
          _status = SquareStatus.empty;
          break;
      }
    });
    // Сообщаем родителю о изменении
    widget.onStatusChanged(_status);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _cycleStatus,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: _buildFill(),
      ),
    );
  }

  Widget _buildFill() {
    switch (_status) {
      case SquareStatus.empty:
        return Container(color: Colors.white);
      case SquareStatus.half:
        return Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _getActivityColor(), // цвет перенесён сюда
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    bottomLeft: Radius.circular(3),
                  ),
                ),
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        );
      case SquareStatus.full:
        return Container(color: _getActivityColor());
    }
  }
  Color _getActivityColor() {
    // Используем цвет из темы или константу
    return Theme.of(context).primaryColor;
  }
}
