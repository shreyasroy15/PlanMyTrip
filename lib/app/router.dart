import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

// Feature Imports
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/create_account_screen.dart';
import '../features/auth/phone_auth_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/home/home_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/ai_planner/ai_planner_screen.dart';
import '../features/trips/trips_screen.dart';
import '../features/trips/trip_detail_screen.dart';
import '../features/itinerary/itinerary_screen.dart';
import '../features/maps/maps_screen.dart';
import '../features/saved/saved_places_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/settings/settings_screen.dart';

// Admin Imports
import '../admin/dashboard/admin_dashboard_screen.dart';
import '../admin/users/admin_users_screen.dart';
import '../admin/trips/admin_trips_screen.dart';
import '../admin/destinations/admin_destinations_screen.dart';
import '../admin/analytics/admin_analytics_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (BuildContext context, GoRouterState state) {
      final path = state.uri.path;
      final isPublicAuthRoute = path == '/splash' ||
          path == '/onboarding' ||
          path == '/login' ||
          path == '/register' ||
          path == '/phone-auth' ||
          path == '/forgot-password' ||
          path == '/reset-password';

      final isAuthenticated = authState.isAuthenticated;
      final isAdmin = authState.userModel?.role == 'admin';

      // Unauthenticated users attempting to access protected routes redirect to login
      if (!isAuthenticated && !isPublicAuthRoute) {
        return '/login';
      }

      // Non-admin users attempting to access admin routes redirect to home
      if (path.startsWith('/admin') && !isAdmin) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: '/phone-auth',
        builder: (context, state) => const PhoneAuthScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      
      // Main Shell Navigation with Bottom Navigation Bar
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/explore',
            builder: (context, state) => const ExploreScreen(),
          ),
          GoRoute(
            path: '/ai-planner',
            builder: (context, state) => const AiPlannerScreen(),
          ),
          GoRoute(
            path: '/trips',
            builder: (context, state) => const TripsScreen(),
          ),
          GoRoute(
            path: '/saved',
            builder: (context, state) => const SavedPlacesScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Feature Sub-routes
      GoRoute(
        path: '/trip-detail/:id',
        builder: (context, state) {
          final tripId = state.pathParameters['id'] ?? '';
          return TripDetailScreen(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/itinerary/:id',
        builder: (context, state) {
          final tripId = state.pathParameters['id'] ?? '';
          return ItineraryScreen(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/maps',
        builder: (context, state) => const MapsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Admin Section Routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/trips',
        builder: (context, state) => const AdminTripsScreen(),
      ),
      GoRoute(
        path: '/admin/destinations',
        builder: (context, state) => const AdminDestinationsScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
    ],
  );
});

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/ai-planner')) return 2;
    if (location.startsWith('/trips')) return 3;
    if (location.startsWith('/saved')) return 4;
    if (location.startsWith('/profile')) return 5;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/home');
        break;
      case 1:
        GoRouter.of(context).go('/explore');
        break;
      case 2:
        GoRouter.of(context).go('/ai-planner');
        break;
      case 3:
        GoRouter.of(context).go('/trips');
        break;
      case 4:
        GoRouter.of(context).go('/saved');
        break;
      case 5:
        GoRouter.of(context).go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: 'AI Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flight_takeoff_outlined),
            activeIcon: Icon(Icons.flight_takeoff),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
