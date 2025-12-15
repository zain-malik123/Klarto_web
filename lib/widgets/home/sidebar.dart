import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Sidebar extends StatelessWidget {
  final String currentPage;
  final Function(String) onPageSelected;
  final int overdueCount;

  const Sidebar({
    super.key, required this.currentPage, required this.onPageSelected, required this.overdueCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: const Color(0xFFF9F9F9),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('assets/images/logo.png', width: 22, height: 22),
                    const SizedBox(width: 6),
                    const Text('Klarto', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF3B4AD6))),
                  ],
                ),
                IconButton(onPressed: () {}, icon: SvgPicture.asset('assets/icons/grid.svg')),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // User & Notifications
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        const Icon(Icons.account_circle_outlined, size: 24, color: Color(0xFF707070)),
                        const SizedBox(width: 8),
                        const Text('James', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Stack(
                          children: [
                            IconButton(onPressed: () {}, icon: SvgPicture.asset('assets/icons/bell.svg')),
                            const Positioned(
                              top: 8, right: 8,
                              child: CircleAvatar(radius: 4, backgroundColor: Color(0xFF3D4CD6)),
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
                    icon: SvgPicture.asset('assets/icons/add.svg'),
                    label: const Text('Add Todo'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color(0xFF3D4CD6).withOpacity(0.08),
                      foregroundColor: const Color(0xFF3D4CD6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Nav Items
                  _buildNavItem('search', 'assets/icons/search.svg', 'Search'),
                  const SizedBox(height: 3),
                  _buildNavItem('dock', 'assets/icons/dock.svg', 'Dock'),
                  const SizedBox(height: 3),
                  _buildNavItem('today', 'assets/icons/today.svg', 'Today', onPressed: () => onPageSelected('today')),
                  const SizedBox(height: 3),
                  if (overdueCount > 0) _buildNavItem('overdue', 'assets/icons/overdue.svg', 'Overdue', badge: overdueCount.toString()),
                  const SizedBox(height: 3),
                  _buildNavItem('filters_and_labels', 'assets/icons/filters.svg', 'Filters & Labels'),
                  const SizedBox(height: 3),
                  _buildNavItem('activity', 'assets/icons/activity.svg', 'Activity'),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF0F0F0), height: 1),
                  const SizedBox(height: 16),
                  // Favorites Heading
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Favorites',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF383838)))),
                  ),
                  _buildNavItem('project_1', 'assets/icons/project.svg', 'Project 1'),
                  const SizedBox(height: 3),
                  _buildNavItem('usman_todos', 'assets/icons/filter.svg', "Usman's Todos"),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF0F0F0), height: 1),
                  const SizedBox(height: 16),
                  // Teams Heading
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Teams',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF383838)))),
                  ),
                  _buildTeamHeader("My Personal Team", isExpanded: false),
                  const SizedBox(height: 3),
                  _buildTeamHeader("Ashar's Team", isExpanded: true, color: const Color(0xFFED7FDE)),                  const SizedBox(height: 3),
                  _buildNavItem('main_project', 'assets/icons/project.svg', 'Main Project', isIndented: true),
                  const SizedBox(height: 3),
                  _buildNavItem('other_projects', 'assets/icons/folder.svg', 'Other Projects', isIndented: true),
                  const SizedBox(height: 3),
                  _buildNavItem('sub_project', 'assets/icons/project.svg', 'Sub Project', isIndented: true, isSubItem: true),
                ],
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: Row(
              children: [
                SvgPicture.asset('assets/icons/help.svg', width: 20, height: 20),
                const SizedBox(width: 8),
                const Text('Get Help', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF707070))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String pageKey, String iconPath, String label, {String? badge, bool isIndented = false, bool isSubItem = false, VoidCallback? onPressed}) {
    final bool isActive = currentPage == pageKey;
    return TextButton.icon(
      onPressed: onPressed ?? () => onPageSelected(pageKey),
      icon: SvgPicture.asset(iconPath, colorFilter: ColorFilter.mode(isActive ? const Color(0xFF383838) : const Color(0xFF707070), BlendMode.srcIn)),
      label: Row(
        children: [
          Text(label),
          const Spacer(),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.12),
                borderRadius: BorderRadius.circular(48),
              ),
              child: Text(badge, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
            ),
        ],
      ),
      style: TextButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        padding: EdgeInsets.fromLTRB(isIndented ? (isSubItem ? 60 : 34) : 8, 8, 8, 8),
        backgroundColor: isActive ? const Color(0xFFF0F0F0) : Colors.transparent,
        foregroundColor: isActive ? const Color(0xFF383838) : const Color(0xFF707070),
        alignment: Alignment.centerLeft,
        textStyle: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.w500 : FontWeight.normal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildTeamHeader(String name, {bool isExpanded = false, Color? color}) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        foregroundColor: const Color(0xFF707070),
      ),
      child: Row(
        children: [
          if (color != null)
            Container(width: 20, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)))
          else
            const Icon(Icons.account_circle_outlined, size: 20, color: Color(0xFF707070)),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
          if (isExpanded) SvgPicture.asset('assets/icons/chevron-down.svg'),
        ],
      ),
    );
  }
}