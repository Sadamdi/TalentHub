import 'package:dio/dio.dart';
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
    // Gunakan addPostFrameCallback untuk menghindari setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _clearError() {
    _error = null;
  }

  void _setError(String error) {
    _error = error;
    // Gunakan addPostFrameCallback untuk menghindari setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
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
      // Handle DioError untuk mendapatkan detail error dari server
      if (e is DioException) {
        if (e.response != null) {
          // Server mengembalikan response dengan error
          final errorData = e.response!.data;
          if (errorData is Map<String, dynamic>) {
            _setError(errorData['message'] ?? 'Login gagal');
          } else {
            _setError('Login gagal');
          }
        } else {
          // Network error atau server tidak merespons
          _setError('Tidak dapat terhubung ke server');
        }
      } else {
        _setError('Terjadi kesalahan saat login');
      }
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
      final requestData = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'role': role,
      };

      // Hanya tambahkan location dan phoneNumber jika tidak null dan tidak kosong
      if (location != null && location.isNotEmpty) {
        requestData['location'] = location;
      }
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        requestData['phoneNumber'] = phoneNumber;
      }

      final response = await _apiService.register(requestData);

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
      // Handle DioError untuk mendapatkan detail error dari server
      if (e is DioException) {
        if (e.response != null) {
          // Server mengembalikan response dengan error
          final errorData = e.response!.data;
          if (errorData is Map<String, dynamic>) {
            // Jika ada array errors, ambil pesan error pertama
            if (errorData['errors'] != null &&
                errorData['errors'] is List &&
                (errorData['errors'] as List).isNotEmpty) {
              final firstError = (errorData['errors'] as List).first;
              if (firstError is Map<String, dynamic> &&
                  firstError['msg'] != null) {
                _setError(firstError['msg']);
              } else {
                _setError(errorData['message'] ?? 'Registrasi gagal');
              }
            } else {
              _setError(errorData['message'] ?? 'Registrasi gagal');
            }
          } else {
            _setError('Registrasi gagal');
          }
        } else {
          // Network error atau server tidak merespons
          _setError('Tidak dapat terhubung ke server');
        }
      } else {
        _setError('Terjadi kesalahan saat registrasi');
      }
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
        // Gunakan addPostFrameCallback untuk menghindari setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    } catch (e) {
      _setError('Gagal mendapatkan data user');
    }
  }

  Future<void> logout() async {
    await _apiService.removeToken();
    _user = null;
    _error = null;
    // Gunakan addPostFrameCallback untuk menghindari setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
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
