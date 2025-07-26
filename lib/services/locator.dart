import 'package:get_it/get_it.dart';
import '../repositories/auth_repository.dart';
import '../repositories/messaging_repository.dart';
import '../repositories/user_repository.dart';
import '../services/dio_client.dart';
import '../services/secure_storage_service.dart';
import '../services/socket_client.dart';
import '../view_models/auth/login_viewmodel.dart';
import '../view_models/chat/chat_list_viewmodel.dart';

// Create a global instance of GetIt
final sl = GetIt.instance;

void setupServiceLocator() {
  // --- CORE SERVICES (Singletons) ---
  // They are created once and reused.
  sl.registerLazySingleton(() => SecureStorageService.instance);
  sl.registerLazySingleton(() => DioClient.instance);
  sl.registerLazySingleton(() => SocketClient.instance);

  // --- REPOSITORIES (Singletons) ---
  // They are also created once. They depend on the core services.
  sl.registerLazySingleton(() => AuthRepository());
  sl.registerLazySingleton(() => MessagingRepository());
  sl.registerLazySingleton(() => UserRepository());
  // --- VIEW MODELS (Factories) ---
  // We need a new instance of a ViewModel every time we create a screen.
  sl.registerFactory(() => AuthViewModel());
  sl.registerFactory(() => ChatListViewModel());
}