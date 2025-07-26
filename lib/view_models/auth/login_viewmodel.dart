// lib/view_models/auth/auth_viewmodel.dart

import 'package:flutter/material.dart';
import '../../repositories/auth_repository.dart';
import '../../shared/failure.dart';
import '../../shared/exceptions.dart';
import '../../services/locator.dart';
import '../../shared/enums.dart';
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = sl<AuthRepository>();
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

  Future<void> login(String username, String password) async {
    _setState(ViewState.Busy);
    _failure = null;

    try {
      // 2. REPLACE THE FAKE DELAY WITH THE REAL REPOSITORY CALL
      await _authRepository.login(username, password);

      _setState(ViewState.Success);
    } on AppException catch (e) { // 3. CATCH OUR SPECIFIC APP EXCEPTIONS
      // Convert the specific exception into a user-friendly Failure object
      if (e is AuthException) {
        _setFailure(AuthFailure(e.message));
      } else if (e is NetworkException) {
        _setFailure(NetworkFailure(e.message));
      } else {
        _setFailure(ServerFailure(e.message));
      }
    }
  }
}