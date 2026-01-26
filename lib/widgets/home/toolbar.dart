import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klarto/widgets/notes_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:klarto/screens/login_screen.dart';

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
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const NotesModal(),
              );
            },
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Color(0xFF707070)),
            onSelected: (value) async {
              if (value == 'logout') {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('jwt_token');
                await prefs.remove('user_id');
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}