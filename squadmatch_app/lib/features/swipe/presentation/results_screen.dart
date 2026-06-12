import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/signalr_client.dart';
import 'package:confetti/confetti.dart';
import '../../../core/theme/app_theme.dart';

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
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _fetchResults();

    SignalRClient.instance.onGameRestarted(() {
      if (mounted) {
        context.go('/lobby/${widget.joinCode}?userId=${widget.userId}&nickname=${widget.nickname}&isHost=${widget.isHost}');
      }
    });

    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
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

        if (_winner != null) {
          _confettiController.play();
        }
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
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: AppTheme.buttonX),
              const SizedBox(height: 20),
              Text(_errorMessage!, style: const TextStyle(fontSize: 24, color: AppTheme.textPrimary)),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.textPrimary,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Torna alla Home"),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Risultati'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_winner != null) ...[
                    const Text(
                      "Il Gruppo ha deciso!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 24),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween<double>(begin: 0, end: 1),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 50 * (1 - value)),
                          child: Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          image: DecorationImage(
                            image: NetworkImage(_winner!['imageUrl'] ?? _winner!['ImageUrl']),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
                          ),
                          child: Text(
                            _winner!['name'] ?? _winner!['Name'],
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      "Nessun accordo trovato :(",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.buttonX),
                    ),
                  ],
                  const SizedBox(height: 48),
                  const Text(
                    "Statistiche Voti",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
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
                        color: AppTheme.cardBackground,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(imageUrl),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite, color: AppTheme.buttonHeart, size: 20),
                              const SizedBox(width: 4),
                              Text('$positive', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              const SizedBox(width: 16),
                              const Icon(Icons.close, color: AppTheme.buttonX, size: 20),
                              const SizedBox(width: 4),
                              Text('$negative', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
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
                        backgroundColor: AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: AppTheme.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppTheme.buttonHeart,
                AppTheme.buttonX,
                Colors.amber,
                Colors.deepPurpleAccent
              ],
            ),
          ),
        ],
      ),
    );
  }
}
