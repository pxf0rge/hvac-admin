import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/enums/user_role.dart';
import 'package:hvac_admin/core/models/office_user.dart';
import 'package:hvac_admin/data/repositories/office_personnel_repository.dart';

/// Office Personnel directory + management mutations.
class OfficePersonnelController extends ChangeNotifier {
  OfficePersonnelController(this._repository);

  final OfficePersonnelRepository _repository;
  List<OfficeUser> _users = const [];
  bool _loading = false;
  bool _mutating = false;
  String? _error;

  bool get isLoading => _loading;
  bool get isMutating => _mutating;
  String? get loadError => _error;
  List<OfficeUser> get users => List.unmodifiable(_users);

  OfficeUser? userById(String id) {
    for (final user in _users) {
      if (user.id == id) return user;
    }
    return null;
  }

  Future<void> load({bool force = false}) async {
    if (!force && _users.isNotEmpty) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _users = await _repository.getOfficeUsers();
    } catch (error, stack) {
      _error = error.toString();
      debugPrint('OfficePersonnelController.load failed: $error\n$stack');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<OfficeUser?> invite({
    required String email,
    required String firstName,
    required String lastName,
    required UserRole role,
  }) async {
    return _runMutation(
      () => _repository.inviteOfficeUser(
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: role,
      ),
    );
  }

  Future<OfficeUser?> changeRole({
    required String userId,
    required UserRole role,
  }) async {
    return _runMutation(() => _repository.setRole(userId: userId, role: role));
  }

  Future<OfficeUser?> setActive({
    required String userId,
    required bool isActive,
  }) async {
    return _runMutation(() => _repository.setActive(userId: userId, isActive: isActive));
  }

  Future<OfficeUser?> _runMutation(Future<OfficeUser> Function() action) async {
    _mutating = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await action();
      final next = [..._users];
      final index = next.indexWhere((u) => u.id == saved.id);
      if (index >= 0) {
        next[index] = saved;
      } else {
        next.add(saved);
      }
      next.sort((a, b) {
        final roleCmp = a.role.dbValue.compareTo(b.role.dbValue);
        if (roleCmp != 0) return roleCmp;
        return a.lastName.compareTo(b.lastName);
      });
      _users = next;
      return saved;
    } on OfficePersonnelException catch (error) {
      _error = error.message;
      return null;
    } catch (error, stack) {
      _error = error.toString();
      debugPrint('OfficePersonnelController.mutation failed: $error\n$stack');
      return null;
    } finally {
      _mutating = false;
      notifyListeners();
    }
  }
}
