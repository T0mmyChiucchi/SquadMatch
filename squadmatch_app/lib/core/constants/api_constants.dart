class ApiConstants {
  // Indirizzo base del backend
  static const String baseUrl = 'http://localhost:5138';

  // Endpoint API REST
  static const String roomsEndpoint = '$baseUrl/api/rooms';

  // Endpoint WebSocket SignalR
  static const String hubUrl = '$baseUrl/roomHub';
}
