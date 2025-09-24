import 'package:flutter/material.dart';

import '../models/job.dart';
import '../services/api_service.dart';

class Pagination {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNext;
  final bool hasPrev;

  Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNext,
    required this.hasPrev,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
    );
  }
}

class JobProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Job> _jobs = [];
  List<Job> _companyJobs = [];
  Job? _selectedJob;
  bool _isLoading = false;
  String? _error;
  Pagination? _pagination;

  List<Job> get jobs => _jobs;
  List<Job> get companyJobs => _companyJobs;
  Job? get selectedJob => _selectedJob;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Pagination? get pagination => _pagination;

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
    print('JobProvider Error: $error'); // Debug log

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
    } else if (error.toString().contains('FormatException')) {
      _setError('Format data tidak valid');
    } else {
      // Show only the main error message without full stack trace
      String errorMessage = error.toString();
      if (errorMessage.contains(':')) {
        errorMessage = errorMessage.split(':').first;
      }
      _setError('Terjadi kesalahan: $errorMessage');
    }
  }

  Future<void> getJobs({
    int page = 1,
    String? search,
    String? category,
    String? location,
    String? sort,
    bool refresh = false,
  }) async {
    if (refresh) {
      _jobs.clear();
      _pagination = null;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getJobs(
        page: page,
        search: search,
        category: category,
        location: location,
        sort: sort,
      );

      if (response.statusCode == 200) {
        final jobs = (response.data['data']['jobs'] as List<dynamic>)
            .map((job) => Job.fromJson(job))
            .toList();

        if (refresh) {
          _jobs = jobs;
        } else {
          _jobs.addAll(jobs);
        }

        _pagination = Pagination.fromJson(response.data['data']['pagination']);
      }
    } catch (e) {
      _handleError(e);
    } finally {
      _setLoading(false);
    }
  }

  Job? getJobById(String jobId) {
    try {
      return _jobs.firstWhere((job) => job.id == jobId);
    } catch (e) {
      return null;
    }
  }

  Future<void> getJob(String jobId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getJob(jobId);
      if (response.statusCode == 200) {
        _selectedJob = Job.fromJson(response.data['data']['job']);
      }
    } catch (e) {
      _handleError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> getCompanyJobs() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getCompanyJobs();
      if (response.statusCode == 200) {
        _companyJobs = (response.data['data']['jobs'] as List<dynamic>)
            .map((job) => Job.fromJson(job))
            .toList();
      }
    } catch (e) {
      _handleError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createJob(Map<String, dynamic> jobData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.createJob(jobData);
      if (response.statusCode == 201) {
        await getCompanyJobs(); // Refresh company jobs
        return true;
      } else {
        _setError(response.data['message'] ?? 'Gagal membuat lowongan');
        return false;
      }
    } catch (e) {
      _handleError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateJob(String jobId, Map<String, dynamic> jobData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.updateJob(jobId, jobData);
      if (response.statusCode == 200) {
        await getCompanyJobs(); // Refresh company jobs
        return true;
      } else {
        _setError(response.data['message'] ?? 'Gagal memperbarui lowongan');
        return false;
      }
    } catch (e) {
      _handleError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteJob(String jobId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.deleteJob(jobId);
      if (response.statusCode == 200) {
        await getCompanyJobs(); // Refresh company jobs
        return true;
      } else {
        _setError(response.data['message'] ?? 'Gagal menghapus lowongan');
        return false;
      }
    } catch (e) {
      _handleError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> activateJob(String jobId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.adminActivateJob(jobId);
      if (response.statusCode == 200) {
        await getCompanyJobs(); // Refresh company jobs
        return true;
      } else {
        _setError(response.data['message'] ?? 'Gagal mengaktifkan lowongan');
        return false;
      }
    } catch (e) {
      _handleError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deactivateJob(String jobId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.deleteJob(jobId);
      if (response.statusCode == 200) {
        await getCompanyJobs(); // Refresh company jobs
        return true;
      } else {
        _setError(response.data['message'] ?? 'Gagal menonaktifkan lowongan');
        return false;
      }
    } catch (e) {
      _handleError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> getJobRecommendations({
    String category = 'all',
    int limit = 10,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getJobRecommendations(
        category: category,
        limit: limit,
      );

      if (response.statusCode == 200) {
        final jobs = (response.data['data']['jobs'] as List<dynamic>)
            .map((job) => Job.fromJson(job))
            .toList();
        _jobs = jobs;
      }
    } catch (e) {
      _handleError(e);
    } finally {
      _setLoading(false);
    }
  }

  // Debug and fix company data
  Future<Map<String, dynamic>?> debugCompanyData() async {
    try {
      final response = await _apiService.debugCompanyData();
      if (response.statusCode == 200) {
        return response.data['debug'];
      }
      return null;
    } catch (e) {
      print('JobProvider: Debug company data error: $e');
      return null;
    }
  }

  Future<bool> fixCompanyData() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.fixCompanyData();
      if (response.statusCode == 200) {
        print('JobProvider: Company data fixed successfully');
        // Refresh company jobs after fixing
        await getCompanyJobs();
        return true;
      } else {
        _setError(response.data['message'] ?? 'Gagal memperbaiki data perusahaan');
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
