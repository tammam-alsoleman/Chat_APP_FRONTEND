// lib/view_models/chat/new_chat_viewmodel.dart
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../repositories/group_repository.dart';
import '../../repositories/user_repository.dart';
import '../../services/locator.dart';
import '../../shared/enums.dart';
import '../../shared/failure.dart';
import '../../shared/exceptions.dart';

class NewChatViewModel extends ChangeNotifier {
  final UserRepository _userRepository = sl<UserRepository>();
  final GroupRepository _groupRepository = sl<GroupRepository>();
  final User _currentUser;

  NewChatViewModel({required User currentUser}) : _currentUser = currentUser;

  ViewState _state = ViewState.Idle;
  ViewState get state => _state;

  Failure? _failure;
  Failure? get failure => _failure;

  List<User> _searchResults = [];
  List<User> get searchResults => _searchResults;

  List<User> _selectedUsers = [];
  List<User> get selectedUsers => _selectedUsers;

  String? _createdGroupId;
  String? get createdGroupId => _createdGroupId;

  void _setState(ViewState viewState) {
    _state = viewState;
    notifyListeners();
  }

  void _setFailure(Failure failure) {
    _failure = failure;
    notifyListeners();
  }

  /// Searches for users based on a query.
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _setState(ViewState.Busy);
    try {
      final users = await _userRepository.searchUsers(query);
      // Exclude the current user from search results
      _searchResults = users.where((user) => user.userId != _currentUser.userId).toList();
    } on ServerException catch (e) {
      _setFailure(ServerFailure(e.message));
    }
    _setState(ViewState.Idle);
  }

  /// Adds a user to the list of participants for the new group.
  void selectUser(User user) {
    if (!_selectedUsers.any((u) => u.userId == user.userId)) {
      _selectedUsers.add(user);
      _searchResults = []; // Clear search results after selection
      notifyListeners();
    }
  }

  /// Removes a user from the list of participants.
  void deselectUser(User user) {
    _selectedUsers.removeWhere((u) => u.userId == user.userId);
    notifyListeners();
  }

  /// Calls the repository to create a new encrypted group.
  Future<void> createGroup() async {
    if (_selectedUsers.isEmpty) {
      _setFailure(AuthFailure("Please select at least one user to start a chat."));
      return;
    }
    _setState(ViewState.Busy);
    _failure = null;

    try {
      // Get the IDs of all participants, including the current user
      final participantIds = [_currentUser.userId, ..._selectedUsers.map((u) => u.userId)];

      // The repository handles the entire secure handshake
      final newGroupId = await _groupRepository.createEncryptedGroup(participantIds);
      _createdGroupId = newGroupId;
      _setState(ViewState.Success);

    } catch (e) {
      _setFailure(ServerFailure("Failed to create secure group: ${e.toString()}"));
      _setState(ViewState.Error);
    }
  }
}