class ApiEndPoints {
  // --- API Endpoints ---
  static const String authSignIn = '/api/auth/sign_in';
  static const String authLogIn = '/api/auth/log_in';
  static const String authSignUp = '/api/auth/sign_up';
  
  static const String usersMe = '/api/users/me';
  static const String usersSearch = '/api/users/search';

  static const String chats = '/api/chats';
  static String chatParticipants(int chatId) => '/api/chats/$chatId/participants';
  static String chatMessages(int chatId) => '/api/chats/$chatId/messages';
}

class StorageKeys {
  static const String authToken = 'auth_token';
  static const String privateKey = 'private_key';
}