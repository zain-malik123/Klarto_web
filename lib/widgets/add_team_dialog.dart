import 'dart:async';
import 'package:flutter/material.dart';
import 'package:klarto/apis/user_api_service.dart';

class AddTeamDialog extends StatefulWidget {
  const AddTeamDialog({super.key});

  @override
  State<AddTeamDialog> createState() => _AddTeamDialogState();
}

class _AddTeamDialogState extends State<AddTeamDialog> {
  final _teamNameController = TextEditingController();
  final UserApiService _userApi = UserApiService();
  List<Map<String, String>> _candidates = [];
  final Set<String> _selected = {};
  bool _loading = false;
  final TextEditingController _inviteEmailController = TextEditingController();
  String? _inviteError;
  Map<String, Map<String, dynamic>> _inviteResults = {};
  Timer? _debounceTimer;
  Map<String, bool> _isMemberMap = {};
  bool _readyToInvite = false;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
    _inviteEmailController.addListener(() {
      _scheduleMemberChecks();
    });
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _inviteEmailController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  List<String> _parsedInviteEmails() {
    final raw = _inviteEmailController.text;
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  void _scheduleMemberChecks() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final emails = _parsedInviteEmails();
      if (emails.isEmpty) return;
      try {
        final checks = await Future.wait(emails.map((e) => _userApi.isMemberOfInviterTeam(e)));
        final map = <String, bool>{};
        for (var i = 0; i < emails.length; i++) map[emails[i]] = checks[i];
        if (mounted) setState(() { _isMemberMap = map; });
      } catch (_) {}
    });
  }

  List<Widget> _buildEmailTagsFromInput() {
    final emails = _parsedInviteEmails();
    return emails.take(5).map((e) => _buildEmailTag(e)).toList();
  }

  Widget _buildEmailTag(String email) {
    final valid = _isValidEmail(email);
    final alreadyMember = _isMemberMap[email] == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: alreadyMember ? const Color(0xFFE3F2FD) : (valid ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE)),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: alreadyMember ? const Color(0xFF2196F3) : (valid ? const Color(0xFF66BB6A) : const Color(0xFFEF5350))),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            alreadyMember ? Icons.person : (valid ? Icons.check_circle_outline : Icons.error_outline),
            size: 16,
            color: alreadyMember ? const Color(0xFF1976D2) : (valid ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
          ),
          const SizedBox(width: 8),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: alreadyMember ? const Color(0xFF1976D2) : (valid ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              final current = _inviteEmailController.text;
              final parts = current.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
              parts.removeWhere((p) => p == email);
              _inviteEmailController.text = parts.join(', ');
              _inviteEmailController.selection = TextSelection.fromPosition(TextPosition(offset: _inviteEmailController.text.length));
              if (mounted) setState(() {});
            },
            child: Icon(
              Icons.close,
              size: 14,
              color: alreadyMember ? const Color(0xFF1976D2) : (valid ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCandidates() async {
    try {
      final res = await _userApi.getAllMembers();
      if (res['success'] == true && res['users'] is List) {
        final list = res['users'] as List<dynamic>;
        setState(() {
          _candidates = list.whereType<Map<String, dynamic>>().map((m) {
            final email = (m['email'] as String?) ?? '';
            final name = (m['name'] as String?) ?? (email.split('@').first);
            return {'name': name, 'email': email};
          }).where((m) => (m['email'] ?? '').isNotEmpty).cast<Map<String, String>>().toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _handleSubmit() async {
    final teamName = _teamNameController.text.trim();
    if (teamName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a team name')));
      return;
    }
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one member')));
      return;
    }
    setState(() => _loading = true);
    try {
      final emails = _selected.toList();
      final res = await _userApi.createTeam(teamName, emails);
      
      if (!mounted) return;
      if (res['success'] == true) {
        Navigator.of(context).pop({'created': true, 'teamName': teamName});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create team: ${res['message'] ?? 'unknown error'}'))
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create team: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isValidEmail(String email) {
    final e = email.trim();
    final regex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    return regex.hasMatch(e);
  }

  Future<void> _inviteEmail() async {
    final raw = _inviteEmailController.text;
    final emails = raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (emails.isEmpty) {
      setState(() => _inviteError = 'Enter an email');
      return;
    }
    if (emails.length > 5) {
      setState(() => _inviteError = 'You can invite up to 5 addresses at once');
      return;
    }
    final invalid = emails.where((e) => !_isValidEmail(e)).toList();
    if (invalid.isNotEmpty) {
      setState(() => _inviteError = 'Invalid: ${invalid.join(', ')}');
      return;
    }
    setState(() => _inviteError = null);
    setState(() => _loading = true);
    final res = await _userApi.inviteTeam(emails);
    if (res['success'] == true) {
      final List<dynamic> results = res['results'] ?? [];
      final mapped = <String, Map<String, dynamic>>{};
      for (final r in results) {
        try {
          final rr = Map<String, dynamic>.from(r as Map);
          mapped[(rr['email'] as String).toLowerCase()] = rr;
        } catch (_) {}
      }
      setState(() {
        _inviteResults.addAll(mapped);
        for (final email in emails) {
          final lower = email.toLowerCase();
          final exists = _candidates.any((m) => (m['email'] ?? '').toLowerCase() == lower);
          final name = email.split('@').first;
          if (!exists) {
            _candidates.insert(0, {'name': name, 'email': email});
          }
          _selected.add(lower);
        }
      });
      _inviteEmailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitations processed.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invite failed: ${res['message'] ?? 'unknown'}')));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.group, size: 24, color: Color(0xFF3D4CD6)),
                      const SizedBox(width: 8),
                      const Text('Create Team', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF383838))),
                    ],
                  ),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Team name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF383838))),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 320,
                      child: TextField(
                        controller: _teamNameController,
                        decoration: InputDecoration(
                          hintText: 'Enter team name',
                          filled: true,
                          fillColor: const Color(0xFFF9F9F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFF0F0F0))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select members', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF383838))),
                    const SizedBox(height: 8),
                    // Invite by email row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inviteEmailController,
                            decoration: InputDecoration(
                              hintText: 'Invite by email',
                              errorText: _inviteError,
                              filled: true,
                              fillColor: const Color(0xFFF9F9F9),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFF0F0F0))),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _inviteEmail,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                          child: const Text('Invite', style: TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Email tags (live validation)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _buildEmailTagsFromInput(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_inviteResults.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          const Text('Invitation results:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ..._inviteResults.entries.map((e) {
                            final email = e.key;
                            final info = e.value;
                            final success = info['success'] == true;
                            final message = info['message'] ?? (success ? 'Invitation sent.' : 'Failed');
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Icon(success ? Icons.check_circle_outline : Icons.error_outline,
                                    size: 18, color: success ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('$email — $message', style: TextStyle(color: success ? const Color(0xFF2E7D32) : const Color(0xFFC62828)))),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: _candidates.isEmpty
                          ? const Center(child: Padding(padding: EdgeInsets.all(12), child: Text('No members')))
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: _candidates.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
                              itemBuilder: (context, i) {
                                final m = _candidates[i];
                                final email = m['email'] ?? '';
                                final name = m['name'] ?? '';
                                final selected = _selected.contains(email.toLowerCase());
                                final lower = email.toLowerCase();
                                final isMember = (_isMemberMap[lower] == true) || (_inviteResults[lower]?['alreadyMember'] == true) || (_inviteResults[lower]?['is_member'] == true);
                                final inviteInfo = _inviteResults[lower];
                                return CheckboxListTile(
                                  value: selected,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) _selected.add(email.toLowerCase()); else _selected.remove(email.toLowerCase());
                                    });
                                  },
                                  title: Row(
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: const Color(0xFFEFEFFF),
                                            child: Text(name.isNotEmpty ? name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join() : '', style: const TextStyle(color: Color(0xFF3D4CD6), fontWeight: FontWeight.w600)),
                                          ),
                                          if (isMember) Positioned(
                                            left: 24,
                                            top: -2,
                                            child: Container(
                                              width: 14,
                                              height: 14,
                                              decoration: BoxDecoration(color: const Color(0xFFB0B0B0), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)),
                                              child: const Icon(Icons.check, size: 10, color: Colors.white),
                                            ),
                                          ) else if (inviteInfo != null) Positioned(
                                            left: 24,
                                            top: -2,
                                            child: Container(
                                              width: 14,
                                              height: 14,
                                              decoration: BoxDecoration(color: const Color(0xFF3D4CD6), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)),
                                              child: const Icon(Icons.mail, size: 10, color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF707070))),
                                                const SizedBox(width: 8),
                                                if (isMember) const Text('Already a member', style: TextStyle(fontSize: 12, color: Color(0xFF9F9F9F))),
                                                if (!isMember && inviteInfo != null && (inviteInfo['message'] as String?) != null) Text(inviteInfo['message'], style: const TextStyle(fontSize: 12, color: Color(0xFF707070))),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: null,
                                  controlAffinity: ListTileControlAffinity.leading,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF9F9F9),
                      foregroundColor: const Color(0xFF707070),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 12),
                  _loading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3D4CD6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          child: const Text('Create Team', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
