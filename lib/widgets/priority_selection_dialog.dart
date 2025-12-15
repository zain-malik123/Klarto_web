import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PrioritySelectionDialog extends StatelessWidget {
  const PrioritySelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOption(context, 1, 'Priority 1', const Color(0xFFEF4444)),
              _buildOption(context, 2, 'Priority 2', const Color(0xFFF59E0B)),
              _buildOption(context, 3, 'Priority 3', const Color(0xFF3D4CD6)),
              _buildOption(context, 4, 'Priority 4', const Color(0xFF9F9F9F)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, int priority, String label, Color color) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(priority),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(8),
        height: 40,
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/icons/priority.svg',
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF383838),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}