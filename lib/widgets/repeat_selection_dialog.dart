import 'package:flutter/material.dart';

class RepeatSelectionDialog extends StatelessWidget {
  const RepeatSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOption(context, 'No Repeat'),
              _buildOption(context, 'Every Day'),
              _buildOption(context, 'Every Week', 'On Saturday'),
              _buildOption(context, 'Every Weekday', '(Mon - Fri)'),
              _buildOption(context, 'Every Month', 'On the 25th'),
              _buildOption(context, 'Every Year', 'On October 25th'),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement custom repeat logic
                  Navigator.of(context).pop('Custom');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D4CD6).withOpacity(0.08),
                  foregroundColor: const Color(0xFF3D4CD6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Custom'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, [String? subtitle]) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(title),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(8),
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF383838),
                fontWeight: FontWeight.w400,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9F9F9F),
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}