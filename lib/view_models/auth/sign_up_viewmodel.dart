// lib/view_models/auth/sign_up_viewmodel.dart

import 'package:chat_app_frontend/models/user_model.dart';
import 'package:chat_app_frontend/services/socket_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../shared/failure.dart';
import '../../shared/exceptions.dart';
import '../../services/locator.dart';
import '../../services/secure_storage_service.dart';
import '../../shared/enums.dart';
import '../user_provider.dart';
import '../call/call_viewmodel.dart';
import '../../services/crypto_service.dart';

class SignUpViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = sl<AuthRepository>();
  final UserRepository _userRepository = sl<UserRepository>();
  final CryptoService _cryptoService = sl<CryptoService>();
  final SecureStorageService _storageService = sl<SecureStorageService>();

  ViewState _state = ViewState.Idle;
  ViewState get state => _state;

  Failure? _failure;
  Failure? get failure => _failure;

  void _setState(ViewState viewState) {
    _state = viewState;
    notifyListeners();
  }

  void _setFailure(Failure failure) {
    _failure = failure;
    _setState(ViewState.Error);
  }

  Future<void> signUp(String userName, String password, String displayName, BuildContext context) async {
    _setState(ViewState.Busy);
    _failure = null;

    try {
      await _storageService.deletePrivateKey();

      final publicKeyPem = await _cryptoService.generateAndStoreKeyPair(); // Using your corrected CryptoService

      // The repository now returns the user object directly on success.
      final user = await _authRepository.signUp(userName, password, displayName, publicKeyPem);

      // If the line above succeeds, we can proceed with post-login setup.
      await sl<SocketClient>().connectAndListen();
      sl<SocketClient>().registerPresence(user as User);

      Provider.of<UserProvider>(context, listen: false).setUser(user);

      // Initialize CallViewModel
      final callViewModel = sl<CallViewModel>();
      if (!callViewModel.isInitialized) {
        await callViewModel.initialize(user);
      } else {
        await callViewModel.reinitialize(user);
      }

      _setState(ViewState.Success);

    } on AppException catch (e) {
      // ===== THIS BLOCK WILL NOW WORK CORRECTLY =====
      // The repository throws a specific exception, and we catch it here.
      if (e is AuthException) {
        _setFailure(AuthFailure(e.message));
      } else if (e is NetworkException) {
        _setFailure(NetworkException(e.message) as Failure);
      } else {
        _setFailure(ServerFailure(e.message));
      }
      // Because we called _setFailure, the state is now ViewState.Error,
      // and the loading will stop.
    } catch (e) {
      // Handle any other unexpected errors
      _setFailure(ServerFailure('An unexpected error occurred during sign up: $e'));
    }
  }

}
