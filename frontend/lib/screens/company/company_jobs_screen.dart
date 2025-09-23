import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/job_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import 'company_create_job_screen.dart';

class CompanyJobsScreen extends StatefulWidget {
  const CompanyJobsScreen({super.key});

  @override
  State<CompanyJobsScreen> createState() => _CompanyJobsScreenState();
}

class _CompanyJobsScreenState extends State<CompanyJobsScreen> {
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  void _loadJobs() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    jobProvider.getCompanyJobs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadJobs,
            tooltip: 'Refresh Jobs',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear_token':
                  // TODO: Implement clear token functionality
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_token',
                child: Text('🔄 Clear Token & Relogin'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const CompanyCreateJobScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<JobProvider>(
        builder: (context, jobProvider, child) {
          if (jobProvider.isLoading && jobProvider.jobs.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (jobProvider.error != null && jobProvider.jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    jobProvider.error!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadJobs,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (jobProvider.jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.work_outline,
                    size: 64,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No jobs posted yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first job posting',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CompanyCreateJobScreen(),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: 8),
                        Text('Create Job'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobProvider.jobs.length,
            itemBuilder: (context, index) {
              final job = jobProvider.jobs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: job.isActive
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              job.isActive ? 'Active' : 'Draft',
                              style: TextStyle(
                                fontSize: 12,
                                color: job.isActive
                                    ? AppColors.success
                                    : AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        job.company?.companyName ?? 'Perusahaan',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            job.location,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            job.formattedJobType,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rp ${job.salary.toString().replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                  (Match m) => '${m[1]},',
                                )}/monthly',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit Job'),
                              ),
                              const PopupMenuItem(
                                value: 'view_applications',
                                child: Text('View Applications'),
                              ),
                              PopupMenuItem(
                                value: job.isActive ? 'deactivate' : 'activate',
                                child: Text(
                                  job.isActive ? 'Deactivate' : 'Activate',
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  // TODO: Navigate to edit job screen
                                  break;
                                case 'view_applications':
                                  // TODO: Navigate to applications for this job
                                  break;
                                case 'activate':
                                case 'deactivate':
                                  // TODO: Toggle job status
                                  break;
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CompanyCreateJobScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
