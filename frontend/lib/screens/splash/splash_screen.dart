import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/student_provider.dart';
import '../../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const SplashScreen({super.key, required this.onContinue});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isChecking = true;
  bool _isConnected = false;
  String _statusMessage = 'Connecting to CampusTrack backend...';

  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
  }

  Future<void> _checkBackendHealth() async {
    setState(() {
      _isChecking = true;
      _statusMessage = 'Verifying MongoDB & Flask connectivity...';
    });

    try {
      final res = await ApiService.get(ApiConfig.health);
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isConnected = res['healthy'] == true;
          _statusMessage = _isConnected
              ? 'Connected to ${res['database_details']?['database'] ?? 'MongoDB'}'
              : 'Backend reported unhealthy status.';
        });

        // Preload dashboard & students data in background
        if (_isConnected) {
          Provider.of<DashboardProvider>(context, listen: false).loadDashboard();
          Provider.of<StudentProvider>(context, listen: false).loadStudents();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isConnected = false;
          _statusMessage = 'Could not connect to ${ApiConfig.baseUrl}.\nTap "Configure Host" or "Retry".';
        });
      }
    }
  }

  void _showConfigureHostDialog() {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configure Backend Host'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select or enter server URL:\n• Android Emulator: http://10.0.2.2:5000\n• Windows/Web: http://127.0.0.1:5000',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Server Host',
                prefixIcon: Icon(Icons.link_rounded),
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
            onPressed: () {
              ApiConfig.setBaseUrl(controller.text.trim());
              Navigator.of(ctx).pop();
              _checkBackendHealth();
            },
            child: const Text('Save & Reconnect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1128), // Deep navy
              Color(0xFF1E293B), // Slate navy
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    // App Logo Icon
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppTheme.indigoAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.indigoAccent.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 58,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Title
                    const Text(
                      'CampusTrack',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      'Student Attendance & Academic Performance\nManagement System',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Tech stack pills
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildPill('Flutter + Dart', Icons.flutter_dash),
                        _buildPill('Python Flask', Icons.api_rounded),
                        _buildPill('MongoDB NoSQL', Icons.storage_rounded),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // Connection status card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isConnected
                              ? AppTheme.successGreen.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (_isChecking)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          else
                            Icon(
                              _isConnected ? Icons.check_circle_rounded : Icons.cloud_off_rounded,
                              color: _isConnected ? AppTheme.successGreen : AppTheme.warningOrange,
                              size: 20,
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _statusMessage,
                              style: TextStyle(
                                fontSize: 12,
                                color: _isConnected ? Colors.white : const Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_ethernet, size: 18, color: Colors.white70),
                            tooltip: 'Configure Backend URL',
                            onPressed: _showConfigureHostDialog,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: widget.onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.indigoAccent,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Enter Portal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.indigoLight),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
