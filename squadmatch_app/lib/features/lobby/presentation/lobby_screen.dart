import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/network/signalr_client.dart';

class LobbyScreen extends StatefulWidget {
  final String joinCode;
  final String userId;
  final String nickname;
  final String avatarUrl;
  final bool isHost;

  const LobbyScreen({
    super.key,
    required this.joinCode,
    required this.userId,
    required this.nickname,
    required this.avatarUrl,
    required this.isHost,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLobby();
  }

  Future<void> _initLobby() async {
    // 1. Fetch room details
    try {
      final response = await http.get(Uri.parse('${ApiConstants.roomsEndpoint}/${widget.joinCode}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'] ?? data['Status'];
        if (status == 'Voting') {
          // Game already started, skip lobby
          if (mounted) {
            context.go('/room/${widget.joinCode}?userId=${widget.userId}&nickname=${widget.nickname}&isHost=${widget.isHost}');
          }
          return;
        }

        final List<dynamic> usersData = data['users'] ?? data['Users'] ?? [];
        for (var u in usersData) {
          final nickname = u['nickname'] ?? u['Nickname'];
          final avatarUrl = u['avatarUrl'] ?? u['AvatarUrl'] ?? 'https://api.dicebear.com/9.x/bottts/png?seed=Felix';
          final isHost = u['isHost'] ?? u['IsHost'] ?? false;
          
          if (nickname != null) {
            _users.add({
              'nickname': nickname,
              'avatarUrl': avatarUrl,
              'isHost': isHost,
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Errore fetching room details: $e");
    }

    // Assicuriamoci che l'utente corrente sia nella lista (nel caso in cui non sia stato aggiunto dalla HTTP fetch)
    final existsSelf = _users.any((u) => u['nickname'] == widget.nickname);
    if (!existsSelf) {
      _users.add({
        'nickname': widget.nickname,
        'avatarUrl': widget.avatarUrl,
        'isHost': widget.isHost,
      });
    }

    setState(() {
      _isLoading = false;
    });

    // 2. Listen to events (BEFORE connecting to avoid race conditions!)
    SignalRClient.instance.onUserJoined((user) {
      if (mounted) {
        setState(() {
          final nickname = user['nickname'] ?? user['Nickname'];
          final avatarUrl = user['avatarUrl'] ?? user['AvatarUrl'] ?? 'https://api.dicebear.com/9.x/bottts/png?seed=Felix';
          
          if (nickname != null) {
            final exists = _users.any((u) => u['nickname'] == nickname);
            if (!exists) {
              _users.add({
                'nickname': nickname,
                'avatarUrl': avatarUrl,
                'isHost': false,
              });
            }
          }
        });
      }
    });

    SignalRClient.instance.onGameStarted(() {
      if (mounted) {
        context.go('/room/${widget.joinCode}?userId=${widget.userId}&nickname=${widget.nickname}&isHost=${widget.isHost}');
      }
    });

    // 3. Connect to SignalR
    await SignalRClient.instance.connect(widget.joinCode, widget.nickname, widget.userId, widget.avatarUrl);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startGame() {
    SignalRClient.instance.startGame(widget.joinCode);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.deepPurple,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.deepPurple,
      appBar: AppBar(
        title: const Text('Lobby', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Codice: ',
                    style: TextStyle(fontSize: 24, color: Colors.white70),
                  ),
                  Text(
                    widget.joinCode,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.joinCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Codice copiato!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Giocatori in attesa',
              style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final u = _users[index];
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        backgroundImage: NetworkImage(u['avatarUrl']),
                      ),
                      title: Text(u['nickname'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                      trailing: u['isHost'] ? const Icon(Icons.star, color: Colors.amber) : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            if (widget.isHost)
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _users.length > 1 ? _startGame : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: Text(
                    _users.length > 1 ? 'AVVIA PARTITA' : 'IN ATTESA DI ALTRI...',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: _users.length > 1 ? Colors.black : Colors.white70
                    ),
                  ),
                ),
              )
            else
              const Center(
                child: Text(
                  'In attesa che l\'host avvii la partita...',
                  style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic),
                ),
              )
          ],
        ),
      ),
    );
  }
}
