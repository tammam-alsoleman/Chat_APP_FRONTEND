import 'package:get_it/get_it.dart';
import '../repositories/auth_repository.dart';
import '../repositories/messaging_repository.dart';
import '../repositories/user_repository.dart';
import '../services/dio_client.dart';
import '../services/secure_storage_service.dart';
import '../services/socket_client.dart';
import '../view_models/auth/login_viewmodel.dart';
import '../view_models/chat/chat_list_viewmodel.dart';
import '../view_models/call/call_viewmodel.dart';
import '../repositories/presence_repository.dart';
import '../repositories/call_repository.dart';
import 'permission_service.dart';

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
  sl.registerLazySingleton(() => PresenceRepository());
  sl.registerLazySingleton(() => CallRepository());
  
  // --- SERVICES ---
  sl.registerLazySingleton(() => PermissionService());
  
  // --- VIEW MODELS ---
  // Auth and Chat ViewModels are factories (new instance per screen)
  sl.registerFactory(() => AuthViewModel());
  sl.registerFactory(() => ChatListViewModel());
  
  // CallViewModel is a singleton (one instance for entire app lifecycle)
  sl.registerLazySingleton(() => CallViewModel(
    presenceRepository: sl<PresenceRepository>(),
    callRepository: sl<CallRepository>(),
    userRepository: sl<UserRepository>(),
    socketClient: sl<SocketClient>(),
  ));
}