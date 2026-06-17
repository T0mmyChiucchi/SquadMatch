import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/signalr_client.dart';
import '../../../domain/models/option.dart';
import '../../../core/constants/api_constants.dart';
import 'package:go_router/go_router.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:vibration/vibration.dart';
import '../../../core/theme/app_theme.dart';

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
  bool _isWaiting = false;
  final AppinioSwiperController _swiperController = AppinioSwiperController();
  final Set<int> _votedIndices = {};
  int _topCardIndex = 0;
  int _votesCast = 0;

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

  Future<void> _castVote(int optionIndex, bool isPositive) async {
    if (optionIndex >= _options.length) return;
    if (_votedIndices.contains(optionIndex)) return;
    
    _votedIndices.add(optionIndex);
    final option = _options[optionIndex];
    
    try {
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 30, amplitude: 128);
      }
      
      await SignalRClient.instance.castVote(widget.joinCode, widget.userId, option.id, isPositive);
      
      _votesCast++;
      if (_votesCast >= _options.length) {
        if (mounted) {
          setState(() {
            _isWaiting = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore invio voto: $e')),
        );
      }
    }
  }

  void _onSwipeEnd(int previousIndex, int targetIndex, SwiperActivity activity) {
    if (activity is Swipe) {
      bool isPositive = activity.direction == AxisDirection.right;
      _castVote(previousIndex, isPositive);
      if (previousIndex >= _topCardIndex) {
        _topCardIndex = previousIndex + 1;
      }
    }
  }

  void _triggerSwipeButton(bool isPositive) {
    if (_isWaiting || _topCardIndex >= _options.length) return;
    
    final currentIndex = _topCardIndex;
    _topCardIndex++;
    
    _castVote(currentIndex, isPositive);

    if (isPositive) {
      _swiperController.swipeRight();
    } else {
      _swiperController.swipeLeft();
    }
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
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
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 24, color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
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
        title: const Text('SquadMatch'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: AppinioSwiper(
                      cardCount: _options.length,
                      controller: _swiperController,
                      onSwipeEnd: _onSwipeEnd,
                      cardBuilder: (BuildContext context, int index) {
                        final currentOption = _options[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Image.network(
                                    currentOption.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200]),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    color: AppTheme.cardBackground,
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentOption.title,
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (currentOption.description.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Flexible(
                                            child: Text(
                                              currentOption.description,
                                              style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 16,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0, top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.close_rounded,
                        color: AppTheme.buttonX,
                        onTap: () => _triggerSwipeButton(false),
                      ),
                      _buildActionButton(
                        icon: Icons.favorite_rounded,
                        color: AppTheme.buttonHeart,
                        onTap: () => _triggerSwipeButton(true),
                      ),
                    ],
                  ),
                )
              ],
            ),
            if (_isWaiting)
              Container(
                color: AppTheme.background,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 24),
                      Text(
                        "In attesa degli altri...",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        customBorder: const CircleBorder(),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 15,
                spreadRadius: 5,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, size: 40, color: color),
        ),
      ),
    );
  }

}
