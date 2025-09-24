import 'package:flutter/material.dart';
import 'dart:io';

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
    print('ApplicationProvider Error: $error'); // Debug log

    // Handle DioException
    if (error.toString().contains('DioException')) {
      if (error.toString().contains('Connection refused')) {
        _setError('Tidak dapat terhubung ke server. Pastikan server berjalan.');
      } else if (error.toString().contains('Connection timeout')) {
        _setError('Koneksi timeout. Coba lagi.');
      } else if (error.toString().contains('bad response')) {
        _setError('Terjadi kesalahan pada server. Coba lagi nanti.');
      } else {
        _setError('Terjadi kesalahan koneksi. Coba lagi.');
      }
    } else if (error.toString().contains('SocketException')) {
      _setError('Tidak ada koneksi internet');
    } else if (error.toString().contains('TimeoutException')) {
      _setError('Koneksi timeout');
    } else {
      // Show only the main error message without full stack trace
      String errorMessage = error.toString();
      if (errorMessage.contains(':')) {
        errorMessage = errorMessage.split(':').first;
      }
      _setError('Terjadi kesalahan: $errorMessage');
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

  Future<Map<String, dynamic>> applyForJob({
    required String jobId,
    required String fullName,
    required String email,
    required String phone,
    required String coverLetter,
    String? experienceYears,
    List<String>? skills,
    String? resumeUrl,
    File? cvFile,
  }) async {
    _setLoading(true);
    _clearError();

    // Debug: print all data
    print('ApplicationProvider: Applying for jobId: $jobId');
    print('ApplicationProvider: Full name: $fullName');
    print('ApplicationProvider: Email: $email');
    print('ApplicationProvider: Phone: $phone');
    print('ApplicationProvider: Cover letter: $coverLetter');
    print('ApplicationProvider: Experience: $experienceYears');
    print('ApplicationProvider: Skills: $skills');
    print('ApplicationProvider: CV File: ${cvFile?.path ?? 'No file'}');

    try {
      // Upload file first if provided
      String? uploadedFileName;
      if (cvFile != null) {
        print('ApplicationProvider: Uploading CV file...');
        final uploadResponse = await _apiService.uploadFile(cvFile);
        if (uploadResponse.statusCode == 200) {
          uploadedFileName = uploadResponse.data['data']['fileName'];
          print('ApplicationProvider: File uploaded: $uploadedFileName');
        } else {
          _setError('Failed to upload CV file');
          return {'success': false, 'message': 'Failed to upload CV file'};
        }
      }

      final response = await _apiService.applyForJob({
        'jobId': jobId,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'coverLetter': coverLetter,
        'experienceYears': experienceYears ?? '',
        'skills': skills ?? [],
        'resumeUrl': uploadedFileName,
      });

      print('ApplicationProvider: Response status: ${response.statusCode}');
      print('ApplicationProvider: Response data: ${response.data}');

      if (response.statusCode == 201) {
        await getApplications(); // Refresh applications
        return {'success': true, 'message': 'Application submitted successfully'};
      } else {
        _setError(response.data['message'] ?? 'Gagal mengirim lamaran');
        return {'success': false, 'message': response.data['message'] ?? 'Gagal mengirim lamaran'};
      }
    } catch (e) {
      print('ApplicationProvider: Error: $e');
      _handleError(e);
      return {'success': false, 'message': 'Error submitting application: $e'};
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> updateApplicationStatus({
    required String applicationId,
    required String status,
    String? notes,
    String? feedback,
  }) async {
    _setLoading(true);
    _clearError();

    print('ApplicationProvider: Updating status for application: $applicationId to $status');

    try {
      final response = await _apiService.updateApplicationStatus(
        applicationId: applicationId,
        status: status,
        notes: notes,
        feedback: feedback,
      );

      print('ApplicationProvider: Status update response: ${response.statusCode}');
      print('ApplicationProvider: Response data: ${response.data}');

      if (response.statusCode == 200) {
        await getApplications(); // Refresh applications
        return {'success': true, 'message': 'Status updated successfully'};
      } else {
        _setError(response.data['message'] ?? 'Failed to update status');
        return {'success': false, 'message': response.data['message'] ?? 'Failed to update status'};
      }
    } catch (e) {
      print('ApplicationProvider: Error updating status: $e');
      _handleError(e);
      return {'success': false, 'message': 'Error updating status: $e'};
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> deleteApplication(String applicationId) async {
    _setLoading(true);
    _clearError();

    print('ApplicationProvider: Deleting application: $applicationId');

    try {
      final response = await _apiService.deleteApplication(applicationId);

      print('ApplicationProvider: Delete response: ${response.statusCode}');
      print('ApplicationProvider: Response data: ${response.data}');

      if (response.statusCode == 200) {
        await getApplications(); // Refresh applications
        return {'success': true, 'message': 'Application deleted successfully'};
      } else {
        _setError(response.data['message'] ?? 'Failed to delete application');
        return {'success': false, 'message': response.data['message'] ?? 'Failed to delete application'};
      }
    } catch (e) {
      print('ApplicationProvider: Error deleting application: $e');
      _handleError(e);
      return {'success': false, 'message': 'Error deleting application: $e'};
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
          await _apiService.updateApplicationStatus(
        applicationId: applicationId,
        status: 'cancelled',
      );

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
}
