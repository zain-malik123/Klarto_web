import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klarto/apis/filters_api_service.dart'; // We will create this next

class AddFilterDialog extends StatefulWidget {
  const AddFilterDialog({super.key});

  @override
  State<AddFilterDialog> createState() => _AddFilterDialogState();
}

class _AddFilterDialogState extends State<AddFilterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _queryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _filtersApiService = FiltersApiService();

  Color _selectedColor = const Color(0xFFFF6B6B);
  bool _isFavorite = false;
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
    _queryController.dispose();
    _descriptionController.dispose();
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
                      SvgPicture.asset('assets/icons/filter.svg', width: 24, height: 24),
                      const SizedBox(width: 8),
                      const Text('Add Filter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF383838))),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: SvgPicture.asset('assets/icons/close.svg', width: 20, height: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextFieldSection(
                        label: 'Describe Filter',
                        description: 'Describe the filter you want to create',
                        hint: 'Describe your filter',
                        controller: _descriptionController,
                        isRequired: true,
                      ),
                      const SizedBox(height: 24),
                      _buildTextFieldSection(label: 'Filter Name', hint: 'Name your filter', controller: _nameController, isRequired: true),
                      const SizedBox(height: 24),
                      _buildTextFieldSection(label: 'Filter Query', hint: 'e.g., "today & @work"', controller: _queryController, isRequired: true),
                      const SizedBox(height: 24),
                      _buildColorPicker(),
                      const SizedBox(height: 24),
                      _buildFavoriteCheckbox(),
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
                      backgroundColor: const Color(0xFFF9F9F9),
                      foregroundColor: const Color(0xFF707070),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 12),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _handleAddFilter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3D4CD6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          child: const Text('Add Filter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddFilter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _filtersApiService.createFilter(
        name: _nameController.text,
        query: _queryController.text,
        description: _descriptionController.text,
        color: '#${_selectedColor.value.toRadixString(16).substring(2)}', // Convert Color to hex string
        isFavorite: _isFavorite,
      );

      if (!mounted) return;

      if (result['success']) {
        Navigator.of(context).pop(); // Close dialog on success
        // Optionally, show a success snackbar
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['message']}', style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF3D4CD6),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to connect to the server.', style: TextStyle(color: Colors.white)),
            backgroundColor: Color(0xFF3D4CD6)),
      );
    }

    setState(() => _isLoading = false);
  }

  Widget _buildTextFieldSection({required String label, String? description, required String hint, required TextEditingController controller, bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF383838))),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF707070))),
        ],
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: isRequired ? (value) {
            if (value == null || value.trim().isEmpty) {
              return 'This field is required.';
            }
            return null;
          } : null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF9F9F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFF0F0F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFF0F0F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF3D4CD6))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildOrSeparator() {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFF0F0F0))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(fontSize: 12, color: Color(0xFF9F9F9F))),
        ),
        Expanded(child: Divider(color: Color(0xFFF0F0F0))),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Color', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF383838))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: _colors.map((color) {
            bool isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? color : const Color(0xFFF0F0F0), width: 1.5),
                ),
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                    child: isSelected ? SvgPicture.asset('assets/icons/check.svg', fit: BoxFit.scaleDown) : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFavoriteCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _isFavorite,
            onChanged: (val) => setState(() => _isFavorite = val ?? false),
            side: const BorderSide(color: Color(0xFF9F9F9F)),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add to Favourites', style: TextStyle(fontSize: 14, color: Color(0xFF383838))),
              Text('Add this filter to favourties', style: TextStyle(fontSize: 12, color: Color(0xFF707070))),
            ],
          ),
        ),
      ],
    );
  }
}