import 'package:flutter/material.dart';

class KlartoTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const KlartoTimePickerDialog({super.key, required this.initialTime});

  @override
  State<KlartoTimePickerDialog> createState() => _KlartoTimePickerDialogState();
}

class _KlartoTimePickerDialogState extends State<KlartoTimePickerDialog> {
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
  }

  void _incrementHour() => setState(() => _hour = (_hour + 1) % 24);
  void _decrementHour() => setState(() => _hour = (_hour - 1 + 24) % 24);
  void _incrementMinute() => setState(() => _minute = (_minute + 1) % 60);
  void _decrementMinute() => setState(() => _minute = (_minute - 1 + 60) % 60);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Text('Time', style: TextStyle(color: Color(0xFF383838), fontSize: 14)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimeSpinner(_hour, _incrementHour, _decrementHour),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF383838))),
                  ),
                  _buildTimeSpinner(_minute, _incrementMinute, _decrementMinute),
                ],
              ),
              const Divider(height: 32, color: Color(0xFFF0F0F0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF707070),
                      backgroundColor: const Color(0xFFF9F9F9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF707070))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(TimeOfDay(hour: _hour, minute: _minute));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D4CD6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSpinner(int value, VoidCallback onIncrement, VoidCallback onDecrement) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF383838)),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              _buildArrowButton(Icons.keyboard_arrow_up, onIncrement),
              const SizedBox(height: 4),
              _buildArrowButton(Icons.keyboard_arrow_down, onDecrement),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArrowButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Icon(icon, size: 20, color: const Color(0xFF707070)),
    );
  }
}