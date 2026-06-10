import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/signalr_client.dart';

class ResultsScreen extends StatefulWidget {
  final String joinCode;
  final String userId;
  final String nickname;
  final bool isHost;

  const ResultsScreen({
    super.key,
    required this.joinCode,
    required this.userId,
    required this.nickname,
    required this.isHost,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  
  Map<String, dynamic>? _winner;
  List<dynamic> _statistics = [];

  @override
  void initState() {
    super.initState();
    _fetchResults();

    SignalRClient.instance.onGameRestarted(() {
      if (mounted) {
        context.go('/lobby/${widget.joinCode}?userId=${widget.userId}&nickname=${widget.nickname}&isHost=${widget.isHost}');
      }
    });
  }

  Future<void> _fetchResults() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.roomsEndpoint}/${widget.joinCode}/results'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _winner = data['winner'] ?? data['Winner'];
          _statistics = data['statistics'] ?? data['Statistics'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Errore nel caricamento dei risultati.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Errore di connessione.";
        _isLoading = false;
      });
    }
  }

  void _restartGame() async {
    try {
      await SignalRClient.instance.restartGame(widget.joinCode);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore riavvio partita: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.deepPurple,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
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
              Text(_errorMessage!, style: const TextStyle(fontSize: 24, color: Colors.white)),
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

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Risultati'),
        automaticallyImplyLeading: false, // Disabilita tasto back
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_winner != null) ...[
                const Text(
                  "Vincitore!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: NetworkImage(_winner!['imageUrl'] ?? _winner!['ImageUrl']),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
                  ),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                    ),
                    child: Text(
                      _winner!['name'] ?? _winner!['Name'],
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  "Nessun vincitore!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 32),
              const Text(
                "Statistiche Voti",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _statistics.length,
                itemBuilder: (context, index) {
                  final stat = _statistics[index];
                  final name = stat['name'] ?? stat['Name'];
                  final positive = stat['positiveVotes'] ?? stat['PositiveVotes'] ?? 0;
                  final negative = stat['negativeVotes'] ?? stat['NegativeVotes'] ?? 0;
                  final imageUrl = stat['imageUrl'] ?? stat['ImageUrl'];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(imageUrl),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite, color: Colors.green, size: 20),
                          const SizedBox(width: 4),
                          Text('$positive', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          const Icon(Icons.close, color: Colors.red, size: 20),
                          const SizedBox(width: 4),
                          Text('$negative', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              if (widget.isHost)
                ElevatedButton(
                  onPressed: _restartGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Gioca Ancora",
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "In attesa che l'Host decida se giocare ancora...",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
