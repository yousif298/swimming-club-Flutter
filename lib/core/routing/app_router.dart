import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/screens/login/login_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/customers/customers_screen.dart';
import '../../presentation/screens/pools/pools_screen.dart';
import '../../presentation/screens/mirror/mirror_screen.dart';
import '../../presentation/screens/bookings/bookings_screen.dart';
import '../../presentation/screens/payments/payments_screen.dart';
import '../../presentation/screens/reports/reports_screen.dart';
import '../../presentation/screens/booking_types/booking_types_screen.dart';
import '../../presentation/screens/users/users_screen.dart';
import '../../presentation/screens/pricing/pricing_screen.dart';
import '../../presentation/screens/members/members_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final isLogin = state.matchedLocation == '/login';
    if (token == null && !isLogin) return '/login';
    if (token != null && isLogin) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/customers',
          builder: (context, state) => const CustomersScreen(),
        ),
        GoRoute(
          path: '/pools',
          builder: (context, state) => const PoolsScreen(),
        ),
        GoRoute(
          path: '/mirror',
          builder: (context, state) => const MirrorScreen(),
        ),
        GoRoute(
          path: '/bookings',
          builder: (context, state) => const BookingsScreen(),
        ),
        GoRoute(
          path: '/payments',
          builder: (context, state) => const PaymentsScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/members',
          builder: (context, state) => const MembersScreen(),
        ),
        GoRoute(
          path: '/pricing',
          builder: (context, state) => const PricingScreen(),
        ),
        GoRoute(
          path: '/booking-types',
          builder: (context, state) => const BookingTypesScreen(),
        ),
        GoRoute(
          path: '/users',
          builder: (context, state) => const UsersScreen(),
        ),
      ],
    ),
  ],
);

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swimming Club'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex(context),
            onDestinationSelected: (i) => _onNavigate(context, i),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Customers'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.pool),
                label: Text('Pools'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_view_week),
                label: Text('Mirror'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.book_online),
                label: Text('Bookings'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.payments),
                label: Text('Payments'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assessment),
                label: Text('Reports'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                label: Text('Members'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.attach_money),
                label: Text('Pricing'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category),
                label: Text('Booking Types'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.manage_accounts),
                label: Text('Users'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/customers')) return 1;
    if (location.startsWith('/pools')) return 2;
    if (location.startsWith('/mirror')) return 3;
    if (location.startsWith('/bookings')) return 4;
    if (location.startsWith('/payments')) return 5;
    if (location.startsWith('/reports')) return 6;
    if (location.startsWith('/members')) return 7;
    if (location.startsWith('/pricing')) return 8;
    if (location.startsWith('/booking-types')) return 9;
    if (location.startsWith('/users')) return 10;
    return 0;
  }

  void _onNavigate(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/dashboard');
      case 1: context.go('/customers');
      case 2: context.go('/pools');
      case 3: context.go('/mirror');
      case 4: context.go('/bookings');
      case 5: context.go('/payments');
      case 6: context.go('/reports');
      case 7: context.go('/members');
      case 8: context.go('/pricing');
      case 9: context.go('/booking-types');
      case 10: context.go('/users');
    }
  }
}
