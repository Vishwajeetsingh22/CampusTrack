import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _captchaInputController = TextEditingController();

  String _role = 'student';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _currentCaptcha = '';
  double _passwordStrength = 0.0;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
    _passwordController.addListener(_calculateStrength);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _passwordController.removeListener(_calculateStrength);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _captchaInputController.dispose();
    super.dispose();
  }

  void _calculateStrength() {
    final pass = _passwordController.text;
    double score = 0;
    if (pass.length >= 8) score += 0.3;
    if (pass.length >= 12) score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(pass)) score += 0.2;
    if (RegExp(r'[A-Z]').hasMatch(pass)) score += 0.15;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pass)) score += 0.15;
    setState(() => _passwordStrength = score.clamp(0.0, 1.0));
  }

  void _generateCaptcha() {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final rnd = Random();
    final result = StringBuffer();
    for (int i = 0; i < 5; i++) {
      result.write(chars[rnd.nextInt(chars.length)]);
    }
    setState(() {
      _currentCaptcha = result.toString();
      _captchaInputController.clear();
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_captchaInputController.text.trim().toUpperCase() != _currentCaptcha) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid CAPTCHA code. Please check security letters.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      _generateCaptcha();
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final payload = {
      'full_name': _nameController.text.trim(),
      'email': _emailController.text.trim().toLowerCase(),
      'password': _passwordController.text,
      'role': _role,
      if (_role == 'student') 'student_id': _studentIdController.text.trim().toUpperCase(),
    };

    final result = await auth.register(payload);
    if (!mounted) return;

    if (result['success'] == true) {
      final token = result['data']?['verification_token'] ?? '';
      _showRegistrationSuccessDialog(token);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Registration failed.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      _generateCaptcha();
    }
  }

  void _showRegistrationSuccessDialog(String devToken) {
    final tokenInput = TextEditingController(text: devToken);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.mark_email_read_rounded, color: AppTheme.successGreen, size: 28),
              SizedBox(width: 10),
              Text('Account Created!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'A real verification email has been dispatched to your email address.',
                  style: TextStyle(fontSize: 14, color: AppTheme.navyPrimary),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LOCAL DEV / TEST TOKEN:',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        devToken.isNotEmpty ? devToken : 'Check server terminal logs',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.indigoAccent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Enter verification token below to activate immediately:',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tokenInput,
                  decoration: const InputDecoration(
                    labelText: 'Token',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // Back to login
              },
              child: const Text('Back to Login'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navyPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final token = tokenInput.text.trim();
                if (token.isEmpty) return;
                Navigator.of(ctx).pop();

                final auth = Provider.of<AuthProvider>(context, listen: false);
                final ok = await auth.verifyEmail(token);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Account verified successfully! Please log in.' : 'Verification failed'),
                      backgroundColor: ok ? AppTheme.navyPrimary : AppTheme.errorRed,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Verify & Continue'),
            ),
          ],
        );
      },
    );
  }

  Color _getStrengthColor() {
    if (_passwordStrength < 0.4) return AppTheme.errorRed;
    if (_passwordStrength < 0.7) return AppTheme.warningAmber;
    return AppTheme.successGreen;
  }

  String _getStrengthText() {
    if (_passwordStrength < 0.4) return 'Weak';
    if (_passwordStrength < 0.7) return 'Moderate';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Register for CampusTrack'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 540),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Your Portal Account',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Select your institutional role and enter your details',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  // Role Selector
                  const Text('ACCOUNT ROLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _role = 'student'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _role == 'student' ? AppTheme.navyPrimary : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _role == 'student' ? AppTheme.navyPrimary : const Color(0xFFCBD5E1),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  size: 18,
                                  color: _role == 'student' ? Colors.white : AppTheme.navyPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Student',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _role == 'student' ? Colors.white : AppTheme.navyPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _role = 'admin'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _role == 'admin' ? AppTheme.navyPrimary : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _role == 'admin' ? AppTheme.navyPrimary : const Color(0xFFCBD5E1),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.admin_panel_settings_rounded,
                                  size: 18,
                                  color: _role == 'admin' ? Colors.white : AppTheme.navyPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Faculty / Admin',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _role == 'admin' ? Colors.white : AppTheme.navyPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // If Student: require Roll Number
                  if (_role == 'student') ...[
                    TextFormField(
                      controller: _studentIdController,
                      decoration: const InputDecoration(
                        labelText: 'Student Roll Number / ID *',
                        hintText: 'e.g. STU1001 or STU1002',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (_role == 'student' && (val == null || val.trim().isEmpty)) {
                          return 'Student ID is required for student accounts';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      hintText: 'e.g. John Doe',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Full name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Institutional Email *',
                      hintText: 'name@campustrack.edu',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || !val.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),

                  // Password Strength Indicator
                  if (_passwordController.text.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _passwordStrength,
                              backgroundColor: const Color(0xFFE2E8F0),
                              color: _getStrengthColor(),
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _getStrengthText(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getStrengthColor(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password *',
                      prefixIcon: const Icon(Icons.lock_clock_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (val) {
                      if (val != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // CAPTCHA
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1B2A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _currentCaptcha,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: AppTheme.navyPrimary),
                          onPressed: _generateCaptcha,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _captchaInputController,
                            decoration: const InputDecoration(
                              labelText: 'Security Code *',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Required';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navyPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: auth.isLoading ? null : _handleRegister,
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
