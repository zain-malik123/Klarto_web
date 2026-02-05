import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klarto/models/label.dart';
import 'package:klarto/models/project.dart';
import 'package:klarto/apis/todos_api_service.dart';
import 'package:klarto/apis/labels_api_service.dart';
import 'package:klarto/widgets/calendar_dialog.dart';
import 'package:klarto/widgets/priority_selection_dialog.dart';
import 'package:klarto/widgets/label_selection_dialog.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:klarto/apis/user_api_service.dart';
import 'package:klarto/widgets/add_project_dialog.dart';
import 'package:klarto/widgets/add_label_dialog.dart';

class AddTodoDialog extends StatefulWidget {
  final Project? initialProject;
  final String? initialDate; // yyyy-MM-dd
  final VoidCallback onTodoAdded;

  const AddTodoDialog({
    super.key,
    this.initialProject,
    this.initialDate,
    required this.onTodoAdded,
  });

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _api = TodosApiService();
  final _labelsApi = LabelsApiService();
  final _userApi = UserApiService();

  final List<Project> _projects = [];
  final List<String> _teams = [];
  Project? _selectedProject;
  
  DateTimeSelection? _dateTimeSelection;
  int _selectedPriority = 4;
  Label? _selectedLabel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initDefaults();
    _loadProjects();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final res = await _userApi.getTeams();
      if (res['success'] == true && res['teams'] is List) {
        final list = (res['teams'] as List).map((t) => (t['name'] ?? '').toString()).toList();
        setState(() {
          _teams.clear();
          _teams.addAll(list);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadProjects() async {
    try {
      final res = await _userApi.getProjects();
      if (res['success'] == true && res['projects'] is List) {
        final list = (res['projects'] as List).map((p) => Project.fromJson(p)).toList();
        setState(() {
          _projects.clear();
          _projects.addAll(list);
          if (widget.initialProject != null) {
            _selectedProject = widget.initialProject;
          } else if (_projects.isNotEmpty) {
            _selectedProject = _projects.first;
          }
        });
      }
    } catch (_) {}
  }

  void _initDefaults() {
    DateTime date = DateTime.now();
    if (widget.initialDate != null) {
      try {
        date = DateTime.parse(widget.initialDate!);
      } catch (_) {}
    }
    
    _dateTimeSelection = DateTimeSelection(
      date: date,
      time: TimeOfDay.now(),
      repeatValue: 'No Repeat',
    );
    _loadDefaultLabel();
  }

  Future<void> _loadDefaultLabel() async {
    try {
      final res = await _labelsApi.getLabels();
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

  Future<String> _generateIncompleteTitle() async {
    try {
      final res = await _api.getTodos();
      if (res['success'] == true && res['data'] is List) {
          final list = List.from(res['data'] as List);
          final used = <int>{};
          for (final item in list) {
            try {
              final title = (item['title'] ?? '') as String;
              if (title.toLowerCase().startsWith('incomplete')) {
                final numMatch = RegExp(r'(\d+)').firstMatch(title);
                if (numMatch != null) {
                  final n = int.tryParse(numMatch.group(1) ?? '0') ?? 0;
                  if (n > 0) used.add(n);
                } else {
                  used.add(1);
                }
              }
            } catch (_) {}
          }
          int i = 1;
          while (used.contains(i)) i++;
          return 'Incomplete. $i';
      }
    } catch (_) {}
    return 'Incomplete. 1';
  }

  Future<void> _handleSave() async {
    String title = _titleController.text.trim();
    if (_selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please create or select a project first.'),
          backgroundColor: Colors.orange[800],
          action: SnackBarAction(
            label: 'ADD PROJECT',
            textColor: Colors.white,
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => AddProjectDialog(teams: _teams ?? []),
              );
              _loadProjects();
            },
          ),
        ),
      );
      return;
    }

    if (_selectedLabel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please create a label first before adding a task.'),
          backgroundColor: Colors.orange[800],
          action: SnackBarAction(
            label: 'ADD LABEL',
            textColor: Colors.white,
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => const AddLabelDialog(),
              );
              await _loadDefaultLabel();
            },
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    if (title.isEmpty) {
      title = await _generateIncompleteTitle();
    }
    
    final res = await _api.createTodo(
      title: title,
      description: _descriptionController.text.trim(),
      projectName: _selectedProject!.name,
      projectId: _selectedProject!.id,
      dueDate: _dateTimeSelection?.date != null ? DateFormat('yyyy-MM-dd').format(_dateTimeSelection!.date!) : '',
      dueTime: _dateTimeSelection?.time != null ? '${_dateTimeSelection!.time!.hour.toString().padLeft(2, '0')}:${_dateTimeSelection!.time!.minute.toString().padLeft(2, '0')}' : '09:00',
      repeatValue: _dateTimeSelection?.repeatValue ?? 'No Repeat',
      priority: _selectedPriority,
      labelId: _selectedLabel?.id ?? '',
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (res['success'] == true) {
        widget.onTodoAdded();
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add task')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Add Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_projects.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Project>(
                        value: _projects.any((p) => p.id == _selectedProject?.id) ? _projects.firstWhere((p) => p.id == _selectedProject?.id) : (_projects.isNotEmpty ? _projects.first : null),
                        items: _projects.map<DropdownMenuItem<Project>>((p) => DropdownMenuItem<Project>(
                          value: p,
                          child: Text(p.name, style: const TextStyle(fontSize: 12, color: Color(0xFF707070))),
                        )).toList(),
                        onChanged: (p) => setState(() => _selectedProject = p),
                        icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_projects.isEmpty) _buildProjectHint(),
            if (_projects.isNotEmpty && _selectedLabel == null) _buildLabelHint(),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Task Title',
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
                _buildBadgeButton('assets/icons/priority.svg', _selectedPriority == null ? '' : 'P$_selectedPriority', onPressed: () async {
                  final result = await showDialog<int>(
                    context: context,
                    builder: (context) => const PrioritySelectionDialog(),
                  );
                  if (result != null) setState(() => _selectedPriority = result);
                }),
                const SizedBox(width: 8),
                _buildBadgeButton(
                  'assets/icons/tag.svg', 
                  _selectedLabel?.name ?? '', 
                  overrideIcon: Icons.label,
                  iconColor: _selectedLabel?.color != null ? _hexToColor(_selectedLabel!.color!) : null,
                  onPressed: () async {
                    final result = await showDialog<Label>(
                      context: context,
                      builder: (context) => const LabelSelectionDialog(),
                    );
                    if (result != null) setState(() => _selectedLabel = result);
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(0xFF707070)))),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D4CD6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add Task'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFB347).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFE67E22), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Before adding a todo, you need a project.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC36A12)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => AddProjectDialog(teams: _teams ?? []),
                    );
                    _loadProjects();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE67E22),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    minimumSize: const Size(0, 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('Add Project', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFB347).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFE67E22), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Before adding a task, you need a label.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC36A12)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => const AddLabelDialog(),
                    );
                    _loadDefaultLabel();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE67E22),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    minimumSize: const Size(0, 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('Add Label', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF707070);
    }
  }

  Widget _buildBadgeButton(String iconPath, String label, {required VoidCallback onPressed, Color? iconColor, IconData? overrideIcon}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFF0F0F0)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (overrideIcon != null)
              Icon(overrideIcon, size: 14, color: iconColor ?? const Color(0xFF707070))
            else
              SvgPicture.asset(iconPath, width: 14, height: 14, colorFilter: ColorFilter.mode(iconColor ?? const Color(0xFF707070), BlendMode.srcIn)),
            const SizedBox(width: 6),
            if (label.isNotEmpty)
               Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF707070))),
          ],
        ),
      ),
    );
  }
}
