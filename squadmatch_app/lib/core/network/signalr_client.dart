import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

class SignalRClient {
  static final SignalRClient instance = SignalRClient._internal();
  late HubConnection hubConnection;

  SignalRClient._internal() {
    hubConnection = HubConnectionBuilder()
        .withUrl(ApiConstants.hubUrl)
        .withAutomaticReconnect()
        .build();
  }

  Future<void> connect(String joinCode, String nickname, String userId, String avatarUrl) async {
    if (hubConnection.state == HubConnectionState.Connected) return;
    
    try {
      await hubConnection.start();
      debugPrint("Connesso a SignalR - Room: $joinCode");
      await hubConnection.invoke("JoinRoom", args: [joinCode, nickname, userId, avatarUrl]);
    } catch (e) {
      debugPrint("Errore SignalR: $e");
    }
  }

  Future<void> startGame(String joinCode) async {
    await hubConnection.invoke("StartGame", args: [joinCode]);
  }

  void onUserJoined(Function(Map<String, dynamic>) callback) {
    hubConnection.off("UserJoined");
    hubConnection.on("UserJoined", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        callback(arguments[0] as Map<String, dynamic>);
      }
    });
  }

  void onGameStarted(Function() callback) {
    hubConnection.off("OnGameStarted");
    hubConnection.on("OnGameStarted", (arguments) {
      callback();
    });
  }

  void onMatchFound(Function(dynamic) callback) {
    hubConnection.off("OnMatchFound");
    hubConnection.on("OnMatchFound", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        callback(arguments[0]);
      }
    });
  }

  void onGameRestarted(Function() callback) {
    hubConnection.off("OnGameRestarted");
    hubConnection.on("OnGameRestarted", (arguments) {
      callback();
    });
  }

  Future<void> castVote(String joinCode, String userId, String optionId, bool isPositive) async {
    if (hubConnection.state == HubConnectionState.Disconnected) {
      await hubConnection.start();
    }
    await hubConnection.invoke("CastVote", args: [joinCode, userId, optionId, isPositive]);
  }

  Future<void> restartGame(String joinCode) async {
    if (hubConnection.state == HubConnectionState.Disconnected) {
      await hubConnection.start();
    }
    await hubConnection.invoke("RestartGame", args: [joinCode]);
  }

  Future<void> stop() async {
    if (hubConnection.state == HubConnectionState.Connected) {
      await hubConnection.stop();
    }
  }
}
