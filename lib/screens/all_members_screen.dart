import 'package:flutter/material.dart';
import 'package:klarto/widgets/home/toolbar.dart';
import 'package:klarto/apis/user_api_service.dart';

class AllMembersScreen extends StatefulWidget {
  const AllMembersScreen({super.key});

  @override
  State<AllMembersScreen> createState() => _AllMembersScreenState();
}

class _AllMembersScreenState extends State<AllMembersScreen> {
  final List<Map<String, String>> _teamMembers = [];
  final List<Map<String, String>> _invitedMembers = [];

  final TextEditingController _emailController = TextEditingController();
  String? _emailError;
  bool _isValidEmail = false;
  final TextEditingController _teamNameController = TextEditingController();
  final UserApiService _userApi = UserApiService();

  @override
  void dispose() {
    _emailController.dispose();
    _teamNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load available members only. The left column is the "new team" being built by the user.
    _loadInvitedMembers();
  }

  Future<void> _loadInvitedMembers() async {
    final res = await _userApi.getAllMembers();
    if (res['success'] == true && res['users'] is List) {
      final list = res['users'] as List<dynamic>;
      setState(() {
        for (final item in list) {
          try {
            final m = item as Map<String, dynamic>;
            final email = (m['email'] ?? '') as String;
            if (email.isEmpty) continue;
            if (_invitedMembers.any((e) => e['email']?.toLowerCase() == email.toLowerCase())) continue;
            final name = (m['name'] as String?) ?? email.split('@').first;
            _invitedMembers.add({'name': name, 'role': '', 'email': email});
          } catch (_) {}
        }
        _syncInvitedWithTeam();
      });
    }
  }

  Future<void> _loadTeamMembers() async {
    final res = await _userApi.getTeamMembers();
    if (res['success'] == true && res['members'] is List) {
      final list = res['members'] as List<dynamic>;
      setState(() {
        _teamMembers.clear();
        for (final item in list) {
          try {
            final m = item as Map<String, dynamic>;
            final name = (m['name'] as String?) ?? '';
            final email = (m['email'] as String?) ?? '';
            final role = (m['role'] as String?) ?? 'member';
            _teamMembers.add({'name': name, 'role': role, 'email': email});
          } catch (_) {}
        }
        _syncInvitedWithTeam();
      });
    }
  }

  Future<void> _addInvitedToTeam(String email) async {
    final teamName = _teamNameController.text.trim();
    final res = await _userApi.addMemberToTeam(email, teamName: teamName.isEmpty ? null : teamName);
    if (res['success'] == true && res['member'] is Map) {
      final m = res['member'] as Map<String, dynamic>;
      final name = (m['name'] as String?) ?? email.split('@').first;
      setState(() {
        final exists = _teamMembers.any((e) => e['email']?.toLowerCase() == email.toLowerCase());
        if (!exists) _teamMembers.add({'name': name, 'role': (m['role'] as String?) ?? 'member', 'email': email});
        _invitedMembers.removeWhere((x) => x['email']?.toLowerCase() == email.toLowerCase());
        _syncInvitedWithTeam();
      });
      final already = res['alreadyMember'] == true;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(already ? '$email is already a member' : 'Added $email to team')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add member: ${res['message'] ?? 'unknown'}')));
    }
  }

  void _removeFromTeam(String email) {
    setState(() {
      final idx = _teamMembers.indexWhere((m) => (m['email'] ?? '').toLowerCase() == email.toLowerCase());
      if (idx != -1) {
        final member = _teamMembers.removeAt(idx);
        final already = _invitedMembers.any((m) => (m['email'] ?? '').toLowerCase() == email.toLowerCase());
        if (!already) {
          _invitedMembers.insert(0, {'name': member['name'] ?? email.split('@').first, 'role': member['role'] ?? '', 'email': email});
        }
      }
      _syncInvitedWithTeam();
    });
  }

  void _syncInvitedWithTeam() {
    final teamEmails = _teamMembers.map((e) => (e['email'] ?? '').toLowerCase()).toSet();
    _invitedMembers.removeWhere((inv) => teamEmails.contains((inv['email'] ?? '').toLowerCase()));
  }

  void _onEmailChanged(String v) {
    final email = v.trim();
    final emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    setState(() {
      if (email.isEmpty) {
        _isValidEmail = false;
        _emailError = null;
      } else if (!emailRegex.hasMatch(email)) {
        _isValidEmail = false;
        _emailError = 'Enter a valid email address';
      } else if (_teamMembers.any((m) => m['email']?.toLowerCase() == email.toLowerCase()) || _invitedMembers.any((m) => m['email']?.toLowerCase() == email.toLowerCase())) {
        _isValidEmail = false;
        _emailError = 'This user is already a member';
      } else {
        _isValidEmail = true;
        _emailError = null;
      }
    });
  }

