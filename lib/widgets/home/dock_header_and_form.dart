import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:klarto/widgets/calendar_dialog.dart';
import 'package:klarto/widgets/priority_selection_dialog.dart';
import 'package:klarto/widgets/label_selection_dialog.dart';
import 'package:klarto/models/label.dart';
import 'package:klarto/apis/todos_api_service.dart';

class DockHeaderAndForm extends StatefulWidget {
  final VoidCallback onTodoAdded;
  const DockHeaderAndForm({super.key, required this.onTodoAdded});

  @override
  State<DockHeaderAndForm> createState() => _DockHeaderAndFormState();
}

class _DockHeaderAndFormState extends State<DockHeaderAndForm> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final TodosApiService _todosApiService;
  String _selectedLocation = 'Project 1';
  DateTimeSelection? _dateTimeSelection;
  int? _selectedPriority;
  Label? _selectedLabel;

  @override
  void initState() {
    super.initState();
    _todosApiService = TodosApiService();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _dateTimeSelection = null;
      _selectedPriority = null;
      _selectedLabel = null;
    });
  }

  Future<void> _handleAddTodo() async {
    // --- Validation ---
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _dateTimeSelection == null ||
        _selectedPriority == null ||
        _selectedLabel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields: title, description, date, priority, and label.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // --- Data is valid, call the API ---
    final result = await _todosApiService.createTodo(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      projectName: _selectedLocation,
      dueDate: DateFormat('yyyy-MM-dd').format(_dateTimeSelection!.date!),
      dueTime: '${_dateTimeSelection!.time!.hour.toString().padLeft(2, '0')}:${_dateTimeSelection!.time!.minute.toString().padLeft(2, '0')}',
      repeatValue: _dateTimeSelection!.repeatValue,
      priority: _selectedPriority!,
      labelId: _selectedLabel!.id,
    );

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todo added successfully!'), backgroundColor: Colors.green),
      );
      _clearForm();
      widget.onTodoAdded();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add todo: ${result['data']['message'] ?? 'Unknown error'}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dock', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Todo Title',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF707070)),
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Todo Description',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 14, color: Color(0xFF9F9F9F)),
                ),
                style: const TextStyle(fontSize: 14, color: Color(0xFF383838)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildBadgeButton('assets/icons/calendar.svg', 'Date', onPressed: () async {
                    final result = await showDialog<DateTimeSelection>(
                      context: context,
                      builder: (context) => const CalendarDialog(),
                    );
                    if (result != null) {
                      setState(() {
                        _dateTimeSelection = result;
                      });
                    }
                  }),
                  const SizedBox(width: 8),
                  _buildBadgeButton('assets/icons/priority.svg', 'Priority', onPressed: () async {
                    final result = await showDialog<int>(
                      context: context,
                      builder: (context) => const PrioritySelectionDialog(),
                    );
                    if (result != null) {
                      setState(() {
                        _selectedPriority = result;
                      });
                    }
                  }),
                  const SizedBox(width: 8),
                  _buildBadgeButton('assets/icons/tag.svg', 'Label', onPressed: () async {
                    final result = await showDialog<Label>(
                      context: context,
                      builder: (context) => const LabelSelectionDialog(),
                    );
                    if (result != null) {
                      setState(() => _selectedLabel = result);
                    }
                  }),
                ],
              ),
              _buildSelectionInfo(),
              const Divider(height: 25, color: Color(0xFFF0F0F0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/send.svg',
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        color: Colors.white,
                        child: DropdownButton<String>(
                          value: _selectedLocation,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedLocation = newValue!;
                            });
                          },
                          items: <String>['Project 1', 'Project 2', 'Project 3']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF707070))),
                            );
                          }).toList(),
                          dropdownColor: Colors.white,
                          underline: Container(),
                          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF707070)),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _clearForm,
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
                        onPressed: _handleAddTodo,
                        child: const Text(
                          'Add Todo',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF3D4CD6),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeButton(String iconPath, String label, {VoidCallback? onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: SvgPicture.asset(
        iconPath,
        width: 12,
        height: 12,
        colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
      ),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF707070),
        side: const BorderSide(color: Color(0xFFF0F0F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildSelectionInfo() {
    final hasDateTime = _dateTimeSelection != null && _dateTimeSelection!.date != null;
    final hasPriority = _selectedPriority != null;
    final hasLabel = _selectedLabel != null;

    if (!hasDateTime && !hasPriority && !hasLabel) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Row(
        children: [
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              if (hasDateTime) ...[
                _buildInfoChip(Icons.calendar_today_outlined, DateFormat('EEE, MMM d').format(_dateTimeSelection!.date!)),
                if (_dateTimeSelection!.time != null) _buildInfoChip(Icons.access_time, _dateTimeSelection!.time!.format(context)),
                if (_dateTimeSelection!.repeatValue != 'No Repeat') _buildInfoChip(Icons.refresh, _dateTimeSelection!.repeatValue),
              ],
              if (hasPriority) _buildPriorityChip(),
              if (hasLabel) _buildInfoChip(Icons.label_outline, _selectedLabel!.name, color: _hexToColor(_selectedLabel!.color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip() {
    final priorityData = {
      1: {'label': 'Priority 1', 'color': const Color(0xFFEF4444)},
      2: {'label': 'Priority 2', 'color': const Color(0xFFF59E0B)},
      3: {'label': 'Priority 3', 'color': const Color(0xFF3D4CD6)},
      4: {'label': 'Priority 4', 'color': const Color(0xFF9F9F9F)},
    };

    final data = priorityData[_selectedPriority];
    if (data == null) return const SizedBox.shrink();

    final color = data['color'] as Color;
    final label = data['label'] as String;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [SvgPicture.asset('assets/icons/priority.svg', width: 12, height: 12, colorFilter: ColorFilter.mode(color, BlendMode.srcIn)), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 12, color: color))],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {Color? color}) {
    final chipColor = color ?? const Color(0xFF3D4CD6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 12, color: chipColor), const SizedBox(width: 4), Text(text, style: TextStyle(fontSize: 12, color: chipColor))],
      ),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}