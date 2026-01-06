import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:klarto/screens/main_app_shell.dart';
import 'package:klarto/widgets/custom_text_field.dart';
import 'package:klarto/apis/user_api_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _inviteController = TextEditingController();
  final UserApiService _userApiService = UserApiService();
  final ImagePicker _picker = ImagePicker();

  int _currentStep = 0;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;

  void _nextPage() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _handleStep2Submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Update Profile Name
      final nameResult = await _userApiService.updateProfile(name: name);
      if (!nameResult['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(nameResult['message'])),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // 2. Upload Avatar if selected
      if (_selectedImageBytes != null) {
        final avatarResult = await _userApiService.uploadAvatar(bytes: _selectedImageBytes, fileName: _selectedImage?.name);
        if (!avatarResult['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(avatarResult['message'])),
            );
          }
          // We continue anyway even if avatar fails, or we could stop.
          // For now let's stop.
          setState(() => _isLoading = false);
          return;
        }
      }

      _nextPage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainAppShell()),
    );
  }

  List<Widget> _buildEmailTagsFromInput() {
    final text = _inviteController.text;
    final emails = text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return emails.take(5).map((e) => _buildEmailTag(e)).toList();
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$', caseSensitive: false);
    return regex.hasMatch(email);
  }

  Future<void> _handleStep3Submit() async {
    final raw = _inviteController.text;
    final emails = raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (emails.isEmpty) {
      // No invites, just complete onboarding
      await _completeOnboarding();
      return;
    }
    if (emails.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can invite up to 5 members.')));
      return;
    }

    // Validate emails locally
    final invalid = emails.where((e) => !_isValidEmail(e)).toList();
    if (invalid.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid email(s): ${invalid.join(', ')}')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _userApiService.inviteTeam(emails);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitations sent.')));
        await _completeOnboarding();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Failed to send invites')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An error occurred sending invites.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Common Background Image for all steps (based on A)
          Positioned.fill(
            child: Image.network(
              'https://c.animaapp.com/xbC4Tecy/img/onboarding-1---welcome.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.white),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Progress Bar Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      // Progress Steps
                      Expanded(
                        child: Row(
                          children: List.generate(3, (index) {
                            return Expanded(
                              child: Container(
                                height: 4,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: index <= _currentStep
                                      ? const Color(0xFF3D4CD6)
                                      : const Color(0xFFE0E0E0),
                                  borderRadius: BorderRadius.circular(48),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index;
                      });
                    },
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1(),
                      _buildStep2(),
                      _buildStep3(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _inviteController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _inviteController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Welcome To Klarto',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF252525),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Please fill in some important info to get started with Klarto.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF707070),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D4CD6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              'Please Enter Your Name',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF252525),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Add your name and profile picture.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF707070),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Profile Picture Upload
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEAECF0),
                    style: BorderStyle.solid,
                    width: 1,
                  ),
                  image: _selectedImage != null
                      ? DecorationImage(
                                    image: MemoryImage(_selectedImageBytes!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_outlined, color: Color(0xFF707070)),
                          const SizedBox(height: 8),
                          const Text(
                            'Upload Profile Picture',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF707070),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 32),
            CustomTextField(
              label: 'Your Name',
              hintText: 'Your Name',
              controller: _nameController,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleStep2Submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D4CD6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            'Invite Your Team Members',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF252525),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(fontSize: 14, color: Color(0xFF707070)),
              children: [
                TextSpan(text: 'You are subscribed to '),
                TextSpan(
                  text: 'Pro Plan with 5 Members. ',
                  style: TextStyle(color: Color(0xFF252525), fontWeight: FontWeight.normal),
                ),
                TextSpan(
                  text: 'Please Invite them to your team.',
                  style: TextStyle(color: Color(0xFF252525)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          CustomTextField(
            label: 'Enter Member Emails (max 5, comma separated)',
            hintText: 'a@b.com, c@d.com',
            controller: _inviteController,
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildEmailTagsFromInput(),
            ),
          ),
          
          const SizedBox(height: 24),
          const Text(
            'You can manage your team members any time in settings.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF707070),
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleStep3Submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D4CD6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Finish',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmailTag(String email) {
    final valid = _isValidEmail(email);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: valid ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: valid ? const Color(0xFF66BB6A) : const Color(0xFFEF5350)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            valid ? Icons.check_circle_outline : Icons.error_outline,
            size: 16,
            color: valid ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          ),
          const SizedBox(width: 8),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: valid ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              // Remove this email from the input
              final current = _inviteController.text;
              final parts = current.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
              parts.removeWhere((p) => p == email);
              _inviteController.text = parts.join(', ');
              // Move cursor to end
              _inviteController.selection = TextSelection.fromPosition(TextPosition(offset: _inviteController.text.length));
              if (mounted) setState(() {});
            },
            child: Icon(
              Icons.close,
              size: 14,
              color: valid ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            ),
          ),
        ],
      ),
    );
  }
}
