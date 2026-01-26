import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klarto/apis/user_api_service.dart';
import 'package:klarto/widgets/home/toolbar.dart';

class TeamDetailsScreen extends StatefulWidget {
  final String teamName;
  final VoidCallback? onDeleted;
  const TeamDetailsScreen({super.key, required this.teamName, this.onDeleted});

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  // Styles from HTML
  final Color _bgGray = const Color(0xFFF9F9F9);
  final Color _indigoPrimary = const Color(0xFF3D4CD6);
  final Color _textBlack = const Color(0xFF252525);
  final Color _textGray = const Color(0xFF707070);
  final Color _borderGray = const Color(0xFFF0F0F0);
  final Color _green = const Color(0xFF0B8D3B);
  final Color _red = const Color(0xFFEF4444);

  // Toggle state
  String _selectedTab = 'All'; // Options: 'All', 'Join', 'Not Join'
  List<dynamic> _projects = [];
  List<dynamic> _members = [];
  List<dynamic> _invited = [];
  bool _isLoading = true;
  bool _isLoadingMembers = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _currentSort = 'Name';

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _loadMembersAndInvites();
  }

  Future<void> _loadProjects() async {
    final result = await UserApiService().getProjects();
    if (result['success'] == true) {
      if (mounted) {
        setState(() {
          _projects = result['projects'];
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMembersAndInvites() async {
    try {
      final api = UserApiService();
      final membersRes = await api.getTeamMembers();
      final invitedRes = await api.getInvitedMembers();
      if (mounted) {
        setState(() {
          _members = membersRes['members'] as List<dynamic>? ?? [];
          _invited = invitedRes['invited'] as List<dynamic>? ?? [];
          _isLoadingMembers = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMembers = false;
        });
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text('Are you sure you want to delete "${widget.teamName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteTeam();
    }
  }

  Future<void> _deleteTeam() async {
    try {
      final result = await UserApiService().deleteTeam(widget.teamName);
      
      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team deleted successfully')),
        );
        // Notify parent and potentially redirect
        if (widget.onDeleted != null) {
          widget.onDeleted!();
        } else {
          Navigator.pop(context, 'deleted');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete team: ${result['message']}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete team: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isLoadingMembers) {
      return const Column(
        children: [
          Toolbar(),
          Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    return Column(
      children: [
        const Toolbar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Team Icon (Pinkish bg #ED7FDE)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFED7FDE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.teamName.isEmpty ? 'Development Team' : widget.teamName,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: _textBlack,
                          fontFamily: 'Inter',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz, color: Color(0xFF717171)),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteConfirmation();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Team', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
                  const SizedBox(height: 32),

                  // Search and View Toggles
                  Row(
                    children: [
                      // Search Input
                      Expanded(
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _borderGray),
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset('assets/icons/search.svg',
                                  width: 18, height: 18, colorFilter: ColorFilter.mode(_textGray, BlendMode.srcIn)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value.trim().toLowerCase();
                                    });
                                  },
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'Search...',
                                    hintStyle: TextStyle(color: _textGray, fontSize: 14),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildOutlineBtn('Sort: Name', onTap: () {
                        setState(() {
                          _currentSort = 'Name';
                        });
                      }),
                      const SizedBox(width: 12),
                      _buildOutlineBtn('Sort: Status', onTap: () {
                        setState(() {
                          _currentSort = 'Status';
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Tabs (All / Join / Not Join)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildTabButton('All'),
                          const SizedBox(width: 12),
                          _buildTabButton('Join'),
                          const SizedBox(width: 12),
                          _buildTabButton('Not Join'),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Members / invitations list under the tabs
                  _buildMembersList(),

                  const SizedBox(height: 24),

                  // List Header
                  Row(
                    children: [
                      Icon(Icons.keyboard_arrow_down, size: 20, color: _textBlack),
                      const SizedBox(width: 4),
                      Text('Active Projects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textBlack)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 16),

                  // Project List
                  if (_projects.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("No projects found."),
                    )
                  else
                    ..._projects.where((project) {
                      if (_searchQuery.isNotEmpty) {
                        final name = (project['name'] ?? '').toString().toLowerCase();
                        if (!name.contains(_searchQuery)) return false;
                      }
                      return true;
                    }).map((project) {
                      final int joined = project['joined_count'] ?? 0;
                      final int pending = project['pending_count'] ?? 0;
                      final int total = joined + pending;
                      final String projectName = project['name'] ?? 'Untitled Project';
                      final String teamDisplayName =
                          widget.teamName.isEmpty ? 'Development Team' : widget.teamName;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              projectName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _textBlack,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildProjectCard(
                              title: teamDisplayName,
                              subtitle: "Joined",
                              subtitleColor: _green,
                              iconBg: _textBlack,
                              totalCount: total,
                              greenCount: joined,
                              redCount: pending,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildTabButton(String label) {
    bool isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
        });
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? _textBlack : const Color(0xFFE0E0E0).withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _textGray,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineBtn(String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF3B4AD6).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(color: _indigoPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _buildPeopleForTab() {
    final List<Map<String, dynamic>> allPeople = [];

    // All members (those who have already joined/accepted)
    for (final m in _members) {
      allPeople.add({
        'name': m['name'] ?? m['email'] ?? 'Member',
        'email': m['email'] ?? '',
        'status': 'Joined',
        'isJoined': true,
        'profile_picture_base64': m['profile_picture_base64'],
      });
    }

    // All pending invitations (those who have not joined yet)
    for (final inv in _invited) {
      final statusStr = (inv['status'] ?? '').toString().toLowerCase();
      // Only include pending invitations in the "Not Join" and "All" counts
      if (statusStr == 'pending') {
        allPeople.add({
          'name': inv['invited_name'] ?? inv['email'] ?? 'Pending Member',
          'email': inv['email'] ?? '',
          'status': 'Not Joined',
          'isJoined': false,
          'profile_picture_base64': inv['profile_picture_base64'],
        });
      }
    }

    // Filter
    List<Map<String, dynamic>> filtered = allPeople.where((p) {
      // Tab filter
      bool tabMatch = true;
      if (_selectedTab == 'Join') tabMatch = p['isJoined'] == true;
      if (_selectedTab == 'Not Join') tabMatch = p['isJoined'] == false;
      if (!tabMatch) return false;

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final email = (p['email'] ?? '').toString().toLowerCase();
        if (!name.contains(_searchQuery) && !email.contains(_searchQuery)) return false;
      }
      return true;
    }).toList();

    // Sort
    if (_currentSort == 'Name') {
      filtered.sort((a, b) => (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase()));
    } else if (_currentSort == 'Status') {
      // Joined first
      filtered.sort((a, b) {
        if (a['isJoined'] == b['isJoined']) {
           return (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase());
        }
        return a['isJoined'] == true ? -1 : 1;
      });
    }

    return filtered;
  }

  Widget _buildMembersList() {
    final people = _buildPeopleForTab();
    if (people.isEmpty) {
      String message = 'No members to show.';
      if (_selectedTab == 'Join') message = 'No joined members yet.';
      if (_selectedTab == 'Not Join') message = 'No pending invitations.';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          message,
          style: TextStyle(fontSize: 13, color: _textGray),
        ),
      );
    }

    return Column(
      children: people.map((p) => _buildMemberRow(p)).toList(),
    );
  }

  Widget _buildMemberRow(Map<String, dynamic> person) {
    final String name = (person['name'] ?? '') as String;
    final String email = (person['email'] ?? '') as String;
    final String status = (person['status'] ?? 'Not Joined') as String;
    final bool isJoined = person['isJoined'] == true;
    final String displayName = name.isNotEmpty ? name : (email.isNotEmpty ? email : 'Member');
    final String initials = displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : '?';
    final String? base64Avatar = person['profile_picture_base64'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          _buildAvatarFromBase64(base64Avatar, initials),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textBlack,
                  ),
                ),
                if (email.isNotEmpty && email != displayName) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(fontSize: 12, color: _textGray),
                  ),
                ],
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: isJoined ? _green : _red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFromBase64(String? b64, String initials) {
    if (b64 == null || b64.isEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFFEEF0FF),
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3D4CD6),
          ),
        ),
      );
    }

    try {
      final parts = b64.split(',');
      final encoded = parts.length > 1 ? parts[1] : parts[0];
      final bytes = base64Decode(encoded);
      return CircleAvatar(
        radius: 16,
        backgroundImage: MemoryImage(bytes),
      );
    } catch (_) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFFEEF0FF),
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3D4CD6),
          ),
        ),
      );
    }
  }

  Widget _buildProjectCard({
    required String title,
    required String subtitle,
    required Color subtitleColor,
    required Color iconBg,
    required int totalCount,
    required int greenCount,
    required int redCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borderGray),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderGray),
            ),
            padding: const EdgeInsets.all(6),
            child: SvgPicture.asset('assets/icons/project.svg',
                colorFilter: ColorFilter.mode(_textBlack, BlendMode.srcIn)),
          ),
          const SizedBox(width: 12),
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textBlack)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: subtitleColor)),
              ],
            ),
          ),
          // Pills (All, Joined, Not Joined)
          Row(
            children: [
              _buildPill(totalCount.toString(), 'assets/icons/avatar.svg', _textGray, iconType: 'all'),
              const SizedBox(width: 12),
              _buildPill(greenCount.toString(), 'assets/icons/check.svg', _green, iconType: 'joined'),
              const SizedBox(width: 12),
              _buildPill(redCount.toString(), 'assets/icons/close.svg', _red, iconType: 'not_joined'),
            ],
          ),
          const SizedBox(width: 24),
          // Avatars (overlapping)
          SizedBox(
            width: 44,
            height: 24,
            child: Stack(
              children: [
                Positioned(
                  right: 16,
                  child: CircleAvatar(
                      radius: 12, backgroundColor: Colors.orange, child: Text('A', style: TextStyle(fontSize: 10, color: Colors.white))),
                ),
                Positioned(
                  right: 0,
                  child: CircleAvatar(
                      radius: 12, backgroundColor: Colors.blue, child: Text('B', style: TextStyle(fontSize: 10, color: Colors.white))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderCard({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borderGray),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/project.svg',
              width: 24, height: 24, colorFilter: ColorFilter.mode(_textBlack, BlendMode.srcIn)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textBlack)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _textGray)),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down, size: 20, color: _textGray),
        ],
      ),
    );
  }

  Widget _buildPill(String text, String iconPath, Color color, {String? iconType}) {
    return Row(
      children: [
        SvgPicture.asset(
          iconPath,
          width: 14,
          height: 14,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}
