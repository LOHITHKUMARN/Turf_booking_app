import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/admin_payout_provider.dart';
import 'providers/tournament_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/turfs/screens/turf_management_screen.dart';
import 'features/users/screens/user_management_screen.dart';
import 'features/users/screens/add_owner_screen.dart';
import 'features/payouts/screens/payout_management_screen.dart';
import 'features/tournaments/screens/pending_tournaments_screen.dart';
import 'features/tournaments/screens/tournament_monitor_screen.dart';
import 'core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    await NotificationService().init();
  } catch (e) {
    debugPrint('Firebase/Notification Service initialization failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminPayoutProvider()),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
      ],
      child: TurfAdminApp(),
    ),
  );
}

class TurfAdminApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turf Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AuthWrapper(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/manage-turfs': (context) => TurfManagementScreen(),
        '/manage-users': (context) => UserManagementScreen(),
        '/add-owner': (context) => AddOwnerScreen(),
        '/payout-management': (context) => const PayoutManagementScreen(),
        '/pending-tournaments': (context) => const PendingTournamentsScreen(),
        '/tournament-monitor': (context) => const TournamentMonitorScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<void> _authFuture;

  @override
  void initState() {
    super.initState();
    _authFuture = Provider.of<AuthProvider>(context, listen: false).tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _authFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return auth.isAuthenticated ? DashboardScreen() : LoginScreen();
          },
        );
      },
    );
  }
}
