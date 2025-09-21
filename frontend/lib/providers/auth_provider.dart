import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _setLoading(true);
    _clearError();

    try {
      final token = await _apiService.getToken();
      if (token != null) {
        await _getCurrentUser();
      }
    } catch (e) {
      _setError('Gagal memeriksa status autentikasi');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.login({
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['data']['token'];
        await _apiService.setToken(token);
        await _getCurrentUser();
        return true;
      } else {
        _setError(response.data['message'] ?? 'Login gagal');
        return false;
      }
    } catch (e) {
      _setError('Terjadi kesalahan saat login');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
    String? location,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.register({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'role': role,
        'location': location,
        'phoneNumber': phoneNumber,
      });

      if (response.statusCode == 201) {
        final token = response.data['data']['token'];
        await _apiService.setToken(token);
        await _getCurrentUser();
        return true;
      } else {
        _setError(response.data['message'] ?? 'Registrasi gagal');
        return false;
      }
    } catch (e) {
      _setError('Terjadi kesalahan saat registrasi');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _getCurrentUser() async {
    try {
      final response = await _apiService.getCurrentUser();
      if (response.statusCode == 200) {
        _user = User.fromJson(response.data['data']['user']);
        notifyListeners();
      }
    } catch (e) {
      _setError('Gagal mendapatkan data user');
    }
  }

  Future<void> logout() async {
    await _apiService.removeToken();
    _user = null;
    _error = null;
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.updateProfile(data);
      if (response.statusCode == 200) {
        await _getCurrentUser();
        return true;
      } else {
        _setError(response.data['message'] ?? 'Gagal memperbarui profil');
        return false;
      }
    } catch (e) {
      _setError('Terjadi kesalahan saat memperbarui profil');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}