  void _inviteMember() {
    final email = _emailController.text.trim();
    if (!_isValidEmail) return;
    setState(() {
      final alreadyInTeam = _teamMembers.any((m) => m['email']?.toLowerCase() == email.toLowerCase());
      if (!alreadyInTeam && !_invitedMembers.any((m) => m['email']?.toLowerCase() == email.toLowerCase())) {
        _invitedMembers.insert(0, {'name': email.split('@').first, 'role': 'Invited', 'email': email});
      }
      _emailController.clear();
      _isValidEmail = false;
      _emailError = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invitation sent to $email')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Toolbar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row (title + team name input)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create your new team', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFF252525))),
                    const SizedBox(height: 12),
                    // Team name input (smaller width)
                    SizedBox(
                      width: 320,
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF0F0F0)),
                        ),
                        child: TextField(
                          controller: _teamNameController,
                          decoration: const InputDecoration(
                            hintText: 'Team name',
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Caption above the lists
                const Text('Choose your team members', style: TextStyle(fontSize: 14, color: Color(0xFF707070))),
                const SizedBox(height: 12),

                // Search + Invite row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF0F0F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Color(0xFF707070)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _emailController,
                                onChanged: _onEmailChanged,
                                decoration: InputDecoration(
                                  hintText: 'Enter email to invite',
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                  errorText: _emailError,
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isValidEmail ? _inviteMember : null,
                      child: const Text('Invite Member'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(140, 44),
                        backgroundColor: _isValidEmail ? const Color(0xFF3D4CD6).withOpacity(0.12) : const Color(0xFFF0F0F0),
                        foregroundColor: const Color(0xFF3D4CD6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Two-column members layout: left = current team members, right = invited members
                LayoutBuilder(builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;

                  Widget buildMemberItem(Map<String, String>? m, {bool showAddButton = false, bool showRemoveButton = false}) {
                    final safeMap = m ?? {'name': '', 'role': '', 'email': ''};
                    final nameStr = safeMap['name'] ?? '';
                    final initials = nameStr.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join();
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFEFEFFF),
                            child: Text(initials, style: const TextStyle(color: Color(0xFF3D4CD6), fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nameStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF252525))),
                                const SizedBox(height: 4),
                                Text('${safeMap['role'] ?? ''} • ${safeMap['email'] ?? ''}', style: const TextStyle(color: Color(0xFF707070))),
                              ],
                            ),
                          ),
                          if (showAddButton) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                final email = safeMap['email'] ?? '';
                                if (email.isNotEmpty) _addInvitedToTeam(email);
                              },
                              icon: const Icon(Icons.add, color: Color(0xFF3D4CD6)),
                              tooltip: 'Add',
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              splashRadius: 18,
                            ),
                          ],
                          if (showRemoveButton) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                final email = safeMap['email'] ?? '';
                                if (email.isNotEmpty) _removeFromTeam(email);
                              },
                              icon: const Icon(Icons.remove, color: Color(0xFFB00020)),
                              tooltip: 'Remove',
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              splashRadius: 18,
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  Widget leftColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New team members', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF252525))),
                      const SizedBox(height: 12),
                      DragTarget<String>(
                        onWillAccept: (data) {
                          if (data == null) return false;
                          final exists = _teamMembers.any((m) => m['email']?.toLowerCase() == data.toLowerCase());
                          return !exists;
                        },
                        onAccept: (data) {
                          _addInvitedToTeam(data);
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            decoration: BoxDecoration(
                              border: candidateData.isNotEmpty ? Border.all(color: const Color(0xFF3D4CD6), width: 2) : null,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.all(4),
                                child: Column(
                                  children: [
                                    for (var i = 0; i < _teamMembers.length; i++) ...[
                                      buildMemberItem(_teamMembers[i], showRemoveButton: true),
                                      if (i != _teamMembers.length - 1) const SizedBox(height: 12),
                                    ],
                                  ],
                                ),
                          );
                        },
                      ),
                    ],
                  );

                  Widget rightColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available members', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF252525))),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          for (var i = 0; i < _invitedMembers.length; i++) ...[
                            (() {
                              final item = _invitedMembers[i];
                              final email = item['email'] ?? '';
                              return LongPressDraggable<String>(
                                data: email,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 280),
                                    child: Opacity(
                                      opacity: 0.95,
                                      child: buildMemberItem(item, showAddButton: true),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(opacity: 0.45, child: buildMemberItem(item, showAddButton: true)),
                                child: buildMemberItem(item, showAddButton: true),
                              );
                            })(),
                            if (i != _invitedMembers.length - 1) const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ],
                  );

                  if (isWide) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: leftColumn),
                          // vertical divider between the lists (full height)
                          Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 20), color: const Color(0xFFE6E6E6)),
                          Expanded(child: rightColumn),
                        ],
                      ),
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        leftColumn,
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFE6E6E6)),
                        const SizedBox(height: 12),
                        rightColumn,
                      ],
                    );
                  }
                }),
              ],
            ),
          ),
        ),

        // Add Team button at bottom (compact, matches Add Filter styling)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 140,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Add Team', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D4CD6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
