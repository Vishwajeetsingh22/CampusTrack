import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'providers/attendance_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/marks_provider.dart';
import 'providers/report_provider.dart';
import 'providers/student_provider.dart';
import 'screens/attendance/attendance_list_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/marks/marks_list_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/student_portal/student_dashboard_screen.dart';
import 'screens/students/student_list_screen.dart';
import 'widgets/responsive_scaffold.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CampusTrackApp());
}

class CampusTrackApp extends StatelessWidget {
  const CampusTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => MarksProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp(
        title: 'CampusTrack — Academic Portal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppEntryGate(),
      ),
    );
  }
}

class AppEntryGate extends StatefulWidget {
  const AppEntryGate({super.key});

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).checkAuthSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onContinue: () {
          setState(() => _showSplash = false);
        },
      );
    }

    final auth = Provider.of<AuthProvider>(context);

    // If authenticated, route based on role
    if (auth.isAuthenticated) {
      if (auth.isStudent) {
        return const StudentDashboardScreen();
      } else {
        return const MainNavigationScreen();
      }
    }

    // If unauthenticated, show professional LoginScreen
    return const LoginScreen();
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Dashboard',
    'Student Directory',
    'Attendance Records',
    'Examination Marks',
    'Reports & Analytics',
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onNavigateTab: (index) => setState(() => _currentIndex = index)),
      const StudentListScreen(),
      const AttendanceListScreen(),
      const MarksListScreen(),
      const ReportsScreen(),
    ];

    return ResponsiveScaffold(
      title: _titles[_currentIndex],
      currentIndex: _currentIndex,
      onNavigationChanged: (index) {
        setState(() => _currentIndex = index);
      },
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
    );
  }
}

typedef MainNavigationWrapper = MainNavigationScreen;
