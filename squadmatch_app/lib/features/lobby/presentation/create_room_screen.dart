import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/avatar_utils.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _joinCodeController = TextEditingController();
  bool _isLoading = false;
  String? _userId;
  String _selectedAvatar = AvatarUtils.availableAvatars[0];

  @override
  void initState() {
    super.initState();
    _initUserId();
  }

  Future<void> _initUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString('localUserId');
    if (storedId == null) {
      storedId = const Uuid().v4();
      await prefs.setString('localUserId', storedId);
    }
    setState(() {
      _userId = storedId;
    });
  }

  Future<void> _createRoom() async {
    if (_nicknameController.text.trim().isEmpty || _userId == null) return;

    setState(() => _isLoading = true);

    try {
      final userId = _userId!;

      final response = await http.post(
        Uri.parse(ApiConstants.roomsEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Category': 'Food',
          'QuorumRule': 'Unanimity',
          'HostNickname': _nicknameController.text.trim(),
          'HostUserId': userId,
          'HostAvatarUrl': _selectedAvatar
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final joinCode = data['joinCode']; 
        
        if (mounted) {
          context.go('/lobby/$joinCode?userId=$userId&nickname=${_nicknameController.text.trim()}&avatarUrl=$_selectedAvatar&isHost=true');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore API: ${response.statusCode} - ${response.body}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _joinRoom() {
    if (_nicknameController.text.trim().isEmpty || _joinCodeController.text.trim().isEmpty || _userId == null) return;

    if (_joinCodeController.text.trim().length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Il codice stanza deve essere di 5 caratteri.')));
      return;
    }

    final joinCode = _joinCodeController.text.trim().toUpperCase();
    final userId = _userId!;
    
    context.go('/lobby/$joinCode?userId=$userId&nickname=${_nicknameController.text.trim()}&avatarUrl=$_selectedAvatar&isHost=false');
  }

  Widget _buildAvatarCarousel() {
    return Column(
      children: [
        const Text(
          'Scegli il tuo Avatar',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: AvatarUtils.availableAvatars.length,
            itemBuilder: (context, index) {
              final avatar = AvatarUtils.availableAvatars[index];
              final isSelected = _selectedAvatar == avatar;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatar = avatar;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.amberAccent : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: Image.network(
                        avatar,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.group_work, size: 80, color: Colors.white),
              const SizedBox(height: 10),
              const Text(
                'SquadMatch',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 30),
              _buildAvatarCarousel(),
              const SizedBox(height: 20),
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  hintText: 'Il tuo Nickname',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator() 
                    : const Text('CREA STANZA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
              const Divider(color: Colors.white54),
              const SizedBox(height: 20),
              const Text(
                'Oppure unisciti a una stanza esistente:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _joinCodeController,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(5),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    return TextEditingValue(
                      text: newValue.text.toUpperCase(),
                      selection: newValue.selection,
                    );
                  }),
                ],
                decoration: InputDecoration(
                  hintText: 'Codice Stanza',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _joinRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                  ),
                  child: const Text('UNISCITI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
