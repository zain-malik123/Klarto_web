import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klarto/apis/user_api_service.dart';

class AddProjectDialog extends StatefulWidget {
  final List<String>? teams;
  const AddProjectDialog({super.key, this.teams});

  @override
  State<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
  final _userApi = UserApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  Color _selectedColor = const Color(0xFFFF6B6B);
  bool _isFavorite = false;
  String _selectedAccess = 'Private';
  bool _isLoading = false;

  final List<Color> _colors = [
    const Color(0xFFFF6B6B),
    const Color(0xFF00C896),
    const Color(0xFF3A86FF),
    const Color(0xFF9B5DE5),
    const Color(0xFFFF8FA3),
    const Color(0xFF4ECDC4),
    const Color(0xFFF7B500),
    const Color(0xFF6C757D),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset('assets/icons/project.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Color(0xFF252525), BlendMode.srcIn)),
                      const SizedBox(width: 8),
                      const Text('Add Project', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF252525))),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: SvgPicture.asset('assets/icons/close.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF252525))),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration('Enter project name'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 24),
                      
                      const Text('Color', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF252525))),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _colors.map((color) => _buildColorDot(color)).toList(),
                      ),
                      const SizedBox(height: 24),

                      const Text('Access', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF252525))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF0F0F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAccess,
                            isExpanded: true,
                            items: ['Private', ...(widget.teams ?? [])]
                                .map<DropdownMenuItem<String>>((s) => DropdownMenuItem<String>(value: s, child: Text(s, style: const TextStyle(fontSize: 14))))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedAccess = val!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          _buildCustomSwitch(
                            value: _isFavorite,
                            onChanged: (val) => setState(() => _isFavorite = val),
                          ),
                          const SizedBox(width: 12),
                          const Text('Add to favorites', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF252525))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF9F9F9).withOpacity(0.5),
                      foregroundColor: const Color(0xFF707070),
                      minimumSize: const Size(80, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleAddProject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D4CD6),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Add Project', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF9F9F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFF0F0F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFF0F0F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF3D4CD6))),
    );
  }

  Widget _buildColorDot(Color color) {
    final bool isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: const Color(0xFF3D4CD6), width: 2) : null,
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
      ),
    );
  }

  Widget _buildCustomSwitch({required bool value, required ValueChanged<bool> onChanged}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 36,
        height: 20,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: value ? const Color(0xFF3D4CD6) : const Color(0xFFE0E0E0),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddProject() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      final res = await _userApi.createProject(
        name: _nameController.text.trim(),
        color: '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
        access: _selectedAccess,
        isFavorite: _isFavorite,
      );

      if (mounted) {
        if (res['success'] == true) {
          Navigator.of(context).pop({
            'success': true,
            'name': _nameController.text,
            'access': _selectedAccess,
            'color': _selectedColor.value,
            'isFavorite': _isFavorite,
            'project': res['project'],
          });
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to create project')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error creating project')),
        );
      }
    }
  }
}
