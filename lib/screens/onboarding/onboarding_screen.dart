import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:klarto/screens/main_app_shell.dart';
import 'package:klarto/widgets/custom_text_field.dart';
import 'package:klarto/widgets/auth_background.dart';
import 'package:klarto/apis/user_api_service.dart';

class OnboardingScreen extends StatefulWidget {
  final bool showInviteStep;
  const OnboardingScreen({super.key, this.showInviteStep = true});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _inviteController = TextEditingController();
  final UserApiService _userApiService = UserApiService();
  final ImagePicker _picker = ImagePicker();
  Map<String, bool> _isMemberMap = {};
  Timer? _debounceTimer;

  int _currentStep = 0;
  late final int _totalSteps;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;
  Map<String, Map<String, dynamic>> _inviteResults = {};
  bool _readyToFinish = false;
  List<dynamic> _plans = [];
  Map<String, dynamic>? _selectedPlan;
  Map<String, dynamic>? _currentSubscription;
  bool _isTrialSelected = false;

  void _nextPage() {
    if (_currentStep < (_totalSteps - 1)) {
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
    setState(() => _isLoading = true);
    try {
      final userApi = UserApiService();
      await userApi.completeOnboarding();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainAppShell()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to complete onboarding. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Widget> _buildEmailTagsFromInput() {
    final text = _inviteController.text;
    final emails = text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return emails.take(5).map((e) => _buildEmailTag(e)).toList();
  }

  void _scheduleMemberChecks() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final text = _inviteController.text;
      final emails = text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (emails.isEmpty) return;
      final checks = await Future.wait(emails.map((e) => _userApiService.isMemberOfInviterTeam(e)));
      final map = <String,bool>{};
      for (var i=0;i<emails.length;i++) map[emails[i]] = checks[i];
      if (mounted) setState(() { _isMemberMap = map; });
    });
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$', caseSensitive: false);
    return regex.hasMatch(email);
  }

