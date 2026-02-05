import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:klarto/apis/user_api_service.dart';
import 'package:klarto/apis/filters_api_service.dart';
import 'package:klarto/widgets/add_team_dialog.dart';
import 'package:klarto/widgets/add_project_dialog.dart';
import 'package:klarto/widgets/add_todo_dialog.dart';
import 'package:klarto/screens/main_app_shell.dart';

class Sidebar extends StatefulWidget {
  final String currentPage;
  final Function(String, {String? name}) onPageSelected;
  final int overdueCount;
  final VoidCallback? onTodoAdded;

  const Sidebar({
    super.key,
    required this.currentPage,
    required this.onPageSelected,
    required this.overdueCount,
    this.onTodoAdded,
  });

  @override
  State<Sidebar> createState() => SidebarState();
}

class SidebarState extends State<Sidebar> {
  final UserApiService _userApi = UserApiService();
  final FiltersApiService _filtersApi = FiltersApiService();
  String? _name;
  String? _profileBase64;
  Uint8List? _avatarBytes;
  bool _loading = true;
  // dynamic subteams shown under Teams header
  final List<String> _subteams = [];
  final List<Map<String, dynamic>> _projects = [];
  final List<Map<String, dynamic>> _favoriteFilters = [];

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    _loadProfile();
    _loadTeams();
    _loadProjects();
    _loadFavoriteFilters();
  }

  Future<void> _loadFavoriteFilters() async {
    try {
      final res = await _filtersApi.getFilters();
      if (res['success'] == true) {
        final list = List<Map<String, dynamic>>.from(res['data'] ?? []);
        final favs = list.where((e) => (e['is_favorite'] ?? false) == true).toList();
        if (mounted) setState(() { _favoriteFilters.clear(); _favoriteFilters.addAll(favs); });
      }
    } catch (_) {}
  }

  Future<void> _loadProjects() async {
    try {
      final res = await _userApi.getProjects();
      if (res['success'] == true) {
        final list = List<Map<String, dynamic>>.from(res['projects'] ?? []);
        if (mounted) setState(() { _projects.clear(); _projects.addAll(list); });
      }
    } catch (_) {}
  }

  Future<void> _loadTeams() async {
    try {
      final res = await _userApi.getTeams();
      debugPrint('Sidebar: _loadTeams result: $res');
      if (res['success'] == true) {
        final list = res['teams'] as List<dynamic>? ?? [];
        final names = list.map((e) {
          final m = e as Map<String, dynamic>;
          return (m['name'] as String?) ?? '';
        }).where((s) => s.isNotEmpty).toSet().toList(); // Ensure unique names
        debugPrint('Sidebar: Found ${names.length} teams: $names');
        if (mounted) {
          setState(() {
            _subteams.clear();
            _subteams.addAll(names);
          });
        }
      } else {
        debugPrint('Sidebar: Failed to load teams: ${res['message']}');
      }
    } catch (e) {
      debugPrint('Sidebar: Error loading teams: $e');
    }
  }

  Future<void> _loadProfile() async {
    try {
      final res = await _userApi.getProfile();
      if (res['success'] == true) {
        final name = res['name'] as String?;
        final b64 = res['profile_picture_base64'] as String?;
        Uint8List? bytes;
        if (b64 != null && b64.isNotEmpty) {
          // data:<mime>;base64,<data>
          final parts = b64.split(',');
          final encoded = parts.length > 1 ? parts[1] : parts[0];
          try { bytes = base64Decode(encoded); } catch (_) { bytes = null; }
        }
        if (mounted) setState(() { _name = name; _profileBase64 = b64; _avatarBytes = bytes; _loading = false; });
      } else {
        if (mounted) setState(() { _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF707070);
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF707070);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: const Color(0xFFFFFFFF),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('assets/images/logo.png', width: 22, height: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Klarto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3D4CD6),
                      ),
                    ),
                  ],
                ),
                SvgPicture.asset(
                  'assets/icons/grid.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User & Notifications
                  Container(
                    width: double.infinity,
                    height: 40,
                    padding: const EdgeInsets.only(left: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _avatarBytes != null
                                ? CircleAvatar(
                                    radius: 12,
                                    backgroundImage: MemoryImage(_avatarBytes!),
                                  )
                                : SvgPicture.asset('assets/icons/avatar.svg', width: 24, height: 24),
                            const SizedBox(width: 8),
                            Text(
                              _name ?? 'User',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF252525),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SvgPicture.asset(
                              'assets/icons/chevron-down.svg',
                              width: 12,
                              height: 12,
                              colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
                            ),
                          ],
                        ),
                                InkWell(
                                  onTap: () {
                                    widget.onPageSelected('notifications');
                                    // small visual feedback to confirm the tap fired
                                    try {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Opening Notifications')),
                                      );
                                    } catch (_) {}
                                    // debug log
                                    // ignore: avoid_print
                                    print('Sidebar: notifications tapped');
                                  },
                                  borderRadius: BorderRadius.circular(24),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        child: SvgPicture.asset(
                                          'assets/icons/bell.svg',
                                          width: 20,
                                          height: 20,
                                          colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3D4CD6),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 1),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Add Todo Button
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AddTodoDialog(
                          // No initial project/date for the global add button
                          onTodoAdded: () {
                            if (widget.onTodoAdded != null) {
                              widget.onTodoAdded!();
                            }
                          },
                        ),
                      );
                    },
                    icon: SvgPicture.asset(
                      'assets/icons/add.svg',
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                    label: const Text('Add Todo'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                      backgroundColor: const Color(0xFF3D4CD6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      alignment: Alignment.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Nav Items
                  _buildNavItem('search', 'assets/icons/search.svg', 'Search'),
                  _buildNavItem('dock', 'assets/icons/dock.svg', 'Dock'),
                  _buildNavItem('today', 'assets/icons/today.svg', 'Today',
                      onPressed: () => widget.onPageSelected('today')),
                  if (widget.overdueCount > 0)
                    _buildNavItem('overdue', 'assets/icons/overdue.svg', 'Overdue',
                        badge: widget.overdueCount.toString()),
                  _buildNavItem('filters_and_labels', 'assets/icons/filters.svg', 'Filters & Labels'),
                  _buildNavItem('activity', 'assets/icons/activity.svg', 'Activity'),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF0F0F0), height: 1),
                  const SizedBox(height: 16),
                  // Favorites Heading
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: Text(
                      'Favorites',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF252525),
                      ),
                    ),
                  ),
                  // Favorite filters (user-defined)
                  for (final f in _favoriteFilters)
                    _buildNavItem('filter_${f['id']}', 'assets/icons/filter.svg', f['name'] ?? 'Filter', onPressed: () {
                      final q = (f['query'] as String?) ?? '';
                      final title = (f['name'] as String?) ?? 'Filter';
                      if (q.isNotEmpty) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MainAppShell(initialFilter: q, initialFilterTitle: title)));
                    }),
                  // Favorite projects (fall back)
                  for (final p in _projects.where((p) => p['is_favorite'] == true))
                    _buildNavItem('project_${p['id']}', 'assets/icons/project.svg', p['name'] ?? 'Unnamed', color: _parseHexColor(p['color'])),
                  if (_favoriteFilters.isEmpty && _projects.where((p) => p['is_favorite'] == true).isEmpty)
                    _buildNavItem('usman_todos', 'assets/icons/filter.svg', "Usman's Todos"),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF0F0F0), height: 1),
                  const SizedBox(height: 16),
                  // Add Project button (above Projects heading)
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await showDialog(
                        context: context,
                        builder: (context) => AddProjectDialog(teams: _subteams),
                      );
                      if (result != null && result['success'] == true) {
                        _loadProjects(); // Refresh projects list
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Project "${result['name']}" created')),
                        );
                      }
                    },
                    icon: SvgPicture.asset(
                      'assets/icons/add.svg',
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(Color(0xFF3D4CD6), BlendMode.srcIn),
                    ),
                    label: const Text('Add Project'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                      backgroundColor: const Color(0xFF3D4CD6).withOpacity(0.08),
                      foregroundColor: const Color(0xFF3D4CD6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      alignment: Alignment.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Projects Heading (new)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: Text(
                      'Projects',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF252525),
                      ),
                    ),
                  ),
                  // Render 'My projects' as a nav item so it matches My teams visually
                  _buildNavItem('my_projects_header', 'assets/icons/project.svg', 'My projects', onPressed: () {}),
                  // Render dynamic projects list under My projects; fallback helper text when empty
                  if (_projects.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Text(
                        'No projects yet — create one with "Add Project"',
                        style: TextStyle(fontSize: 13, color: Color(0xFF707070)),
                      ),
                    )
                  else
                    for (final p in _projects)
                      _buildNavItem('project_${p['id']}', 'assets/icons/project.svg', p['name'] ?? 'Unnamed',
                          isIndented: true, color: _parseHexColor(p['color']), onPressed: () => widget.onPageSelected('project_${p['id']}', name: p['name'])),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF0F0F0), height: 1),
                  const SizedBox(height: 16),
                  // Add Teams button (above Teams heading)
                  ElevatedButton.icon(
                    onPressed: () async {
                      // open Add Team dialog
                      try {
                        final res = await showDialog(context: context, builder: (_) => const AddTeamDialog());
                        if (res is Map && res['created'] == true) {
                          _loadTeams(); // Refresh teams from server
                          final teamName = (res['teamName'] ?? '').toString();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Team "${teamName}" created')));
                        }
                      } catch (_) {}
                    },
                    icon: SvgPicture.asset(
                      'assets/icons/add.svg',
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(Color(0xFF3D4CD6), BlendMode.srcIn),
                    ),
                    label: const Text('Add Teams'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                      backgroundColor: const Color(0xFF3D4CD6).withOpacity(0.08),
                      foregroundColor: const Color(0xFF3D4CD6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      alignment: Alignment.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Teams Heading (dynamic)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: Text(
                      'Teams',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF252525),
                      ),
                    ),
                  ),
                  // Render 'My teams' as a nav item so it matches Project Alpha visually
                  _buildNavItem('my_teams_header', 'assets/icons/project.svg', 'My teams', onPressed: () {}),
                  // Render dynamic subteams list under My teams; fallback helper text when empty
                  if (_subteams.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Text(
                        'No teams yet — create one with "Add Teams"',
                        style: TextStyle(fontSize: 13, color: Color(0xFF707070)),
                      ),
                    )
                  else
                    for (final t in _subteams)
                      _buildNavItem('team_${t.replaceAll(' ', '_').toLowerCase()}', 'assets/icons/avatar.svg', t,
                          isIndented: true, useAtIcon: true, onPressed: () => widget.onPageSelected('team_${t.replaceAll(' ', '_').toLowerCase()}', name: t)),
                ],
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF),
              border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/help.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Get Help',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF707070),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String pageKey, String iconPath, String label,
      {String? badge, bool isIndented = false, bool isSubItem = false, VoidCallback? onPressed, bool useAtIcon = false, Color? color}) {
    final bool isActive = widget.currentPage == pageKey;
    final Color contentColor = isActive ? const Color(0xFF3D4CD6) : const Color(0xFF707070);
    final Color backgroundColor = isActive ? const Color(0xFF3D4CD6).withOpacity(0.08) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: InkWell(
        onTap: onPressed ?? () => widget.onPageSelected(pageKey),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 39,
          padding: EdgeInsets.fromLTRB(isIndented ? (isSubItem ? 60 : 34) : 8, 8, 8, 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (useAtIcon)
                Icon(Icons.alternate_email, size: 18, color: contentColor)
              else if (color != null)
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                )
              else
                SvgPicture.asset(
                  iconPath,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(contentColor, BlendMode.srcIn),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                    color: contentColor,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(48),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamHeader(String name, {bool isExpanded = false, Color? color}) {
    return Container(
      height: 40,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          if (color != null)
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            )
          else
            SvgPicture.asset('assets/icons/avatar.svg', width: 20, height: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF252525),
              ),
            ),
          ),
          SvgPicture.asset(
            'assets/icons/chevron-down.svg',
            width: 12,
            height: 12,
            colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
          ),
        ],
      ),
    );
  }
}