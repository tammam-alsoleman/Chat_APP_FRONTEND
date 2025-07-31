// lib/view_models/auth/sign_up_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fast_rsa/fast_rsa.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../shared/failure.dart';
import '../../shared/exceptions.dart';
import '../../services/locator.dart';
import '../../services/secure_storage_service.dart';
import '../../shared/enums.dart';
import '../user_provider.dart';
import '../call/call_viewmodel.dart';

class SignUpViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = sl<AuthRepository>();
  final UserRepository _userRepository = sl<UserRepository>();
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
      // Generate RSA key pair using fast_rsa
      final keyPair = await RSA.generate(2048);
      final publicKey = keyPair.publicKey;
      final privateKey = keyPair.privateKey;

      // Convert public key to PEM format
      final publicKeyPem = '-----BEGIN PUBLIC KEY-----\n${publicKey}\n-----END PUBLIC KEY-----';

      // Store private key securely using dedicated method
      final storageService = SecureStorageService.instance;
      await storageService.savePrivateKey(privateKey);

      // Sign up with public key
      await _authRepository.signUp(userName, password, displayName, publicKeyPem);

      // Then fetch user data and set it in the provider
      final user = await _userRepository.getMe();
      Provider.of<UserProvider>(context, listen: false).setUser(user);

      // Initialize CallViewModel for the new user
      final callViewModel = sl<CallViewModel>();
      if (!callViewModel.isInitialized) {
        await callViewModel.initialize(user);
      } else {
        // Re-initialize if already initialized (for sign-up case)
        await callViewModel.reinitialize(user);
      }

      _setState(ViewState.Success);
    } on AppException catch (e) {
      if (e is AuthException) {
        if (e.message.contains('User with the same username already exists')) {
          _setFailure(AuthFailure('Username already exists. Please choose a different username.'));
        } else {
          _setFailure(AuthFailure(e.message));
        }
      } else if (e is NetworkException) {
        _setFailure(NetworkFailure(e.message));
      } else {
        _setFailure(ServerFailure(e.message));
      }
    } catch (e) {
      // Handle any other unexpected errors
      _setFailure(ServerFailure('An unexpected error occurred during sign up: $e'));
    }
  }

}
