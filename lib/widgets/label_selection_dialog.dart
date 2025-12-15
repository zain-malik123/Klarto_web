import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klarto/apis/labels_api_service.dart';
import 'package:klarto/models/label.dart';

class LabelSelectionDialog extends StatefulWidget {
  const LabelSelectionDialog({super.key});

  @override
  State<LabelSelectionDialog> createState() => _LabelSelectionDialogState();
}

class _LabelSelectionDialogState extends State<LabelSelectionDialog> {
  final LabelsApiService _labelsApiService = LabelsApiService();
  late Future<List<Label>> _labelsFuture;

  @override
  void initState() {
    super.initState();
    _labelsFuture = _fetchLabels();
  }

  Future<List<Label>> _fetchLabels() async {
    final result = await _labelsApiService.getLabels();
    if (result['success'] && result['data'] is List) {
      return (result['data'] as List).map((json) => Label.fromJson(json)).toList();
    }
    // In a real app, you might want to show an error message.
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 264, maxHeight: 400),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: FutureBuilder<List<Label>>(
            future: _labelsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No labels found.'));
              }
              final labels = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: labels.length,
                itemBuilder: (context, index) {
                  return _buildOption(context, labels[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, Label label) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(label),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(8),
        height: 40,
        child: Row(
          children: [
            SvgPicture.asset('assets/icons/tag.svg', width: 18, height: 18, colorFilter: const ColorFilter.mode(Color(0xFF707070), BlendMode.srcIn)),
            const SizedBox(width: 8),
            Text(label.name, style: const TextStyle(fontSize: 14, color: Color(0xFF383838), fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}