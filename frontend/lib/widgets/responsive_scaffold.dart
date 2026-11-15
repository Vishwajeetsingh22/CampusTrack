import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/student_portal/student_dashboard_screen.dart';
import 'app_drawer.dart';

class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onNavigationChanged;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentIndex,
    required this.onNavigationChanged,
    this.actions,
    this.floatingActionButton,
  });

  Widget _buildUserMenu(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final name = user?.fullName ?? 'Administrator';

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: PopupMenuButton<String>(
        tooltip: 'Account Menu',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onSelected: (val) async {
          if (val == 'student_portal') {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
            );
          } else if (val == 'logout') {
            await auth.logout();
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                Text(user?.email ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'student_portal',
            child: Row(
              children: [
                Icon(Icons.school_rounded, size: 18, color: AppTheme.indigoAccent),
                SizedBox(width: 8),
                Text('Open Student Portal View'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout_rounded, size: 18, color: AppTheme.errorRed),
                SizedBox(width: 8),
                Text('Sign Out', style: TextStyle(color: AppTheme.errorRed)),
              ],
            ),
          ),
        ],
        child: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'A',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = width >= 800;

    if (isDesktopOrTablet) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.school_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                'CampusTrack — $title',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            ...?actions,
            _buildUserMenu(context),
          ],
        ),
        body: Row(
          children: [
            // Side navigation rail on large displays
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onNavigationChanged,
              backgroundColor: AppTheme.surfaceWhite,
              minWidth: 72,
              extended: width >= 1100,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Icon(Icons.hub_rounded, color: AppTheme.indigoAccent),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline_rounded),
                  selectedIcon: Icon(Icons.people_alt_rounded),
                  label: Text('Students'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.fact_check_outlined),
                  selectedIcon: Icon(Icons.fact_check_rounded),
                  label: Text('Attendance'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment_turned_in_rounded),
                  label: Text('Marks'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights_rounded),
                  label: Text('Reports'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    // Mobile layout
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...?actions,
          _buildUserMenu(context),
        ],
      ),
      drawer: AppDrawer(
        selectedIndex: currentIndex,
        onDestinationSelected: onNavigationChanged,
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onNavigationChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_alt_rounded),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_turned_in_rounded),
            label: 'Marks',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Reports',
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
