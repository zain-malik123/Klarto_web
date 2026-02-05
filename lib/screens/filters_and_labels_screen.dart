import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klarto/widgets/home/toolbar.dart';
import 'package:klarto/widgets/add_filter_dialog.dart';
import 'package:klarto/widgets/add_label_dialog.dart';
import 'package:klarto/screens/filtered_todos_screen.dart';
import 'package:klarto/screens/main_app_shell.dart';
import 'package:klarto/apis/filters_api_service.dart';
import 'package:klarto/apis/labels_api_service.dart';

class FiltersAndLabelsScreen extends StatefulWidget {
  const FiltersAndLabelsScreen({super.key});

  @override
  State<FiltersAndLabelsScreen> createState() => _FiltersAndLabelsScreenState();
}

class _FiltersAndLabelsScreenState extends State<FiltersAndLabelsScreen> {
  final FiltersApiService _filtersApiService = FiltersApiService();
  final LabelsApiService _labelsApiService = LabelsApiService();

  late Future<List<dynamic>> _filtersFuture;
  late Future<List<dynamic>> _labelsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _filtersFuture = _getFilters();
    _labelsFuture = _getLabels();
  }

  Future<List<dynamic>> _getFilters() async {
    final result = await _filtersApiService.getFilters();
    return result['success'] ? result['data'] : [];
  }

  Future<List<dynamic>> _getLabels() async {
    final result = await _labelsApiService.getLabels();
    return result['success'] ? result['data'] : [];
  }

  Future<void> _deleteItem(String type, String id) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${type.substring(0, type.length - 1)}'),
        content: Text('Are you sure you want to delete this ${type.substring(0, type.length - 1)}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = type == 'Filters'
          ? await _filtersApiService.deleteFilter(id)
          : await _labelsApiService.deleteLabel(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Action completed.', style: const TextStyle(color: Colors.white)),
          backgroundColor: result['success'] ? Colors.green : const Color(0xFF3D4CD6),
        ),
      );

      if (result['success']) {
        setState(() {
          _loadData();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Let parent handle background
      body: Column(
        children: [
          const Toolbar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters & Labels',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF383838)),
                  ),
                  const SizedBox(height: 32),
                  FutureBuilder<List<dynamic>>(
                    future: _filtersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Text('Failed to load filters.');
                      }
                      final filters = snapshot.data!;
                      return _buildSection(
                        title: 'Filters',
                        showAddButton: false, // User requested to remove Add filter button
                        onAdd: () async {
                          await showDialog(context: context, builder: (context) => const AddFilterDialog());
                          setState(() { _loadData(); }); // Refresh data after dialog closes
                        },
                        items: filters.map((filter) => 
                          _buildListItem(type: 'Filters', item: filter, count: 0)
                        ).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  FutureBuilder<List<dynamic>>(
                    future: _labelsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Text('Failed to load labels.');
                      }
                      final labels = snapshot.data!;
                      return _buildSection(
                        title: 'Labels',
                        showAddButton: true,
                        onAdd: () async {
                          await showDialog(context: context, builder: (context) => const AddLabelDialog());
                          setState(() { _loadData(); }); // Refresh data after dialog closes
                        },
                        items: labels.map((label) => 
                          _buildListItem(type: 'Labels', item: label, count: 0)
                        ).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required VoidCallback onAdd, required List<Widget> items, bool showAddButton = true}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF383838))),
            if (showAddButton)
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

  Widget _buildListItem({required String type, required Map<String, dynamic> item, required int count}) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF0F0F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (type == 'Filters')
            SvgPicture.asset('assets/icons/filter.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Color(0xFF383838), BlendMode.srcIn))
          else
            Icon(
              Icons.label,
              size: 20,
              color: item['color'] != null ? _hexToColor(item['color'] as String) : const Color(0xFF383838),
            ),
          const SizedBox(width: 6),
          // Make the name tappable for Filters to open a filtered todo view
          if (type == 'Filters')
            GestureDetector(
              onTap: () {
                final rawQuery = item['query'] as String?;
                final query = (rawQuery != null && rawQuery.trim().isNotEmpty) ? rawQuery.trim() : null;
                final title = (item['name'] as String?) ?? 'Filter';
                if (query == null) {
                  print('FiltersAndLabels: tapped filter "${title}" but query is empty');
                  return; // nothing to open
                }
                print('FiltersAndLabels: opening filter "$title" -> query="$query"');
                // Map certain well-known filter queries to the named pages used by
                // the left menu so the behavior matches the left nav (Today/Overdue).
                final qLower = query.toLowerCase();
                if (qLower == 'due_today' || qLower == 'today') {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MainAppShell(initialPage: 'today')));
                } else if (qLower == 'overdue') {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MainAppShell(initialPage: 'overdue')));
                } else {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MainAppShell(initialFilter: query, initialFilterTitle: title)));
                }
              },
              child: Text(item['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF383838))),
            )
          else
            Text(item['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF383838))),
          const SizedBox(width: 6),
          Text('($count Todos)', style: const TextStyle(fontSize: 12, color: Color(0xFF707070))),
          const Spacer(),
          if (type != 'Filters')
            _buildActionIcon('assets/icons/trash.svg', () => _deleteItem(type, item['id'])),
          const SizedBox(width: 10),
          _buildActionIcon('assets/icons/link.svg'),
          const SizedBox(width: 10),
          _buildActionIcon('assets/icons/edit.svg', type == 'Labels' ? () async {
            await showDialog(
              context: context,
              builder: (context) => AddLabelDialog(label: item),
            );
            setState(() { _loadData(); });
          } : null),
          const SizedBox(width: 10),
          if (type == 'Filters')
            (() {
              final id = item['id'] as String?;
              final current = (item['is_favorite'] ?? false) as bool;
              return IconButton(
                onPressed: () async {
                  if (id == null) return;
                  final res = await _filtersApiService.updateFilterFavorite(id, !current);
                  if (res['success'] == true) {
                    // Refresh filters list and rebuild main shell so sidebar reloads favorites
                    if (mounted) setState(() { _loadData(); });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(!current ? 'Added to favorites' : 'Removed from favorites')));
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MainAppShell(initialPage: 'filters_and_labels')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to update favorite')));
                  }
                },
                icon: current
                  ? const Icon(Icons.favorite, size: 18, color: Color(0xFFE53935))
                  : const Icon(Icons.favorite_border, size: 18, color: Color(0xFF707070)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              );
            })()
          else
            _buildActionIcon('assets/icons/heart.svg'),
          const SizedBox(width: 10),
          const VerticalDivider(width: 1, color: Color(0xFFF0F0F0)),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF383838);
    }
  }

  Widget _buildActionIcon(String iconPath, [VoidCallback? onPressed]) {
    return IconButton(
      onPressed: onPressed,
      icon: SvgPicture.asset(iconPath, width: 18, height: 18),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}
