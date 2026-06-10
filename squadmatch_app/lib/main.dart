import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/lobby/presentation/create_room_screen.dart';
import 'features/lobby/presentation/lobby_screen.dart';
import 'features/swipe/presentation/swipe_deck_screen.dart';
import 'features/swipe/presentation/results_screen.dart';

void main() {
  runApp(const SquadMatchApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const CreateRoomScreen();
      },
    ),
    GoRoute(
      path: '/lobby/:joinCode',
      builder: (BuildContext context, GoRouterState state) {
        final joinCode = state.pathParameters['joinCode']!;
        final userId = state.uri.queryParameters['userId'] ?? "22222222-2222-2222-2222-222222222222";
        final nickname = state.uri.queryParameters['nickname'] ?? "AmicoInvitato";
        final avatarUrl = state.uri.queryParameters['avatarUrl'] ?? 'https://api.dicebear.com/9.x/bottts/png?seed=Felix';
        final isHost = state.uri.queryParameters['isHost'] == 'true';

        return LobbyScreen(
          joinCode: joinCode,
          userId: userId,
          nickname: nickname,
          avatarUrl: avatarUrl,
          isHost: isHost,
        );
      },
    ),
    GoRoute(
      path: '/room/:joinCode',
      builder: (BuildContext context, GoRouterState state) {
        final joinCode = state.pathParameters['joinCode']!;
        final userId = state.uri.queryParameters['userId'] ?? "22222222-2222-2222-2222-222222222222";
        final nickname = state.uri.queryParameters['nickname'] ?? "AmicoInvitato";
        final isHost = state.uri.queryParameters['isHost'] == 'true';

        return SwipeDeckScreen(
          joinCode: joinCode,
          userId: userId,
          nickname: nickname,
          isHost: isHost,
        );
      },
    ),
    GoRoute(
      path: '/results/:joinCode',
      builder: (BuildContext context, GoRouterState state) {
        final joinCode = state.pathParameters['joinCode']!;
        final userId = state.uri.queryParameters['userId'] ?? "22222222-2222-2222-2222-222222222222";
        final nickname = state.uri.queryParameters['nickname'] ?? "AmicoInvitato";
        final isHost = state.uri.queryParameters['isHost'] == 'true';

        return ResultsScreen(
          joinCode: joinCode,
          userId: userId,
          nickname: nickname,
          isHost: isHost,
        );
      },
    ),
  ],
);

class SquadMatchApp extends StatelessWidget {
  const SquadMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SquadMatch',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
