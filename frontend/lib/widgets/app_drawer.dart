import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/student_portal/student_dashboard_screen.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final userName = user?.fullName ?? 'Administrator';
    final userRole = user?.role.toUpperCase() ?? 'ADMIN';

    return Drawer(
      backgroundColor: AppTheme.surfaceWhite,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 24),
            decoration: const BoxDecoration(
              color: AppTheme.navyPrimary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.indigoAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        userRole,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'CampusTrack Academic Portal',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  index: 0,
                  context: context,
                ),
                _buildDrawerItem(
                  icon: Icons.people_alt_rounded,
                  label: 'Students',
                  index: 1,
                  context: context,
                ),
                _buildDrawerItem(
                  icon: Icons.fact_check_rounded,
                  label: 'Attendance',
                  index: 2,
                  context: context,
                ),
                _buildDrawerItem(
                  icon: Icons.assignment_turned_in_rounded,
                  label: 'Marks & Exams',
                  index: 3,
                  context: context,
                ),
                _buildDrawerItem(
                  icon: Icons.insights_rounded,
                  label: 'Reports & Analytics',
                  index: 4,
                  context: context,
                ),
                const Divider(),
                // Switch to Student Portal preview
                ListTile(
                  leading: const Icon(Icons.school_outlined, color: AppTheme.indigoAccent, size: 22),
                  title: const Text('Open Student Portal View', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.indigoAccent)),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // Backend Server URL Setting
          ListTile(
            leading: const Icon(Icons.settings_ethernet_rounded, color: AppTheme.textSecondary, size: 22),
            title: const Text('Backend API URL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(
              ApiConfig.baseUrl,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _showServerConfigDialog(context),
          ),

          // Sign Out Option
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tileColor: AppTheme.errorBg,
              leading: const Icon(Icons.logout_rounded, color: AppTheme.errorRed, size: 20),
              title: const Text('Sign Out', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold, fontSize: 13)),
              onTap: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required int index,
    required BuildContext context,
  }) {
    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.indigoSoftBg : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.indigoAccent : AppTheme.textSecondary,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.indigoAccent : AppTheme.textPrimary,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          onDestinationSelected(index);
        },
      ),
    );
  }

  void _showServerConfigDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configure Backend Host', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Flask server URL:\n• Android Emulator: http://10.0.2.2:5000\n• Windows/Web: http://127.0.0.1:5000',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Server URL',
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('API URL updated to: ${ApiConfig.baseUrl}')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
