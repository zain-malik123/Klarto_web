import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klarto/models/todo.dart';
import 'package:klarto/apis/todos_api_service.dart';
import 'package:klarto/apis/user_api_service.dart';
import 'package:klarto/widgets/calendar_dialog.dart';
import 'package:klarto/widgets/priority_selection_dialog.dart';
import 'package:klarto/widgets/label_selection_dialog.dart';
import 'package:klarto/models/label.dart';
import 'package:klarto/models/project.dart';
import 'package:klarto/models/sub_todo.dart';
import 'package:klarto/widgets/add_sub_todo_dialog.dart';

class TaskModal extends StatefulWidget {
  final Todo todo;
  final VoidCallback onUpdate;

  const TaskModal({
    super.key,
    required this.todo,
    required this.onUpdate,
  });

  @override
  State<TaskModal> createState() => _TaskModalState();
}

class _TaskModalState extends State<TaskModal> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _commentController;
  final TodosApiService _api = TodosApiService();
  final UserApiService _userApi = UserApiService();
  final List<Project> _projects = [];
  final List<Map<String, dynamic>> _teams = [];
  List<Map<String, dynamic>> _comments = [];
  List<SubTodo> _subTodos = [];
  bool _isSaving = false;
  bool _isLoadingComments = false;
  bool _isLoadingSubTodos = false;
  bool _hideCompletedSubTodos = false;
  Timer? _debounce;
  
  String? _currentUserProfileBase64;
  Uint8List? _currentUserAvatarBytes;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _descriptionController = TextEditingController(text: widget.todo.description ?? '');
    
    _titleController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);

    _commentController = TextEditingController();
    _loadProjects();
    _loadTeams();
    _loadComments();
    _loadSubTodos();
    _loadUserProfile();
  }

  void _onFieldChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _handleUpdate();
      }
    });
    setState(() {});
  }

  Future<void> _loadTeams() async {
    try {
      final res = await _userApi.getTeams();
      if (res['success'] == true) {
        final List<dynamic> data = res['teams'] ?? [];
        if (mounted) {
          setState(() {
            _teams.clear();
            _teams.addAll(data.map((e) => Map<String, dynamic>.from(e)).toList());
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadUserProfile() async {
    try {
      final res = await _userApi.getProfile();
      if (res['success'] == true) {
        if (mounted) {
          setState(() {
            _currentUserProfileBase64 = res['profile_picture_base64'];
            if (_currentUserProfileBase64 != null && _currentUserProfileBase64!.isNotEmpty) {
              _currentUserAvatarBytes = base64Decode(_currentUserProfileBase64!);
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadSubTodos() async {
    if (!mounted) return;
    setState(() => _isLoadingSubTodos = true);
    try {
      final res = await _api.getSubTodos(widget.todo.id);
      if (res['success'] == true && res['data'] != null && res['data'] is List) {
        if (mounted) {
          setState(() {
            _subTodos = (res['data'] as List).map((e) => SubTodo.fromJson(e)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading sub-todos: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSubTodos = false);
    }
  }

  Future<void> _handleAddSubTodo() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddSubTodoDialog(parentTodoId: widget.todo.id),
    );
    if (result == true) {
      _loadSubTodos();
    }
  }

  Future<void> _toggleSubTodo(SubTodo st) async {
    final nextStatus = !st.isCompleted;
    final res = await _api.toggleSubTodoCompletion(id: st.id, isCompleted: nextStatus);
    if (res['success'] == true) {
      setState(() {
        st.isCompleted = nextStatus;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update sub-to do')),
        );
      }
    }
  }

  Future<void> _loadComments() async {
    if (!mounted) return;
    setState(() => _isLoadingComments = true);
    try {
      final res = await _api.getComments(widget.todo.id);
      if (res['success'] == true && res['data'] != null && res['data'] is List) {
        if (mounted) {
          setState(() {
            _comments = List<Map<String, dynamic>>.from(res['data']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
    } finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _loadProjects() async {
    try {
      final res = await _userApi.getProjects();
      if (res['success'] == true) {
        final List<dynamic> data = res['projects'] ?? [];
        if (mounted) {
           setState(() {
             _projects.clear();
             _projects.addAll(data.map((e) => Project.fromJson(e)).toList());
           });
        }
      }
    } catch (_) {}
  }

  Future<void> _handleAddComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    final res = await _api.addComment(todoId: widget.todo.id, text: text);
    if (res['success'] == true) {
      _commentController.clear();
      _loadComments();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add comment')),
        );
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.removeListener(_onFieldChanged);
    _descriptionController.removeListener(_onFieldChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate({bool shouldPop = false}) async {
    setState(() => _isSaving = true);
    final res = await _api.updateTodo(
      id: widget.todo.id,
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: widget.todo.dueDate,
      priority: widget.todo.priority,
      labelId: widget.todo.labelId,
      projectName: widget.todo.projectName,
      projectId: widget.todo.projectId,
      teamId: widget.todo.teamId,
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (res['success']) {
        widget.todo.title = _titleController.text;
        widget.todo.description = _descriptionController.text;
        widget.onUpdate();
        if (shouldPop) {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Update failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 920,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 60,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Column
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: _buildLeftPanel(context),
                            ),
                          ),
                          _buildCommentInputSection(),
                        ],
                      ),
                    ),
                    // Right Sidebar
                    Container(
                      width: 280,
                      color: const Color(0xFFF9F9F9),
                      child: _buildRightPanel(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final currentProject = _projects.where((p) => p.id == widget.todo.projectId).firstOrNull;
    final teamName = widget.todo.teamName ?? currentProject?.teamName ?? "Tasks";
    final teamColor = _hexToColor(currentProject?.color ?? "#ED7FDE");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Team Info
              InkWell(
                onTap: _pickTeam,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: teamColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      teamName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF252525),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '/',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF707070),
                ),
              ),
              const SizedBox(width: 8),
              // Project Info
              InkWell(
                onTap: _pickProject,
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/project.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.todo.projectName ?? 'Add Project',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF707070),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Nav arrows
              _buildIconButton('assets/icons/arrow_up.svg', size: 24, onTap: () {}),
              const SizedBox(width: 24),
              _buildIconButton('assets/icons/arrow_down.svg', size: 24, onTap: () {}),
              const SizedBox(width: 24),
              _buildIconButton('assets/icons/more.svg', size: 20, onTap: () {}),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () => _handleUpdate(shouldPop: true),
                child: SvgPicture.asset(
                  'assets/icons/close.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Task Title & Description Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    final bool nextStatus = !widget.todo.isCompleted;
                    setState(() => _isSaving = true);
                    final res = await _api.updateTodoCompletion(id: widget.todo.id, isCompleted: nextStatus);
                    if (mounted) {
                      setState(() => _isSaving = false);
                      if (res['success']) {
                        setState(() {
                          widget.todo.isCompleted = nextStatus;
                        });
                        widget.onUpdate();
                      }
                    }
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFFEF4444), // Priority color or default
                        width: 2,
                      ),
                      color: widget.todo.isCompleted ? const Color(0xFFEF4444).withOpacity(0.1) : null,
                    ),
                    child: widget.todo.isCompleted
                        ? const Icon(Icons.check, size: 14, color: Color(0xFFEF4444))
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF252525),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Task Title',
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: TextField(
                controller: _descriptionController,
                maxLines: null,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF707070),
                  height: 1.4,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add description...',
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Sub-todos Section
        _buildSubTodosHeader(),
        const SizedBox(height: 12),
        if (_isLoadingSubTodos)
          const Center(child: CircularProgressIndicator())
        else if (_subTodos.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text('No sub-todos yet.', style: TextStyle(fontSize: 13, color: Color(0xFF9F9F9F))),
          )
        else
          ..._subTodos
              .where((st) => !_hideCompletedSubTodos || !st.isCompleted)
              .map((st) => _buildSubtaskItem(st)),
        const SizedBox(height: 12),
        _buildAddSubTodoButton(),
        const SizedBox(height: 20),
        // Comments Section
        _buildCommentsHeader(),
        const SizedBox(height: 12),
        if (_isLoadingComments)
          const Center(child: CircularProgressIndicator())
        else if (_comments.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text('No comments yet.', style: TextStyle(fontSize: 13, color: Color(0xFF9F9F9F))),
          )
        else
          ..._comments.map((c) => _buildCommentItem(
                c['author_name'] ?? 'Unknown',
                c['text'] ?? '',
                _formatCommentTime(c['created_at']),
                c['profile_picture_base64'],
              )),
      ],
    );
  }

  Widget _buildSubTodosHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'Sub-Todos',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF252525),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${_subTodos.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF707070),
              ),
            ),
          ],
        ),
        InkWell(
          onTap: () {
            setState(() {
              _hideCompletedSubTodos = !_hideCompletedSubTodos;
            });
          },
          child: Row(
            children: [
              Text(
                _hideCompletedSubTodos ? 'Show Completed' : 'Hide Completed',
                style: const TextStyle(fontSize: 12, color: Color(0xFF707070)),
              ),
              const SizedBox(width: 6),
              Icon(
                _hideCompletedSubTodos ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 14,
                color: const Color(0xFF707070),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddSubTodoButton() {
    return InkWell(
      onTap: _handleAddSubTodo,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _indigoPrimary, width: 1.5),
                  ),
                ),
                Icon(Icons.add, size: 12, color: _indigoPrimary),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              'Add Sub Todo',
              style: TextStyle(
                fontSize: 14,
                color: _indigoPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'Comments',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF252525),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${_comments.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF707070),
              ),
            ),
          ],
        ),
        SvgPicture.asset(
          'assets/icons/arrow_down.svg',
          width: 18,
          height: 18,
          colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
        ),
      ],
    );
  }

  Widget _buildCommentInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Column(
        children: [
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Enter your comment',
              hintStyle: const TextStyle(color: Color(0xFF9F9F9F), fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _indigoPrimary),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildIconButton('assets/icons/attachment.svg', size: 24, onTap: () {}),
                  const SizedBox(width: 12),
                  _buildIconButton('assets/icons/mention.svg', size: 24, onTap: () {}),
                ],
              ),
              ElevatedButton(
                onPressed: _handleAddComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _indigoPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Comment', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    final currentProject = _projects.where((p) => p.id == widget.todo.projectId).firstOrNull;
    final teamName = widget.todo.teamName ?? currentProject?.teamName ?? "Tasks";
    final teamColor = _hexToColor(currentProject?.color ?? "#ED7FDE");

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection('Team', valueWidget: InkWell(
            onTap: _pickTeam,
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: teamColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(teamName, style: const TextStyle(fontSize: 14, color: Color(0xFF707070))),
              ],
            ),
          )),
          const SizedBox(height: 20),
          _buildInfoSection('Project', valueWidget: InkWell(
            onTap: _pickProject,
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/project.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
                ),
                const SizedBox(width: 8),
                Text(widget.todo.projectName ?? 'Add Project', style: const TextStyle(fontSize: 14, color: Color(0xFF707070))),
              ],
            ),
          )),
          const SizedBox(height: 20),
          _buildInfoSection('Assignee', valueWidget: Row(
            children: [
              const CircleAvatar(
                radius: 9,
                backgroundColor: Color(0xFF3D4CD6),
                child: Icon(Icons.person, size: 10, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text("Me", style: TextStyle(fontSize: 14, color: Color(0xFF707070))),
            ],
          )),
          const SizedBox(height: 20),
          _buildInfoSection('Date', valueWidget: InkWell(
            onTap: _pickDate,
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/calendar.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
                ),
                const SizedBox(width: 8),
                Text(_formatDate(widget.todo.dueDate), style: const TextStyle(fontSize: 14, color: Color(0xFF707070))),
              ],
            ),
          )),
          const SizedBox(height: 20),
          _buildInfoSection('Priority', valueWidget: InkWell(
            onTap: _pickPriority,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/priority.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(_getPriorityColor(widget.todo.priority), BlendMode.srcIn),
                  ),
                  const SizedBox(width: 6),
                  Text(_getPriorityText(widget.todo.priority), style: const TextStyle(fontSize: 14, color: Color(0xFF707070))),
                ],
              ),
            ),
          )),
          const SizedBox(height: 20),
          _buildInfoSection('Label', valueWidget: InkWell(
            onTap: _pickLabel,
            child: Wrap(
              spacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.label,
                        size: 16,
                        color: _hexToColor(widget.todo.labelColor ?? '#707070'),
                      ),
                      const SizedBox(width: 6),
                      Text(widget.todo.labelName ?? 'Label', style: const TextStyle(fontSize: 14, color: Color(0xFF707070))),
                    ],
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 20),
          _buildInfoSection('Reminders', valueWidget: InkWell(
            onTap: _pickDate,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/reminder.svg',
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
                    ),
                    const SizedBox(width: 8),
                    Text(_formatDate(widget.todo.dueDate), style: const TextStyle(fontSize: 14, color: Color(0xFF707070))),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _pickDate,
                  icon: SvgPicture.asset(
                    'assets/icons/calendar.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(_indigoPrimary, BlendMode.srcIn),
                  ),
                  label: const Text('Add To Calendar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _indigoPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String label, {Widget? valueWidget}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF707070),
          ),
        ),
        const SizedBox(height: 8),
        if (valueWidget != null) valueWidget,
      ],
    );
  }

  Widget _buildSubtaskItem(SubTodo st) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleSubTodo(st),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFEF4444), width: 2),
                    color: st.isCompleted ? const Color(0xFFEF4444).withOpacity(0.1) : null,
                  ),
                  child: st.isCompleted ? const Icon(Icons.check, size: 12, color: Color(0xFFEF4444)) : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  st.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF252525),
                    decoration: st.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              InkWell(
                onTap: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => AddSubTodoDialog(
                      parentTodoId: widget.todo.id,
                      subTodo: st,
                    ),
                  );
                  if (result == true) {
                    _loadSubTodos();
                  }
                },
                child: SvgPicture.asset(
                  'assets/icons/edit.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
                ),
              ),
            ],
          ),
          if ((st.description ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 26.0, top: 4),
              child: Text(
                st.description!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF707070), height: 1.4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(String author, String text, String time, String? avatarBase64) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE0E0E0),
            backgroundImage: (avatarBase64 != null && avatarBase64.isNotEmpty)
                ? MemoryImage(base64Decode(avatarBase64))
                : null,
            child: (avatarBase64 == null || avatarBase64.isEmpty)
                ? const Icon(Icons.person, size: 20, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(author, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF252525))),
                    Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF707070))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF252525), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(String iconPath, {double size = 20, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: SvgPicture.asset(
        iconPath,
        width: size,
        height: size,
        colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
      ),
    );
  }

  String _getPriorityText(int? p) {
    switch (p) {
      case 1: return 'P1';
      case 2: return 'P2';
      case 3: return 'P3';
      case 4: return 'P4';
      default: return 'No Priority';
    }
  }

  final Color _indigoPrimary = const Color(0xFF3D4CD6);

  void _pickDate() async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => const CalendarDialog(),
    );
    if (result != null) {
      setState(() {
        if (result is DateTimeSelection) {
          if (result.date != null) {
            widget.todo.dueDate = result.date!.toIso8601String().split('T').first;
          }
          if (result.time != null) {
            final h = result.time!.hour.toString().padLeft(2, '0');
            final m = result.time!.minute.toString().padLeft(2, '0');
            widget.todo.dueTime = '$h:$m';
          }
        } else if (result is String) {
          widget.todo.dueDate = result;
        }
      });
      _handleUpdate();
    }
  }

  void _pickTeam() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Team'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _teams.length,
            itemBuilder: (context, index) {
              final team = _teams[index];
              return ListTile(
                title: Text(team['name'] ?? 'Unnamed Team'),
                onTap: () => Navigator.pop(context, team),
                selected: widget.todo.teamId == team['id'],
              );
            },
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        widget.todo.teamId = result['id'];
        widget.todo.teamName = result['name'];
        // Optional: If we change team, maybe clear project if it doesn't belong to the new team?
        // But for now let's just update the team.
      });
      _handleUpdate();
    }
  }

  void _pickProject() async {
    final result = await showDialog<Project>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Project'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _projects.length,
            itemBuilder: (context, index) {
              final p = _projects[index];
              return ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _hexToColor(p.color),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(p.name),
                onTap: () => Navigator.pop(context, p),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        widget.todo.projectId = result.id;
        widget.todo.projectName = result.name;
      });
      _handleUpdate();
    }
  }

  void _pickPriority() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => const PrioritySelectionDialog(),
    );
    if (result != null) {
      setState(() => widget.todo.priority = result);
      _handleUpdate();
    }
  }

  void _pickLabel() async {
    final result = await showDialog<Label>(
      context: context,
      builder: (context) => const LabelSelectionDialog(),
    );
    if (result != null) {
      setState(() {
        widget.todo.labelId = result.id;
        widget.todo.labelName = result.name;
        widget.todo.labelColor = result.color;
      });
      _handleUpdate();
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'No Date';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final check = DateTime(date.year, date.month, date.day);
      if (check == today) return 'Today';
      if (check == today.add(const Duration(days: 1))) return 'Tomorrow';
      return '${_month(date.month)} ${date.day}';
    } catch (_) {
      return dateStr;
    }
  }

  String _month(int m) {
    const list = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return list[m - 1];
  }

  String _formatCommentTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${dt.day} ${_month(dt.month)}';
    } catch (_) {
      return iso;
    }
  }

  Color _getPriorityColor(int? priority) {
    switch (priority) {
      case 1: return const Color(0xFFEF4444);
      case 2: return const Color(0xFFF59E0B);
      case 3: return const Color(0xFF3D4CD6);
      default: return const Color(0xFF707070);
    }
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF707070);
    }
  }
}
