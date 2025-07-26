// lib/view_models/chat/chat_list_viewmodel.dart

import 'package:flutter/material.dart';
import '../../models/group_model.dart';
import '../../repositories/messaging_repository.dart';
import '../../shared/exceptions.dart';
import '../../shared/failure.dart';
import '../../shared/enums.dart';
import '../../services/locator.dart';

class ChatListViewModel extends ChangeNotifier {
  final MessagingRepository _messagingRepository = sl<MessagingRepository>();
  ViewState _state = ViewState.Idle;
  ViewState get state => _state;

  Failure? _failure;
  Failure? get failure => _failure;

  List<Group> _chats = [];
  List<Group> get chats => _chats;

  void _setState(ViewState viewState) {
    _state = viewState;
    notifyListeners();
  }

  void _setFailure(Failure failure) {
    _failure = failure;
    _setState(ViewState.Error);
  }

  /// Fetches the list of chats from the repository.
  Future<void> fetchChats() async {
    _setState(ViewState.Busy);
    _failure = null;

    try {
      final chatList = await _messagingRepository.getMyChats();
      _chats = chatList;
      _setState(ViewState.Idle); // Change to Idle to show the list
    } on AppException catch (e) {
      if (e is NetworkException) {
        _setFailure(NetworkFailure(e.message));
      } else {
        _setFailure(ServerFailure(e.message));
      }
    }
  }
}