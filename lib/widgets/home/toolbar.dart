import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Toolbar extends StatelessWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () {},
            icon: SvgPicture.asset(
              'assets/icons/view.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
            ),
            label: const Text('View'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF707070)),
          ),
          const SizedBox(height: 32, child: VerticalDivider(color: Color(0xFFE0E0E0))),
          TextButton.icon(
            onPressed: () {},
            icon: SvgPicture.asset(
              'assets/icons/notes.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
            ),
            label: const Text('Notes'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF707070)),
          ),
          const SizedBox(height: 32, child: VerticalDivider(color: Color(0xFFE0E0E0))),
          IconButton(
              onPressed: () {},
              icon: SvgPicture.asset(
                'assets/icons/align.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
              )),
        ],
      ),
    );
  }
}