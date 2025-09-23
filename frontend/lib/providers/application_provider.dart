import 'package:flutter/material.dart';

import '../models/application.dart';
import '../services/api_service.dart';

class ApplicationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Application> _applications = [];
  List<Application> _companyApplications = [];
  Application? _selectedApplication;
  bool _isLoading = false;
  String? _error;

  List<Application> get applications => _applications;
  List<Application> get companyApplications => _companyApplications;
  Application? get selectedApplication => _selectedApplication;
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

  void _handleError(dynamic error) {
    if (error.toString().contains('SocketException')) {
      _setError('Tidak ada koneksi internet');
    } else if (error.toString().contains('TimeoutException')) {
      _setError('Koneksi timeout');
    } else {
      _setError('Terjadi kesalahan pada server');
    }
  }

  Future<void> getApplications() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getApplications();
      if (response.statusCode == 200) {
        _applications = (response.data['data']['applications'] as List<dynamic>)
            .map((application) => Application.fromJson(application))
            .toList();
      }
    } catch (e) {
      _handleError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> getCompanyApplications() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getCompanyApplications();
      if (response.statusCode == 200) {
        _companyApplications =
            (response.data['data']['applications'] as List<dynamic>)
                .map((application) => Application.fromJson(application))
                .toList();
      }
    } catch (e) {
      _handleError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> getApplication(String applicationId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getApplication(applicationId);
      if (response.statusCode == 200) {
        _selectedApplication =
            Application.fromJson(response.data['data']['application']);
      }
    } catch (e) {
      _handleError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> applyForJob({
    required String jobId,
    required String coverLetter,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.applyForJob({
        'jobId': jobId,
        'coverLetter': coverLetter,
      });

      if (response.statusCode == 201) {
        await getApplications(); // Refresh applications
        return true;
      } else {
        _setError(response.data['message'] ?? 'Gagal mengirim lamaran');
        return false;
      }
    } catch (e) {
      _handleError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelApplication(String applicationId) async {
    _setLoading(true);
    _clearError();

    try {
      // TODO: Add cancel application endpoint in API service
      // For now, we'll update status to 'cancelled'
      final response =
          await _apiService.updateApplicationStatus(applicationId, {
        'status': 'cancelled',
      });

      if (response.statusCode == 200) {
        await getApplications(); // Refresh applications
        return true;
      } else {
        _setError(response.data['message'] ?? 'Gagal membatalkan lamaran');
        return false;
      }
    } catch (e) {
      _handleError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response =
          await _apiService.updateApplicationStatus(applicationId, {
        'status': status,
      });

      if (response.statusCode == 200) {
        await getCompanyApplications(); // Refresh company applications
        return true;
      } else {
        _setError(
            response.data['message'] ?? 'Gagal memperbarui status lamaran');
        return false;
      }
    } catch (e) {
      _handleError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