  Future<void> _handleStep3Submit() async {
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a plan.')));
      return;
    }
    _nextPage();
  }

  Future<void> _handleStep4Submit() async {
    setState(() => _isLoading = true);
    try {
      // 1. Create Payment Method via Stripe
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      // 2. Send Payment Method ID to our backend
      final res = await _userApiService.subscribe(
        planId: _selectedPlan!['id'],
        paymentMethodId: paymentMethod.id,
        isTrial: _isTrialSelected,
      );

      if (res['success']) {
        _nextPage();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error processing payment. Please check your card details.')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleStep5Submit() async {
    final raw = _inviteController.text;
    final emails = raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (emails.isEmpty) {
      // No invites, just complete onboarding
      await _completeOnboarding();
      return;
    }
    
    final limit = _selectedPlan?['member_limit'] ?? 5;
    if (emails.length > limit) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You can invite up to $limit members with your plan.')));
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
        // Store per-email results so we can show messages like "already a member"
        final List<dynamic> results = result['results'] ?? [];
        final mapped = {
          for (final r in results)
            (r['email'] as String): Map<String, dynamic>.from(r as Map<String, dynamic>)
        };
        if (mounted) {
          setState(() {
            _inviteResults = mapped;
            _readyToFinish = true;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitations processed.')));
        // Do not auto-complete; show results to the user and let them tap the button again to finish.
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
          // High-fidelity background ornaments
          const Positioned.fill(
            child: BackgroundOrnaments(),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top-right Skip button for all onboarding pages
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text('Skip', style: TextStyle(color: Color(0xFF707070))),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Progress Bar Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      // Progress Steps
                      Expanded(
                        child: Row(
                          children: List.generate(_totalSteps, (index) {
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
                    children: widget.showInviteStep
                        ? [_buildStep1(), _buildStep2(), _buildStep3(), _buildStep4(), _buildStep5()]
                        : [_buildStep1(), _buildStep2()],
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
    _totalSteps = widget.showInviteStep ? 5 : 2;
    _inviteController.addListener(() {
      if (mounted) setState(() { _readyToFinish = false; });
      _scheduleMemberChecks();
    });
    if (widget.showInviteStep) {
      _fetchPlans();
    }
  }

  Future<void> _fetchPlans() async {
    final plans = await _userApiService.getSubscriptionPlans();
    if (mounted) {
      setState(() {
        _plans = plans;
        // Default to first plan if available
        if (_plans.isNotEmpty) {
          _selectedPlan = _plans[0];
        }
      });
    }
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
            'Choose Your Plan',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF252525),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Select a plan that fits your team size.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF707070),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _plans.isEmpty 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _plans.length,
                itemBuilder: (context, index) {
                  final plan = _plans[index];
                  final isSelected = _selectedPlan?['id'] == plan['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPlan = plan),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF0F2FF) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF3D4CD6) : const Color(0xFFE0E0E0),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan['name'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${plan['member_limit']} Members Limit',
                                  style: const TextStyle(color: Color(0xFF707070)),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${plan['price']}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3D4CD6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: _handleStep3Submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D4CD6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
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

  Widget _buildStep4() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            'Payment Details',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF252525),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
           const Text(
            'Enter your card details to subscribe.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF707070),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 50,
            child: CardField(
              key: const ValueKey('stripe_card_field'),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                labelText: 'Card Details',
              ),
              onCardChanged: (card) {
                // Can use this to track card state if needed
              },
            ),
          ),
          const SizedBox(height: 24),
          // Trial Option
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEAECF0)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _isTrialSelected,
                  onChanged: (val) => setState(() => _isTrialSelected = val ?? false),
                  activeColor: const Color(0xFF3D4CD6),
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start 7-Day Free Trial',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        'You won\'t be charged until after 7 days.',
                        style: TextStyle(color: Color(0xFF707070), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleStep4Submit,
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
                  : Text(
                      _isTrialSelected ? 'Start Trial' : 'Pay & Continue',
                      style: const TextStyle(
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

  Widget _buildStep5() {
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
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Color(0xFF707070)),
              children: [
                const TextSpan(text: 'You are subscribed to '),
                TextSpan(
                  text: '${_selectedPlan?['name'] ?? 'Pro'} Plan with ${_selectedPlan?['member_limit'] ?? 5} Members. ',
                  style: const TextStyle(color: Color(0xFF252525), fontWeight: FontWeight.normal),
                ),
                const TextSpan(
                  text: 'Please Invite them to your team.',
                  style: TextStyle(color: Color(0xFF252525)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          CustomTextField(
            label: 'Enter Member Emails (max ${_selectedPlan?['member_limit'] ?? 5}, comma separated)',
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
          const SizedBox(height: 12),
          if (_inviteResults.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text('Invitation results:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ..._inviteResults.entries.map((e) {
                  final email = e.key;
                  final info = e.value;
                  final success = info['success'] == true;
                  final message = info['message'] ?? (success ? 'Invitation sent.' : 'Failed');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(success ? Icons.check_circle_outline : Icons.error_outline,
                          size: 18, color: success ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
                        const SizedBox(width: 8),
                        Expanded(child: Text('$email — $message', style: TextStyle(color: success ? const Color(0xFF2E7D32) : const Color(0xFFC62828)))),
                      ],
                    ),
                  );
                }).toList(),
              ],
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
              onPressed: _isLoading ? null : (_readyToFinish ? _completeOnboarding : _handleStep5Submit),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D4CD6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                _readyToFinish ? 'Finish' : 'Confirm & Invite',
                style: const TextStyle(
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
    final alreadyMember = _isMemberMap[email] == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: alreadyMember ? const Color(0xFFE3F2FD) : (valid ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE)),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: alreadyMember ? const Color(0xFF2196F3) : (valid ? const Color(0xFF66BB6A) : const Color(0xFFEF5350))),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            alreadyMember ? Icons.person : (valid ? Icons.check_circle_outline : Icons.error_outline),
            size: 16,
            color: alreadyMember ? const Color(0xFF1976D2) : (valid ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
          ),
          const SizedBox(width: 8),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: alreadyMember ? const Color(0xFF1976D2) : (valid ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
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
              color: alreadyMember ? const Color(0xFF1976D2) : (valid ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
            ),
          ),
        ],
      ),
    );
  }
}
