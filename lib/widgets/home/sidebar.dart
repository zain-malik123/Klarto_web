import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:klarto/apis/user_api_service.dart';

class Sidebar extends StatefulWidget {
  final String currentPage;
  final Function(String) onPageSelected;
  final int overdueCount;

  const Sidebar({
    super.key, required this.currentPage, required this.onPageSelected, required this.overdueCount,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final UserApiService _userApi = UserApiService();
  String? _name;
  String? _profileBase64;
  Uint8List? _avatarBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: const Color(0xFFF9F9F9),
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
                        Stack(
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Add Todo Button
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: SvgPicture.asset(
                      'assets/icons/add.svg',
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(Color(0xFF3D4CD6), BlendMode.srcIn),
                    ),
                    label: const Text('Add Todo'),
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
                  _buildNavItem('project_1', 'assets/icons/project.svg', 'Project 1'),
                  _buildNavItem('usman_todos', 'assets/icons/filter.svg', "Usman's Todos"),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF0F0F0), height: 1),
                  const SizedBox(height: 16),
                  // Teams Heading
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
                  _buildTeamHeader("My Personal Team", isExpanded: false),
                  _buildTeamHeader("Ashar's Team", isExpanded: true, color: const Color(0xFFED7FDE)),
                  _buildNavItem('main_project', 'assets/icons/project.svg', 'Main Project',
                      isIndented: true),
                  _buildNavItem('other_projects', 'assets/icons/folder.svg', 'Other Projects',
                      isIndented: true),
                  _buildNavItem('sub_project', 'assets/icons/project.svg', 'Sub Project',
                      isIndented: true, isSubItem: true),
                ],
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9F9),
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
      {String? badge, bool isIndented = false, bool isSubItem = false, VoidCallback? onPressed}) {
    final bool isActive = widget.currentPage == pageKey;
    final Color contentColor = isActive ? const Color(0xFF252525) : const Color(0xFF707070);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: InkWell(
        onTap: onPressed ?? () => widget.onPageSelected(pageKey),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 39,
          padding: EdgeInsets.fromLTRB(isIndented ? (isSubItem ? 60 : 34) : 8, 8, 8, 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFF0F0F0) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
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