import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:klarto/widgets/calendar_dialog.dart';
import 'package:klarto/widgets/priority_selection_dialog.dart';
import 'package:klarto/widgets/label_selection_dialog.dart';
import 'package:klarto/models/label.dart';
import 'package:klarto/apis/todos_api_service.dart';
import 'package:klarto/apis/labels_api_service.dart';

class AddSubTodoDialog extends StatefulWidget {
  final String parentTodoId;
  const AddSubTodoDialog({super.key, required this.parentTodoId});

  @override
  State<AddSubTodoDialog> createState() => _AddSubTodoDialogState();
}

class _AddSubTodoDialogState extends State<AddSubTodoDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _todosApiService = TodosApiService();
  final _labelsApiService = LabelsApiService();
  
  DateTimeSelection? _dateTimeSelection;
  int? _selectedPriority = 4;
  Label? _selectedLabel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dateTimeSelection = _defaultDateTimeSelection();
    _loadDefaultLabel();
  }

  DateTimeSelection _defaultDateTimeSelection() {
    final now = DateTime.now();
    return DateTimeSelection(
      date: DateTime(now.year, now.month, now.day),
      time: TimeOfDay.now(),
      repeatValue: 'No Repeat',
    );
  }

  Future<void> _loadDefaultLabel() async {
    try {
      final res = await _labelsApiService.getLabels();
      if (res['success'] == true && res['data'] is List) {
        final list = List.from(res['data'] as List);
        if (list.isNotEmpty) {
           setState(() {
             _selectedLabel = Label.fromJson(list.first);
           });
        }
      }
    } catch (_) {}
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);
    
    final res = await _todosApiService.addSubTodo(
      todoId: widget.parentTodoId,
      title: title,
      description: _descriptionController.text.trim(),
      dueDate: _dateTimeSelection?.date != null ? DateFormat('yyyy-MM-dd').format(_dateTimeSelection!.date!) : null,
      dueTime: _dateTimeSelection?.time != null ? '${_dateTimeSelection!.time!.hour.toString().padLeft(2, '0')}:${_dateTimeSelection!.time!.minute.toString().padLeft(2, '0')}' : null,
      priority: _selectedPriority,
      labelId: _selectedLabel?.id,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (res['success'] == true) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add sub-to do')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Sub-to do',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Sub-to do Title',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 16, color: Color(0xFF707070)),
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              autofocus: true,
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Description',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF9F9F9F)),
              ),
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildBadgeButton('assets/icons/calendar.svg', _dateTimeSelection?.date == null ? 'Date' : DateFormat('MMM d').format(_dateTimeSelection!.date!), onPressed: () async {
                  final result = await showDialog<DateTimeSelection>(
                    context: context,
                    builder: (context) => const CalendarDialog(),
                  );
                  if (result != null) setState(() => _dateTimeSelection = result);
                }),
                const SizedBox(width: 8),
                _buildBadgeButton('assets/icons/priority.svg', 'P$_selectedPriority', onPressed: () async {
                  final result = await showDialog<int>(
                    context: context,
                    builder: (context) => const PrioritySelectionDialog(),
                  );
                  if (result != null) setState(() => _selectedPriority = result);
                }),
                const SizedBox(width: 8),
                _buildBadgeButton('assets/icons/tag.svg', _selectedLabel?.name ?? 'Label', onPressed: () async {
                  final result = await showDialog<Label>(
                    context: context,
                    builder: (context) => const LabelSelectionDialog(),
                  );
                  if (result != null) setState(() => _selectedLabel = result);
                }),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF707070))),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D4CD6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add Sub-to do'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeButton(String iconPath, String label, {required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(iconPath, width: 14, height: 14, colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF707070), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
