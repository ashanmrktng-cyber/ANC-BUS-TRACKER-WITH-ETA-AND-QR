import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../data/services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user          => _user;
  bool get isLoading           => _isLoading;
  String? get error            => _error;
  bool get isLoggedIn          => _user != null;

  void _set(bool loading, [String? err]) {
    _isLoading = loading;
    _error = err;
    notifyListeners();
  }

  // Pure Firebase Auth Login (Works for both Admin and Parents)
  Future<bool> loginWithEmail(String email, String password) async {
    _set(true, null);
    try {
      final credential = await FirebaseService.signInWithEmail(email, password);
      return await _handleUserCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint("Login Error: ${e.code}");
      String msg = 'Login failed';
      if (e.code == 'user-not-found') msg = 'No user found with this email.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') msg = 'Incorrect password.';
      if (e.code == 'network-request-failed') msg = 'Network error. Check connection.';
      _set(false, msg);
      return false;
    } catch (e) {
      _set(false, 'An unexpected error occurred.');
      return false;
    }
  }

  Future<bool> _handleUserCredential(UserCredential credential) async {
    final fbUser = credential.user;
    if (fbUser != null) {
      final userData = await FirebaseService.getUserData(fbUser.uid);
      
      if (userData != null) {
        _user = UserModel.fromMap({...userData, 'userId': fbUser.uid});
      } else if (fbUser.email == 'ancbustracker@admin.com') {
        _user = UserModel(
          phoneNumber: '',
          name: 'School Admin',
          userId: fbUser.uid,
          accountCode: 'ANC',
          role: UserRole.driver,
        );
      } else {
        // Fallback for new parents if Firestore is slightly delayed
        _user = UserModel(
          phoneNumber: '',
          name: 'Parent',
          userId: fbUser.uid,
          accountCode: 'ANC',
          role: UserRole.parent,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone', _user!.phoneNumber);
      await prefs.setString('name', _user!.name);
      await prefs.setString('userId', _user!.userId);
      await prefs.setString('role', _user!.role.name);
      await prefs.setBool('isLoggedIn', true);

      _set(false);
      return true;
    }
    _set(false, 'User not found.');
    return false;
  }

  Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isLoggedIn') ?? false) {
      _user = UserModel(
        phoneNumber: prefs.getString('phone') ?? '',
        name: prefs.getString('name') ?? '',
        userId: prefs.getString('userId') ?? '',
        accountCode: 'ANC',
        role: prefs.getString('role') == 'driver' ? UserRole.driver : UserRole.parent,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await FirebaseService.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _user = null;
    notifyListeners();
  }
}
