import 'package:flutter/material.dart';
import 'package:klarto/apis/user_api_service.dart';
import 'package:klarto/config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io' as io;
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class NotesModal extends StatefulWidget {
  const NotesModal({super.key});

  @override
  State<NotesModal> createState() => _NotesModalState();
}

class _NotesModalState extends State<NotesModal> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  
  // Recording state
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;

  // Audio Playback state
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final result = await UserApiService().getNotes();
    if (result['success'] == true) {
      if (mounted) {
        setState(() {
          _notes.clear();
          _notes.addAll(List<Map<String, dynamic>>.from(result['notes']));
          _isLoading = false;
        });
        
        // Scroll to bottom after frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addTextNote() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final result = await UserApiService().addNote(type: 'text', content: text);
    if (result['success'] == true) {
      _commentController.clear();
      _loadNotes();
    }
  }

  Future<void> _addImageNote() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    final result = await UserApiService().addNote(type: 'image', mediaBase64: base64Image);
    if (result['success'] == true) {
      _loadNotes();
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _recordingPath = path;
        });
        if (path != null) {
          _addVoiceNote(path);
        }
      } else {
        if (!kIsWeb) {
          final hasPermission = await Permission.microphone.request().isGranted;
          if (!hasPermission) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Microphone permission denied'))
              );
            }
            return;
          }
        }

        String? path;
        if (!kIsWeb) {
          final directory = await getApplicationDocumentsDirectory();
          path = '${directory.path}/note_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }
        
        const config = RecordConfig();
        await _audioRecorder.start(config, path: path ?? '');
        
        setState(() {
          _isRecording = true;
          _recordingPath = path;
        });
        
        // Auto-stop after 30 seconds
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted && _isRecording) {
            _toggleRecording();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording error: $e'))
        );
        setState(() => _isRecording = false);
      }
    }
  }

  Future<void> _addVoiceNote(String path) async {
    try {
      Uint8List bytes;
      if (kIsWeb) {
        final response = await http.get(Uri.parse(path));
        bytes = response.bodyBytes;
      } else {
        bytes = await XFile(path).readAsBytes();
      }
      
      final base64Audio = base64Encode(bytes);

      final result = await UserApiService().addNote(
        type: 'audio', 
        content: 'Voice Note', 
        mediaBase64: base64Audio
      );
      
      if (result['success'] == true) {
        _loadNotes();
      }
      
      if (!kIsWeb) {
        // Cleanup local file
        await io.File(path).delete();
      }
    } catch (_) {}
  }

  Future<void> _playVoiceNote(String noteId, String base64Data) async {
    if (_playingId == noteId) {
      await _audioPlayer.stop();
      setState(() => _playingId = null);
      return;
    }

    try {
      final bytes = base64Decode(base64Data);
      await _audioPlayer.play(BytesSource(bytes));
      setState(() => _playingId = noteId);
      
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) setState(() => _playingId = null);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playback error: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: SizedBox(
        width: 600, // Increased width
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(20),
                          itemCount: _notes.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) => _buildNoteItem(_notes[index]),
                        ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildInputRow(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteItem(Map<String, dynamic> note) {
    final id = note['id'].toString();
    final type = note['type'];
    final content = note['content'] ?? '';
    final mediaBase64 = note['media_base64'];
    final createdAtStr = note['created_at'];
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(createdAtStr);
    } catch (_) {
      createdAt = DateTime.now();
    }
    final timeStr = DateFormat('MMM d, HH:mm').format(createdAt);
    final isPlaying = _playingId == id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Me',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF252525),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (type == 'text' || (content.isNotEmpty && type != 'audio'))
                    Text(
                      content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF383838),
                      ),
                    ),
                  if (type == 'image' && mediaBase64 != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(mediaBase64),
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  if (type == 'audio' && mediaBase64 != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildAudioPlayerItem(id, content, mediaBase64, isPlaying),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: Text(
            timeStr,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9F9F9F),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioPlayerItem(String id, String label, String base64Data, bool isPlaying) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _playVoiceNote(id, base64Data),
            child: Icon(isPlaying ? Icons.stop : Icons.play_arrow, size: 20, color: const Color(0xFF3D4CD6)),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF707070), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.sticky_note_2_outlined, size: 20, color: Color(0xFF252525)),
              SizedBox(width: 8),
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF252525),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF707070)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return const CircleAvatar(
      radius: 16,
      backgroundColor: Color(0xFFEEF0FF),
      child: Text(
        'ME',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3D4CD6),
        ),
      ),
    );
  }

  Widget _buildInputRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 4, // Increase width of text box
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your note',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9F9F9F),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _commentController,
                maxLines: 6, // Increased from 4
                minLines: 3, // Increased from 1
                style: const TextStyle(fontSize: 14, color: Color(0xFF252525)),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF3D4CD6)),
                  ),
                  hintText: 'Type something...',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _addImageNote,
                    child: const _IconCircle(icon: Icons.image_outlined),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: _IconCircle(
                      icon: _isRecording ? Icons.stop : Icons.mic_none,
                      color: _isRecording ? Colors.red : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12), // Bring comment button below
              SizedBox(
                height: 36,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addTextNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D4CD6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Comment',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  final Color? color;

  const _IconCircle({required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        size: 18,
        color: color ?? const Color(0xFF707070),
      ),
    );
  }
}
