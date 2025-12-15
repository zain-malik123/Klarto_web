import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klarto/widgets/home/toolbar.dart';
import 'package:klarto/widgets/add_filter_dialog.dart';
import 'package:klarto/widgets/add_label_dialog.dart';

class FiltersAndLabelsScreen extends StatelessWidget {
  const FiltersAndLabelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const Toolbar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(120, 28, 120, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters & Labels',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF383838)),
                  ),
                  const SizedBox(height: 32),
                  _buildSection(
                    title: 'Filters',
                    onAdd: () {
                      showDialog(
                        context: context,
                        builder: (context) => const AddFilterDialog(),
                      );
                    },
                    items: [
                      _buildListItem(iconPath: 'assets/icons/filter.svg', title: "Usman's Todos", count: 2),
                      _buildListItem(iconPath: 'assets/icons/filter.svg', title: "Work Todos", count: 2),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSection(
                    title: 'Labels',
                    onAdd: () {
                      showDialog(
                        context: context,
                        builder: (context) => const AddLabelDialog(),
                      );
                    },
                    items: [
                      _buildListItem(iconPath: 'assets/icons/tag.svg', title: "Work Todos", count: 2),
                      _buildListItem(iconPath: 'assets/icons/tag.svg', title: "Personal", count: 2),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required VoidCallback onAdd, required List<Widget> items}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF383838))),
            TextButton.icon(
              onPressed: onAdd,
              icon: SvgPicture.asset('assets/icons/add-square.svg', width: 14, height: 14),
              label: Text('Add ${title.substring(0, title.length - 1)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF3D4CD6),
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
        const Divider(height: 25, color: Color(0xFFF0F0F0)),
        Column(children: items),
      ],
    );
  }

  Widget _buildListItem({required String iconPath, required String title, required int count}) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF0F0F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SvgPicture.asset(iconPath, width: 20, height: 20, colorFilter: const ColorFilter.mode(Color(0xFF383838), BlendMode.srcIn)),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF383838))),
          const SizedBox(width: 6),
          Text('($count Todos)', style: const TextStyle(fontSize: 12, color: Color(0xFF707070))),
          const Spacer(),
          _buildActionIcon('assets/icons/trash.svg'),
          const SizedBox(width: 10),
          _buildActionIcon('assets/icons/link.svg'),
          const SizedBox(width: 10),
          _buildActionIcon('assets/icons/edit.svg'),
          const SizedBox(width: 10),
          _buildActionIcon('assets/icons/heart.svg'),
          const SizedBox(width: 10),
          const VerticalDivider(width: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(width: 10),
          _buildActionIcon('assets/icons/three-dots.svg'),
        ],
      ),
    );
  }

  Widget _buildActionIcon(String iconPath) {
    return IconButton(
      onPressed: () {},
      icon: SvgPicture.asset(iconPath, width: 18, height: 18),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}