import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
      } else {
        _setError(
            'Gagal mendapatkan data user: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('AuthProvider _getCurrentUser error: $e');
      if (e.toString().contains('DioException')) {
        if (e.toString().contains('Connection refused')) {
          _setError(
              'Tidak dapat terhubung ke server. Pastikan server berjalan.');
        } else if (e.toString().contains('Connection timeout')) {
          _setError('Koneksi timeout. Coba lagi.');
        } else if (e.toString().contains('bad response')) {
          _setError('Terjadi kesalahan pada server. Coba lagi nanti.');
        } else {
          _setError('Terjadi kesalahan koneksi. Coba lagi.');
        }
      } else {
        _setError('Gagal mendapatkan data user');
      }
    }
  }

  Future<bool> _isProfileComplete() async {
    try {
      final response = await _apiService.getCurrentUser();
      if (response.statusCode == 200) {
        final userData = response.data['data']['user'];
        // Check if essential profile data is filled
        // For now, we consider profile complete if user has location or phone number
        return (userData['location'] != null &&
                userData['location'].toString().isNotEmpty) ||
            (userData['phoneNumber'] != null &&
                userData['phoneNumber'].toString().isNotEmpty);
      }
      return false;
    } catch (e) {
      return false;
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

  Future<String?> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      print('🔄 Starting Google Sign In...');

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // First, sign out any existing user to ensure clean state
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('❌ Google Sign In cancelled by user');
        _setError('Google Sign In dibatalkan');
        return null;
      }

      print('✅ Google user signed in: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('❌ Google authentication tokens are null');
        _setError('Gagal mendapatkan token Google');
        return null;
      }

      print('✅ Google authentication tokens obtained');

      // Split display name properly
      final displayName = googleUser.displayName ?? '';
      final nameParts = displayName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final requestData = {
        'email': googleUser.email,
        'firstName': firstName,
        'lastName': lastName,
        'googleId': googleUser.id,
        'accessToken': googleAuth.accessToken,
        'idToken': googleAuth.idToken,
      };

      print('📡 Sending Google auth data to server: ${requestData['email']}');

      final response = await _apiService.googleSignIn(requestData);

      print('📡 Server response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['data']['token'];
        await _apiService.setToken(token);
        await _getCurrentUser();

        print('✅ Google Sign In successful, checking profile completeness...');

        // Check if user profile is complete
        final isProfileComplete = await _isProfileComplete();
        if (!isProfileComplete) {
          print('⚠️ Profile incomplete, redirecting to completion');
          return 'profile_incomplete';
        }

        print('✅ Profile complete, sign in successful');
        return 'success';
      } else {
        print('❌ Server error: ${response.data}');
        _setError(response.data['message'] ?? 'Google Sign In gagal');
        return null;
      }
    } catch (e) {
      print('❌ Google Sign In exception: $e');

      if (e is DioException) {
        if (e.response != null) {
          final errorData = e.response!.data;
          print('❌ Server error response: $errorData');
          if (errorData is Map<String, dynamic>) {
            _setError(errorData['message'] ?? 'Google Sign In gagal');
          } else {
            _setError('Google Sign In gagal');
          }
        } else {
          _setError('Tidak dapat terhubung ke server');
        }
      } else {
        // Log the actual error for debugging
        _setError('Terjadi kesalahan saat Google Sign In: ${e.toString()}');
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }
}
