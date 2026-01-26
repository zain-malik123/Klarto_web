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
  List<Map<String, dynamic>> _comments = [];
  List<SubTodo> _subTodos = [];
  bool _isSaving = false;
  bool _isLoadingComments = false;
  bool _isLoadingSubTodos = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _titleController.addListener(() {
      if (mounted) setState(() {});
    });
    _descriptionController = TextEditingController(text: widget.todo.description ?? '');
    _commentController = TextEditingController();
    _loadProjects();
    _loadComments();
    _loadSubTodos();
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
    _titleController.dispose();
    _descriptionController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
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
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (res['success']) {
        widget.onUpdate();
        Navigator.pop(context);
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: SizedBox(
        width: 1000,
        height: 800,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: main task body
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: _buildLeftPanel(context),
                    ),
                  ),
                  // Right: side task details panel
                  Container(
                    width: 240,
                    color: const Color(0xFFF9F9F9),
                    child: _buildRightPanel(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              // Small colored square (project icon)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFED7FDE),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _titleController.text, // Show current title text in header
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF252525),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildStatusBadge(),
              const SizedBox(width: 16),
              _buildIconButton('assets/icons/link.svg'),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF707070)),
                onPressed: () => Navigator.pop(context),
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
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
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
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getPriorityColor(widget.todo.priority),
                            width: 2,
                          ),
                          color: widget.todo.isCompleted ? _getPriorityColor(widget.todo.priority).withOpacity(0.1) : null,
                        ),
                        child: widget.todo.isCompleted
                            ? Icon(Icons.check, size: 14, color: _getPriorityColor(widget.todo.priority))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF252525),
                          decoration: widget.todo.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Task title',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Short description line (non-editable preview)
                if ((widget.todo.description ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: Text(
                      widget.todo.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF707070),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Meta information row
                Wrap(
                  spacing: 32,
                  runSpacing: 24,
                  children: [
                    _buildMetaColumn('Assignee', 'assets/icons/avatar.svg', 'Me'),
                    _buildMetaColumn('Due Date', 'assets/icons/calendar.svg', _formatDate(widget.todo.dueDate), onTap: _pickDate),
                    _buildMetaColumn('Project', 'assets/icons/project.svg', widget.todo.projectName ?? 'No Project', iconColor: const Color(0xFF3D4CD6), onTap: _pickProject),
                    _buildMetaColumn('Priority', 'assets/icons/priority.svg', _getPriorityText(widget.todo.priority), iconColor: _getPriorityColor(widget.todo.priority), onTap: _pickPriority),
                    _buildMetaColumn('Label', 'assets/icons/tag.svg', widget.todo.labelName ?? 'No Label', iconColor: _hexToColor(widget.todo.labelColor ?? '#707070'), onTap: _pickLabel),
                  ],
                ),
                const SizedBox(height: 24),
                // Sub-to do section (static for now, to match HTML feel)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Sub-to do',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF252525),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _loadSubTodos,
                          icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF9F9F9F)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Refresh sub-to dos',
                        ),
                      ],
                    ),
                    Text(
                      '${_subTodos.where((st) => st.isCompleted).length}/${_subTodos.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9F9F9F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isLoadingSubTodos)
                  const Center(child: CircularProgressIndicator())
                else if (_subTodos.isEmpty)
                   const Text('No sub-to dos yet.', style: TextStyle(fontSize: 13, color: Color(0xFF9F9F9F)))
                else
                  ..._subTodos.map((st) => _buildSubtaskItem(st)),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _handleAddSubTodo,
                  icon: const Icon(Icons.add, size: 18, color: Color(0xFF3D4CD6)),
                  label: const Text('Add sub to do', style: TextStyle(color: Color(0xFF3D4CD6))),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(height: 24),
                // Description section
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF252525),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: null,
                  minLines: 3,
                  style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF252525)),
                  decoration: InputDecoration(
                    hintText: 'Add a more detailed description...',
                    hintStyle: const TextStyle(color: Color(0xFF9F9F9F)),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF3D4CD6)),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 24),
                // Comments Section
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF252525),
                  ),
                ),
                const SizedBox(height: 12),
                if (_isLoadingComments)
                  const Center(child: CircularProgressIndicator())
                else if (_comments == null || _comments.isEmpty)
                  const Text('No comments yet.', style: TextStyle(fontSize: 13, color: Color(0xFF9F9F9F)))
                else
                  ..._comments.map((c) => _buildCommentItem(
                    c['author_name'] ?? 'Unknown',
                    c['text'] ?? '',
                    _formatCommentTime(c['created_at']),
                  )),
                const SizedBox(height: 16),
                // Comment input field
                Row(
                  children: [
                    CircleAvatar(radius: 14, backgroundColor: _indigoPrimary, child: const Icon(Icons.person, size: 16, color: Colors.white)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9F9F9F)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          filled: true,
                          fillColor: const Color(0xFFF9F9F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFF0F0F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFF0F0F0))),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _handleAddComment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _indigoPrimary,
                      side: BorderSide(color: _indigoPrimary),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Add comment'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF707070)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSaving ? null : _handleUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _indigoPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF252525),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Project', widget.todo.projectName ?? 'No project'),
          const SizedBox(height: 12),
          _buildDetailRow('Assignee', 'Me'),
          const SizedBox(height: 12),
          _buildDetailRow('Label', widget.todo.labelName ?? 'No label'),
          const SizedBox(height: 12),
          _buildDetailRow('Priority', _getPriorityText(widget.todo.priority)),
          const SizedBox(height: 12),
          _buildDetailRow('Due date', _formatDate(widget.todo.dueDate)),
        ],
      ),
    );
  }

  Widget _buildCommentItem(String author, String text, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14, 
            backgroundColor: author == 'Me' ? _indigoPrimary : Colors.grey[300], 
            child: const Icon(Icons.person, size: 16, color: Colors.white)
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(author, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF9F9F9F))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF383838))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  final Color _indigoPrimary = const Color(0xFF3D4CD6);

  void _pickDate() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const CalendarDialog(),
    );
    if (result != null) {
      setState(() => widget.todo.dueDate = result);
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
    }
  }

  void _pickPriority() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => const PrioritySelectionDialog(),
    );
    if (result != null) {
      setState(() => widget.todo.priority = result);
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
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'No Date';
    try {
      final date = DateTime.parse(dateStr);
      // Format like "Today", "Tomorrow" or "Jan 25"
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

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9F9F9F),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF383838),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return GestureDetector(
      onTap: () async {
        setState(() => _isSaving = true);
        final bool nextStatus = !widget.todo.isCompleted;
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: widget.todo.isCompleted ? const Color(0xFFE8F5E9) : const Color(0xFFEEF0FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.todo.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: widget.todo.isCompleted ? Colors.green : const Color(0xFF3D4CD6),
            ),
            const SizedBox(width: 6),
            Text(
              widget.todo.isCompleted ? 'Completed' : 'In Progress',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.todo.isCompleted ? Colors.green : const Color(0xFF3D4CD6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(String iconPath) {
    return Container(
      width: 32,
      height: 32,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: SvgPicture.asset(iconPath, colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn)),
    );
  }

  Widget _buildMetaColumn(String label, String iconPath, String value, {Color? iconColor, VoidCallback? onTap}) {
    // If the value is long, we truncate it
    final displayValue = value.length > 20 ? '${value.substring(0, 18)}...' : value;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 120, // Fixed width for alignment
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF9F9F9F), fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                SvgPicture.asset(
                    iconPath,
                    width: 16,
                    height: 16,
                    colorFilter: iconColor != null ? ColorFilter.mode(iconColor, BlendMode.srcIn) : const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayValue,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF383838)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtaskItem(SubTodo st) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleSubTodo(st),
            child: Icon(
              st.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: st.isCompleted ? const Color(0xFF3D4CD6) : const Color(0xFF9F9F9F),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  st.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF383838),
                    decoration: st.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (st.dueDate != null || st.priority != null && st.priority != 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        if (st.dueDate != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              _formatDate(st.dueDate),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF9F9F9F)),
                            ),
                          ),
                        if (st.priority != null && st.priority != 4)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getPriorityColor(st.priority),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPriorityText(int? p) {
    switch (p) {
      case 1: return 'High';
      case 2: return 'Medium';
      case 3: return 'Low';
      default: return 'None';
    }
  }
}
