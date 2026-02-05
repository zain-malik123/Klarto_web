import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:klarto/widgets/calendar_dialog.dart';
import 'package:klarto/widgets/priority_selection_dialog.dart';
import 'package:klarto/widgets/label_selection_dialog.dart';
import 'package:klarto/models/label.dart';
import 'package:klarto/models/project.dart';
import 'package:klarto/apis/todos_api_service.dart';
import 'package:klarto/apis/labels_api_service.dart';
import 'package:klarto/apis/user_api_service.dart';
import 'package:klarto/widgets/add_project_dialog.dart';

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
  late final LabelsApiService _labelsApiService;
  late final UserApiService _userApiService;
  final List<Project> _projects = [];
  final List<String> _teams = [];
  Project? _selectedProject;
  DateTimeSelection? _dateTimeSelection;
  int? _selectedPriority;
  Label? _selectedLabel;
  Label? _defaultLabel;

  @override
  void initState() {
    super.initState();
    _todosApiService = TodosApiService();
    _userApiService = UserApiService();
    _dateTimeSelection = _defaultDateTimeSelection();
    _selectedPriority = 4; // default to 4th priority
    _labelsApiService = LabelsApiService();
    _setDefaultLabel();
    _loadProjects();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final res = await _userApiService.getTeams();
      if (res['success'] == true && res['teams'] is List) {
        final list = (res['teams'] as List).map((t) => (t['name'] ?? '').toString()).toList();
        if (mounted) {
          setState(() {
            _teams.clear();
            _teams.addAll(list);
          });
        }
      }
    } catch (_) {}
  }

  Widget _buildProjectHint() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                  'No projects found!',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFC36A12)),
                ),
                const SizedBox(height: 2),
                const Text(
                  'You must create a project before adding your first todo.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFC36A12)),
                ),
              ],
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Add Project', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<String> _generateIncompleteTitle() async {
    try {
      final res = await _todosApiService.getTodos();
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

  DateTimeSelection _defaultDateTimeSelection() {
    final now = DateTime.now();
    final timeNow = TimeOfDay.fromDateTime(now);
    final totalMinutes = timeNow.hour * 60 + timeNow.minute + 5; // 5 minutes ahead
    final newHour = (totalMinutes ~/ 60) % 24;
    final newMinute = totalMinutes % 60;
    return DateTimeSelection(
      date: DateTime(now.year, now.month, now.day),
      time: TimeOfDay(hour: newHour, minute: newMinute),
      repeatValue: 'No Repeat',
    );
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
      _dateTimeSelection = _defaultDateTimeSelection();
      _selectedPriority = 4;
      _selectedLabel = _defaultLabel;
    });
  }

  Future<void> _setDefaultLabel() async {
    try {
      final res = await _labelsApiService.getLabels();
      if (res['success'] == true && res['data'] is List) {
        final list = List.from(res['data'] as List);
        if (list.isNotEmpty) {
          Map<String, dynamic>? pick;
          for (final item in list) {
            try {
              final name = (item['name'] ?? '') as String;
              if (name.toLowerCase() == 'default') {
                pick = item as Map<String, dynamic>;
                break;
              }
            } catch (_) {}
          }
          pick ??= list.first as Map<String, dynamic>;
          final label = Label.fromJson(pick);
          if (mounted) setState(() { _defaultLabel = label; if (_selectedLabel == null) _selectedLabel = label; });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadProjects() async {
    try {
      final res = await _userApiService.getProjects();
      if (res['success'] == true && res['projects'] is List) {
        final list = (res['projects'] as List).map((p) => Project.fromJson(p)).toList();
        if (mounted) {
          setState(() {
            _projects.clear();
            _projects.addAll(list);
            if (_projects.isNotEmpty) {
              _selectedProject = _projects.first;
            }
          });
        }
      }
    } catch (e) {
      print('Error loading projects: $e');
    }
  }

  Future<void> _handleAddTodo() async {
    // --- Prepare title/description and Validation ---
    String title = _titleController.text.trim();
    String description = _descriptionController.text.trim();

    if (title.isEmpty) {
      title = await _generateIncompleteTitle();
    }

    // Apply defaults when not selected
    if (_dateTimeSelection == null) {
      _dateTimeSelection = _defaultDateTimeSelection();
    }
    if (_selectedPriority == null) {
      _selectedPriority = 4;
    }

    // Use default label if none selected
    if (_selectedLabel == null && _defaultLabel != null) {
      _selectedLabel = _defaultLabel;
    }
    
    if (_selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please create or select a project before adding a todo.'),
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

    // --- Data is valid, call the API ---
    final result = await _todosApiService.createTodo(
      title: title,
      description: description,
      projectName: _selectedProject!.name,
      projectId: _selectedProject!.id,
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

  String _getCalendarButtonLabel() {
    if (_dateTimeSelection?.date == null) return 'Date';
    
    final dateStr = DateFormat('MMM d').format(_dateTimeSelection!.date!);
    if (_dateTimeSelection!.time != null) {
      return '$dateStr, ${_dateTimeSelection!.time!.format(context)}';
    }
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dock', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        if (_projects.isEmpty) _buildProjectHint(),
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
                  _buildBadgeButton(
                    'assets/icons/calendar.svg', 
                    _getCalendarButtonLabel(), 
                    onPressed: () async {
                      final result = await showDialog<DateTimeSelection>(
                        context: context,
                        builder: (context) => const CalendarDialog(),
                      );
                      if (result != null) {
                        setState(() {
                          _dateTimeSelection = result;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildBadgeButton(
                    'assets/icons/priority.svg', 
                    _selectedPriority == null ? 'Priority' : 'P$_selectedPriority', 
                    onPressed: () async {
                      final result = await showDialog<int>(
                        context: context,
                        builder: (context) => const PrioritySelectionDialog(),
                      );
                      if (result != null) {
                        setState(() {
                          _selectedPriority = result;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildBadgeButton(
                    'assets/icons/tag.svg', 
                    _selectedLabel?.name ?? 'Label', 
                    overrideIcon: Icons.label,
                    iconColor: _selectedLabel?.color != null ? _hexToColor(_selectedLabel!.color!) : null,
                    onPressed: () async {
                      final result = await showDialog<Label>(
                        context: context,
                        builder: (context) => const LabelSelectionDialog(),
                      );
                      if (result != null) {
                        setState(() => _selectedLabel = result);
                      }
                    },
                  ),
                ],
              ),
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
                        child: DropdownButton<Project>(
                          value: _selectedProject,
                          onChanged: (Project? newValue) {
                            setState(() {
                              _selectedProject = newValue;
                            });
                          },
                          items: _projects
                              .map<DropdownMenuItem<Project>>((Project project) {
                            return DropdownMenuItem<Project>(
                              value: project,
                              child: Text(project.name, style: const TextStyle(fontSize: 12, color: Color(0xFF707070))),
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

  Widget _buildBadgeButton(String iconPath, String label, {VoidCallback? onPressed, Color? iconColor, IconData? overrideIcon}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: overrideIcon != null 
        ? Icon(overrideIcon, size: 14, color: iconColor ?? const Color(0xFF707070))
        : SvgPicture.asset(
            iconPath,
            width: 12,
            height: 12,
            colorFilter: ColorFilter.mode(iconColor ?? const Color(0xFF707070), BlendMode.srcIn),
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

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}