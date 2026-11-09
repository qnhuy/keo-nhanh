import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import providers
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';

// Import screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/player_list_screen.dart';
import 'screens/home/my_team_screen.dart';
import 'screens/home/match_screen.dart';
import 'screens/profile/profile_setup_screen.dart';

import 'screens/home/create_match_screen.dart';
import 'screens/home/match_detail_screen.dart';
import 'screens/home/create_team_screen.dart';
import 'screens/home/all_matches_screen.dart';
import 'screens/home/find_team_screen.dart';
import 'screens/home/team_chat_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/ai/ai_chat_screen.dart';

// --- TAB NAVIGATOR (Tương đương MainTabs trong RN) ---
class MainTabs extends StatefulWidget {
  final Widget
  child; // Widget con hiện tại do GoRouter quyết định (HomeScreen, etc.)
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
    return 0; // Default to Home
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
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;

    // Tương đương với logic trong React Native:
    // Các tab 'Đội của tôi', 'Kèo đấu' và 'Hồ sơ' chỉ hiện nếu có `user`
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
      const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Cầu thủ'),
    ];

    if (isLoggedIn) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.security),
          label: 'Đội của tôi',
        ),
      );
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.sports_soccer),
          label: 'Kèo đấu',
        ),
      );
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Hồ sơ',
        ),
      );
    }

    // Nếu user log out khi đang ở tab số 2, 3 thì selectedIndex có thể out of bound
    int currentIndex = _calculateSelectedIndex(context);
    if (currentIndex >= items.length) {
      currentIndex = 0; // fallback an toàn
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: items,
        currentIndex: currentIndex,
        selectedItemColor: Colors.green, // #22c55e
        unselectedItemColor: Colors.grey,
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }
}

// --- APP ENTRY POINT ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Không thể nạp .env, sử dụng config mặc định: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const KeonhanhApp(),
    ),
  );
}

class KeonhanhApp extends StatelessWidget {
  const KeonhanhApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Cấu hình GoRouter tương đương với NavigationContainer & Stack.Navigator
    final GoRouter router = GoRouter(
      initialLocation: '/',
      // Redirect logic: nếu chưa login mà cố vào trang cần login thì đẩy về /login
      redirect: (BuildContext context, GoRouterState state) {
        final auth = context.read<AuthProvider>();
        final isLoggedIn = auth.isLoggedIn;

        // Danh sách các trang yêu cầu đăng nhập
        final bool isProtectedRoute =
            state.uri.path == '/my-team' || state.uri.path == '/matches' || state.uri.path == '/profile' || state.uri.path == '/admin';

        if (!isLoggedIn && isProtectedRoute) {
          return '/login';
        }
        if (state.uri.path == '/admin' && !auth.isAdmin) {
          return '/';
        }
        return null; // Không redirect, cho phép đi tiếp
      },
      routes: [
        // ShellRoute dùng để bọc các màn hình có chung BottomNavigationBar (MainTabs)
        ShellRoute(
          builder: (context, state, child) {
            return MainTabs(child: child);
          },
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
            GoRoute(
              path: '/players',
              builder: (context, state) => const PlayerListScreen(),
            ),
            GoRoute(
              path: '/my-team',
              builder: (context, state) => const MyTeamScreen(),
            ),
            GoRoute(
              path: '/matches',
              builder: (context, state) => const MatchScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileSetupScreen(),
            ),
          ],
        ),

        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/createMatch',
          builder: (context, state) => const CreateMatchScreen(),
        ),
        GoRoute(
          path: '/matchDetail',
          builder: (context, state) {
            String matchId = '';
            if (state.extra is String) {
              matchId = state.extra as String;
            } else if (state.extra is Map) {
              final extra = state.extra as Map;
              matchId = (extra['matchId'] ?? extra['_id'] ?? extra['id'] ?? '').toString();
            }
            return MatchDetailScreen(matchId: matchId);
          },
        ),
        GoRoute(
          path: '/createTeam',
          builder: (context, state) => const CreateTeamScreen(),
        ),
        GoRoute(
          path: '/allMatches',
          builder: (context, state) => const AllMatchesScreen(),
        ),
        GoRoute(
          path: '/findTeam',
          builder: (context, state) => const FindTeamScreen(),
        ),
        GoRoute(
          path: '/teamChat',
          builder: (context, state) {
            String teamId = '';
            String teamName = 'Nhóm Chat';
            if (state.extra is String) {
              teamId = state.extra as String;
            } else if (state.extra is Map) {
              final extra = state.extra as Map;
              teamId = (extra['teamId'] ?? extra['_id'] ?? extra['id'] ?? '').toString();
              teamName = (extra['teamName'] ?? extra['name'] ?? 'Nhóm Chat').toString();
            }
            return TeamChatScreen(
              teamId: teamId,
              teamName: teamName,
            );
          },
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/ai-chat',
          builder: (context, state) => const AiChatScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Keonhanh',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
