import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../main.dart';
import '../student_portal/student_dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _captchaInputController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  String _currentCaptcha = '';

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _captchaInputController.dispose();
    super.dispose();
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Verify CAPTCHA
    if (_captchaInputController.text.trim().toUpperCase() != _currentCaptcha) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid CAPTCHA code. Please check the security letters.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      _generateCaptcha();
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _identifierController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      if (auth.isAdmin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationWrapper()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
        );
      }
    } else {
      final err = auth.errorMessage ?? 'Login failed. Please check credentials.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppTheme.errorRed,
          action: err.contains('not been verified')
              ? SnackBarAction(
                  label: 'Verify',
                  textColor: Colors.white,
                  onPressed: _showVerificationDialog,
                )
              : null,
        ),
      );
      _generateCaptcha();
    }
  }

  void _showVerificationDialog() {
    final tokenController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.mark_email_read_rounded, color: AppTheme.indigoAccent),
              SizedBox(width: 10),
              Text('Verify Account', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the verification token sent to your email (or displayed in the server terminal logs during development):',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(
                  labelText: 'Verification Token',
                  hintText: 'e.g. 77M8fnV2...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navyPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final token = tokenController.text.trim();
                if (token.isEmpty) return;
                Navigator.of(ctx).pop();

                final auth = Provider.of<AuthProvider>(context, listen: false);
                final ok = await auth.verifyEmail(token);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Account verified! Logging in...' : (auth.errorMessage ?? 'Verification failed')),
                      backgroundColor: ok ? AppTheme.navyPrimary : AppTheme.errorRed,
                    ),
                  );
                  if (ok) {
                    if (auth.isAdmin) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MainNavigationWrapper()),
                      );
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
                      );
                    }
                  }
                }
              },
              child: const Text('Confirm Verification'),
            ),
          ],
        );
      },
    );
  }

  void _quickFillDemo(String identifier, String password) {
    setState(() {
      _identifierController.text = identifier;
      _passwordController.text = password;
      _captchaInputController.text = _currentCaptcha;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          if (isWide) {
            // Full-Screen Two-Panel Desktop Layout (Fills 100% Viewport)
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Hero Panel: 42% width, edge-to-edge dark navy
                  Expanded(
                    flex: 42,
                    child: Container(
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0A1128), Color(0xFF14213D), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 440),
                                child: _buildLeftHeroPanelContent(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Right Form Panel: 58% width, edge-to-edge white
                  Expanded(
                    flex: 58,
                    child: Container(
                      height: double.infinity,
                      color: Colors.white,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight > 72 ? constraints.maxHeight - 72 : 500,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 460),
                              child: _buildLoginForm(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Responsive Single-Column Mobile/Tablet Layout
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildMobileHeroHeader(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: _buildLoginForm(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildLeftHeroPanelContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.school_rounded, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 24),
        const Text(
          'CampusTrack',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'STUDENT & ACADEMIC PORTAL',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Access attendance, performance metrics, semester results, and fee notices in one secure academic platform.',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFFCBD5E1),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        _buildFeatureBullet(Icons.check_circle_rounded, 'Real-time attendance & 75% alerts'),
        const SizedBox(height: 14),
        _buildFeatureBullet(Icons.check_circle_rounded, 'GPA & SGPA academic tracking'),
        const SizedBox(height: 14),
        _buildFeatureBullet(Icons.check_circle_rounded, 'Role-based Faculty & Student access'),
        const SizedBox(height: 44),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: const Row(
            children: [
              Icon(Icons.security_rounded, color: Colors.white70, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Protected with JWT & SHA-256 password hashing.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_rounded, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            'CampusTrack Portal',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Student & Faculty Academic System',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    final auth = Provider.of<AuthProvider>(context);

    return Form(
      key: _formKey,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sign in with your Email or Student Roll Number',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),

            // Demo Helper Chips for Examiners / Reviewers
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('QUICK DEMO PRESETS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.admin_panel_settings, size: 16, color: Color(0xFF0284C7)),
                        label: const Text('Admin Demo', style: TextStyle(fontSize: 12)),
                        onPressed: () => _quickFillDemo('admin@campustrack.edu', 'Admin@1234'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.person_rounded, size: 16, color: Color(0xFF10B981)),
                        label: const Text('Student Demo (STU1001)', style: TextStyle(fontSize: 12)),
                        onPressed: () => _quickFillDemo('STU1001', 'Student@1234'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Identifier Field
            TextFormField(
              controller: _identifierController,
              decoration: const InputDecoration(
                labelText: 'Student Roll No / Email *',
                hintText: 'STU1001 or name@campus.edu',
                prefixIcon: Icon(Icons.account_circle_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter your Student ID or Email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password *',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Interactive CAPTCHA challenge box (as shown in reference screenshot)
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.navyPrimary),
                    tooltip: 'Generate new CAPTCHA',
                    onPressed: _generateCaptcha,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _captchaInputController,
                      decoration: const InputDecoration(
                        labelText: 'Enter CAPTCHA *',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Remember Me & Forgot Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (val) => setState(() => _rememberMe = val ?? true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Remember me', style: TextStyle(fontSize: 13)),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  child: const Text('Forgot Password?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sign In Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navyPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: auth.isLoading ? null : _handleLogin,
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),

            // Register Footer
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Register here',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.indigoAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}
