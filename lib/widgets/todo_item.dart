import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TodoItem extends StatelessWidget {
  final String title;
  final String subtaskCount;
  final String time;
  final String tag;

  const TodoItem({
    super.key,
    required this.title,
    required this.subtaskCount,
    required this.time,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF0F0F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: false,
                onChanged: (value) {},
                visualDensity: VisualDensity.compact,
                side: const BorderSide(color: Color(0xFF707070), width: 2),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Row(
              children: [
                _buildMetaItem('assets/icons/subtasks.svg', subtaskCount),
                const SizedBox(width: 12),
                _buildMetaItem('assets/icons/clock.svg', time),
                const SizedBox(width: 12),
                _buildMetaItem('assets/icons/tag.svg', tag),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String iconPath, String text) {
    return Row(
      children: [
        SvgPicture.asset(
          iconPath,
          width: 14,
          height: 14,
          colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF707070)),
        ),
      ],
    );
  }
}