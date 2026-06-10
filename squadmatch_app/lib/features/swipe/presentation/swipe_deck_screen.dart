import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/signalr_client.dart';
import '../../../domain/models/option.dart';
import '../../../core/constants/api_constants.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class SwipeDeckScreen extends StatefulWidget {
  final String joinCode;
  final String userId;
  final String nickname;
  final bool isHost;

  const SwipeDeckScreen({
    super.key, 
    required this.joinCode, 
    required this.userId,
    required this.nickname,
    required this.isHost,
  });

  @override
  State<SwipeDeckScreen> createState() => _SwipeDeckScreenState();
}

class _SwipeDeckScreenState extends State<SwipeDeckScreen> {

  bool _isLoading = true;
  String? _errorMessage;
  List<Option> _options = [];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _connectToRoom();
    _fetchOptions();
  }

  Future<void> _fetchOptions() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.roomsEndpoint}/${widget.joinCode}/options'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        setState(() {
          _options = jsonList.map((json) => Option.fromJson(json)).toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Stanza non trovata o codice errato.";
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "Errore del server: ${response.statusCode}";
        });
        debugPrint('Failed to load options: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Errore di connessione.";
      });
      debugPrint('Error fetching options: $e');
    }
  }

  Future<void> _connectToRoom() async {
    await SignalRClient.instance.connect(widget.joinCode, widget.nickname, widget.userId, "");
    
    SignalRClient.instance.onMatchFound((winnerId) {
      if (mounted) {
        context.go('/results/${widget.joinCode}?userId=${widget.userId}&nickname=${widget.nickname}&isHost=${widget.isHost}');
      }
    });
  }

  Future<void> _castVote(bool isPositive) async {
    if (_currentIndex >= _options.length) return;

    final option = _options[_currentIndex];
    
    try {
      await SignalRClient.instance.castVote(widget.joinCode, widget.userId, option.id, isPositive);
      
      setState(() {
        _currentIndex++;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore invio voto: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.deepPurple,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 24, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text("Torna alla Home"),
              )
            ],
          ),
        ),
      );
    }

    if (_currentIndex >= _options.length) {
      return const Scaffold(
        body: Center(child: Text("In attesa degli altri...", style: TextStyle(fontSize: 24))),
      );
    }

    final currentOption = _options[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('SquadMatch - Swipe!'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: widget.joinCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Codice copiato negli appunti!')),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Stanza: ${widget.joinCode}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.copy, size: 18, color: Colors.deepPurple),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(currentOption.imageUrl),
                  fit: BoxFit.cover,
                ),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 10))],
              ),
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentOption.title,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    if (currentOption.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          currentOption.description,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: "btn_no",
                  backgroundColor: Colors.redAccent,
                  onPressed: () => _castVote(false),
                  child: const Icon(Icons.close, size: 30, color: Colors.white),
                ),
                FloatingActionButton(
                  heroTag: "btn_yes",
                  backgroundColor: Colors.greenAccent[700],
                  onPressed: () => _castVote(true),
                  child: const Icon(Icons.favorite, size: 30, color: Colors.white),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

}
