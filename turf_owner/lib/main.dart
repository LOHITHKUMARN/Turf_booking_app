import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/turf_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/payout_provider.dart';
import 'providers/tournament_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/home_screen.dart';
import 'features/turfs/screens/add_turf_screen.dart';
import 'features/staff/screens/manage_staff_screen.dart';
import 'features/bookings/screens/booking_management_screen.dart';
import 'features/analytics/screens/dashboard_screen.dart';
import 'features/turfs/screens/manage_venues_screen.dart';
import 'features/staff/screens/staff_list_screen.dart';
import 'features/bookings/screens/manual_booking_screen.dart';
import 'features/slots/screens/block_slot_screen.dart';
import 'features/announcements/screens/announcement_list_screen.dart';
import 'features/announcements/screens/create_announcement_screen.dart';
import 'features/payouts/screens/payout_screen.dart';
import 'features/tournaments/screens/tournament_list_screen.dart';
import 'features/tournaments/screens/create_tournament_screen.dart';
import 'features/staff/screens/staff_reports_screen.dart';
import 'features/staff/screens/staff_attendance_screen.dart';
import 'core/theme/app_theme.dart';

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
        ChangeNotifierProvider(create: (_) => TurfProvider()),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
        ChangeNotifierProvider(create: (_) => PayoutProvider()),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turf Owner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => OwnerLoginScreen(),
        '/dashboard-home': (context) => HomeScreen(),
        '/add-turf': (context) => AddTurfScreen(),
        '/manage-staff': (context) => ManageStaffScreen(),
        '/staff-list': (context) => StaffListScreen(),
        '/bookings': (context) => BookingManagementScreen(),
        '/analytics': (context) => DashboardScreen(),
        '/manage-venues': (context) => ManageVenuesScreen(),
        '/manual-booking': (context) => const ManualBookingScreen(),
        '/block-slots': (context) => const BlockSlotScreen(),
        '/announcements': (context) => const AnnouncementListScreen(),
        '/create-announcement': (context) => const CreateAnnouncementScreen(),
        '/payouts': (context) => PayoutScreen(),
        '/tournaments': (context) => const TournamentListScreen(),
        '/create-tournament': (context) => const CreateTournamentScreen(),
        '/staff-reports': (context) => const StaffReportsScreen(),
        '/staff-attendance': (context) => const StaffAttendanceScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
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
              child: CircularProgressIndicator(color: Color(0xFF00A86B)),
            ),
          );
        }
        return Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return auth.isAuthenticated ? HomeScreen() : OwnerLoginScreen();
          },
        );
      },
    );
  }
}
