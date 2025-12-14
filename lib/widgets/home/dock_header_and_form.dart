import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DockHeaderAndForm extends StatefulWidget {
  const DockHeaderAndForm({super.key});

  @override
  State<DockHeaderAndForm> createState() => _DockHeaderAndFormState();
}

class _DockHeaderAndFormState extends State<DockHeaderAndForm> {
  String _selectedLocation = 'Dock';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dock', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Todo Title',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF707070)),
                ),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Todo Description',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 14, color: Color(0xFF9F9F9F)),
                ),
                style: TextStyle(fontSize: 14, color: Color(0xFF383838)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildBadgeButton('assets/icons/calendar.svg', 'Date'),
                  const SizedBox(width: 8),
                  _buildBadgeButton('assets/icons/priority.svg', 'Priority'),
                  const SizedBox(width: 8),
                  _buildBadgeButton('assets/icons/tag.svg', 'Label'),
                ],
              ),
              const Divider(height: 25, color: Color(0xFFF0F0F0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/send.svg',
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        color: Colors.white,
                        child: DropdownButton<String>(
                          value: _selectedLocation,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedLocation = newValue!;
                            });
                          },
                          items: <String>['Dock', 'Project 1', 'Work Todos']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF707070))),
                            );
                          }).toList(),
                          dropdownColor: Colors.white,
                          underline: Container(),
                          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF707070)),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF707070),
                          backgroundColor: const Color(0xFFF9F9F9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text(
                          'Add Todo',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF3D4CD6),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeButton(String iconPath, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: SvgPicture.asset(iconPath, colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn)),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF707070),
        side: const BorderSide(color: Color(0xFFF0F0F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}