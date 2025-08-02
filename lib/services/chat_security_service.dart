// lib/services/chat_security_service.dart
import 'package:encrypt/encrypt.dart' as enc;

class ChatSecurityService {
  ChatSecurityService._();
  static final ChatSecurityService instance = ChatSecurityService._();

  // Change the type of the value to enc.Key
  final Map<String, enc.Key> _keyCache = {};

  // Change the parameter type to enc.Key
  void storeKey(String groupId, enc.Key key) {
    _keyCache[groupId] = key;
  }

  // Change the return type to enc.Key
  enc.Key? getKey(String groupId) {
    return _keyCache[groupId];
  }

  void clearAllKeys() {
    _keyCache.clear();
  }
}