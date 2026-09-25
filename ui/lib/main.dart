import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/player_list_screen.dart';
import 'screens/home/my_team_screen.dart';
import 'screens/home/match_screen.dart';
import 'screens/profile/profile_setup_screen.dart';
import 'screens/home/all_matches_screen.dart';

class MainTabs extends StatefulWidget {
  final Widget child;
  const MainTabs({super.key, required this.child});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/players')) return 1;
    if (location.startsWith('/my-team')) return 2;
    if (location.startsWith('/matches')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/players');
        break;
      case 2:
        context.go('/my-team');
        break;
      case 3:
        context.go('/matches');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF16A34A),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Cầu thủ'),
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'Đội bóng'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Kèo đấu'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}

void main() {
  runApp(const KeonhanhApp());
}

class KeonhanhApp extends StatelessWidget {
  const KeonhanhApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainTabs(child: child),
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
            GoRoute(path: '/players', builder: (context, state) => const PlayerListScreen()),
            GoRoute(path: '/my-team', builder: (context, state) => const MyTeamScreen()),
            GoRoute(path: '/matches', builder: (context, state) => const MatchScreen()),
            GoRoute(path: '/profile', builder: (context, state) => const ProfileSetupScreen()),
          ],
        ),
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
        GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
        GoRoute(path: '/allMatches', builder: (context, state) => const AllMatchesScreen()),
      ],
    );

    return MaterialApp.router(
      title: 'Keonhanh',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF16A34A)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
