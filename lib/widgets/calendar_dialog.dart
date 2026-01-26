import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart';
import 'package:klarto/widgets/time_picker_dialog.dart';
import 'package:klarto/widgets/repeat_selection_dialog.dart';

class DateTimeSelection {
  final DateTime? date;
  final TimeOfDay? time;
  final String repeatValue;

  DateTimeSelection({this.date, this.time, required this.repeatValue});
}

class CalendarDialog extends StatefulWidget {
  const CalendarDialog({super.key});

  @override
  State<CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<CalendarDialog> {
  final _dateInputController = TextEditingController();
  DateTime _currentDisplayDate = DateTime.now();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _repeatValue = 'No Repeat';

  @override
  void initState() {
    super.initState();
    _selectedDate = _currentDisplayDate;
    // Default time a few minutes ahead to avoid immediate past times
    final now = TimeOfDay.now();
    final totalMinutes = now.hour * 60 + now.minute + 5; // 5 minutes ahead
    final newHour = (totalMinutes ~/ 60) % 24;
    final newMinute = totalMinutes % 60;
    _selectedTime = TimeOfDay(hour: newHour, minute: newMinute);
    _updateDateInputText();
  }

  @override
  void dispose() {
    _dateInputController.dispose();
    super.dispose();
  }

  void _updateDateInputText() {
    if (_selectedDate != null) {
      _dateInputController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    } else {
      _dateInputController.text = '';
    }
  }

  void _changeMonth(int month) {
    setState(() {
      _currentDisplayDate = DateTime(_currentDisplayDate.year, _currentDisplayDate.month + month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 328),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQuickSelectButtons(),
                    const Divider(height: 25, color: Color(0xFFF0F0F0)),
                    _buildDateInput(),
                    const Divider(height: 25, color: Color(0xFFF0F0F0)),
                    _buildCalendarGrid(),
                    const Divider(height: 25, color: Color(0xFFF0F0F0)),
                    _buildTimeInput(),
                    const SizedBox(height: 8),
                    _buildRepeatDropdown(),
                    const Divider(height: 25, color: Color(0xFFF0F0F0)),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () => _changeMonth(-1), icon: SvgPicture.asset('assets/icons/arrow-left.svg')),
          Text(DateFormat('MMMM yyyy').format(_currentDisplayDate), style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF383838))),
          IconButton(onPressed: () => _changeMonth(1), icon: SvgPicture.asset('assets/icons/arrow-right.svg')),
        ],
      ),
    );
  }

  Widget _buildQuickSelectButtons() {
    return Row(
      children: [
        Expanded(child: _buildQuickButton('Today', () {
          setState(() {
            final now = DateTime.now();
            _selectedDate = now;
            _currentDisplayDate = now;
            _updateDateInputText();
          });
        })),
        const SizedBox(width: 12),
        Expanded(child: _buildQuickButton('Tomorrow', () {
          setState(() {
            final tomorrow = DateTime.now().add(const Duration(days: 1));
            _selectedDate = tomorrow;
            _currentDisplayDate = tomorrow;
            _updateDateInputText();
          });
        })),
      ],
    );
  }

  Widget _buildQuickButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3D4CD6).withOpacity(0.08),
        foregroundColor: const Color(0xFF3D4CD6),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(text),
    );
  }

  Widget _buildDateInput() {
    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      controller: _dateInputController,
      onChanged: (value) {
        try {
          final date = DateFormat('dd/MM/yyyy').parseStrict(value);
          setState(() {
            _selectedDate = date;
            _currentDisplayDate = date;
          });
        } catch (e) {
          // Ignore parse errors while typing
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        try {
          DateFormat('dd/MM/yyyy').parseStrict(value);
          return null;
        } catch (e) {
          return 'Invalid format';
        }
      },
      decoration: InputDecoration(
        hintText: 'e.g., ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SvgPicture.asset('assets/icons/calendar-2.svg'),
        ),
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFF0F0F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFF0F0F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF3D4CD6))),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final firstDayOfMonth = DateTime(_currentDisplayDate.year, _currentDisplayDate.month, 1);
    final startingWeekday = firstDayOfMonth.weekday % 7; // Sunday is 7, make it 0
    final daysInMonth = DateTime(_currentDisplayDate.year, _currentDisplayDate.month + 1, 0).day;
    final totalDaysInGrid = (daysInMonth + startingWeekday > 35) ? 42 : 35;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days.map((day) => Text(day, style: const TextStyle(color: Color(0xFF9F9F9F), fontSize: 14))).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
          itemCount: totalDaysInGrid,
          itemBuilder: (context, index) {
            final dayNumber = index - startingWeekday + 1;
            final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
            final currentDate = DateTime(_currentDisplayDate.year, _currentDisplayDate.month, dayNumber);
            
            final isSelected = _selectedDate != null &&
                currentDate.year == _selectedDate!.year &&
                currentDate.month == _selectedDate!.month &&
                currentDate.day == _selectedDate!.day;

            return GestureDetector(
              onTap: isCurrentMonth ? () => setState(() {
                _selectedDate = currentDate;
                _updateDateInputText();
              }) : null,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3D4CD6) : const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCurrentMonth ? '$dayNumber' : '',
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF707070),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimeInput() {
    return OutlinedButton(
      onPressed: () async {
        final TimeOfDay? pickedTime = await showDialog<TimeOfDay>(
          context: context,
          builder: (context) => KlartoTimePickerDialog(initialTime: _selectedTime ?? TimeOfDay.now()),
        );
        if (pickedTime != null) {
          setState(() {
            _selectedTime = pickedTime;
          });
        }
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 44), // Match height of dropdown
        backgroundColor: const Color(0xFFF9F9F9),
        side: const BorderSide(color: Color(0xFFF0F0F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/icons/clock.svg', colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn)),
          const SizedBox(width: 8),
          Text(
            _selectedTime?.format(context) ?? 'Time',
            style: const TextStyle(color: Color(0xFF707070), fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatDropdown() {
    return OutlinedButton(
      onPressed: () async {
        final String? result = await showDialog<String>(
          context: context,
          builder: (context) => const RepeatSelectionDialog(),
        );
        if (result != null) {
          setState(() {
            _repeatValue = result;
          });
        }
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 44),
        backgroundColor: const Color(0xFFF9F9F9),
        side: const BorderSide(color: Color(0xFFF0F0F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/icons/refresh.svg', colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn)),
          const SizedBox(width: 8),
          Text(
            _repeatValue == 'No Repeat' ? 'No Repeat' : 'Repeat: $_repeatValue',
            style: const TextStyle(color: Color(0xFF707070), fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null), // Return null on cancel
          child: const Text(
            'Cancel',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF707070),
            backgroundColor: const Color(0xFFF9F9F9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {
            if (_selectedDate == null || _selectedTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a date and time.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

            final selection = DateTimeSelection(
              date: _selectedDate,
              time: _selectedTime,
              repeatValue: _repeatValue,
            );
            Navigator.of(context).pop(selection);
          },
          child: const Text(
            'Done',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3D4CD6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          ),
        ),
      ],
    );
  }
}