import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/job.dart';
import '../../providers/job_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import 'company_create_job_screen.dart';
import 'job_applications_screen.dart';

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
    print('🔄 CompanyJobsScreen: Loading company jobs...');
    jobProvider.getCompanyJobs().then((_) {
      print(
          '✅ CompanyJobsScreen: Jobs loaded, count: ${jobProvider.companyJobs.length}');
    }).catchError((error) {
      print('❌ CompanyJobsScreen: Error loading jobs: $error');
    });
  }

  Future<void> _showEditJobDialog(BuildContext context, Job job) async {
    final TextEditingController titleController =
        TextEditingController(text: job.title);
    final TextEditingController descriptionController =
        TextEditingController(text: job.description);
    final TextEditingController locationController =
        TextEditingController(text: job.location);
    final TextEditingController salaryController =
        TextEditingController(text: job.salary.toString());
    final TextEditingController jobTypeController =
        TextEditingController(text: job.jobType);
    final TextEditingController categoryController =
        TextEditingController(text: job.category);
    final TextEditingController experienceLevelController =
        TextEditingController(text: job.experienceLevel);
    final TextEditingController skillsController =
        TextEditingController(text: job.skills.join(', '));
    final TextEditingController requirementsController =
        TextEditingController(text: job.requirements.join('\n'));
    final TextEditingController responsibilitiesController =
        TextEditingController(text: job.responsibilities.join('\n'));
    final TextEditingController benefitsController =
        TextEditingController(text: job.benefits.join('\n'));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Job'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Job Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextField(
                controller: salaryController,
                decoration: const InputDecoration(labelText: 'Salary'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: jobTypeController,
                decoration: const InputDecoration(labelText: 'Job Type'),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: experienceLevelController,
                decoration:
                    const InputDecoration(labelText: 'Experience Level'),
              ),
              TextField(
                controller: skillsController,
                decoration: const InputDecoration(
                    labelText: 'Skills (comma separated)'),
              ),
              TextField(
                controller: requirementsController,
                decoration: const InputDecoration(labelText: 'Requirements'),
                maxLines: 3,
              ),
              TextField(
                controller: responsibilitiesController,
                decoration:
                    const InputDecoration(labelText: 'Responsibilities'),
                maxLines: 3,
              ),
              TextField(
                controller: benefitsController,
                decoration: const InputDecoration(labelText: 'Benefits'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final jobProvider =
                  Provider.of<JobProvider>(context, listen: false);

              // Parse skills
              final skills = skillsController.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();

              // Parse requirements and responsibilities
              final requirements = requirementsController.text
                  .split('\n')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();

              final responsibilities = responsibilitiesController.text
                  .split('\n')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();

              final benefits = benefitsController.text
                  .split('\n')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();

              final success = await jobProvider.updateJob(job.id, {
                'title': titleController.text,
                'description': descriptionController.text,
                'location': locationController.text,
                'jobType': jobTypeController.text,
                'category': categoryController.text,
                'experienceLevel': experienceLevelController.text,
                'skills': skills,
                'requirements': requirements,
                'responsibilities': responsibilities,
                'benefits': benefits,
                'salary': {
                  'amount': int.tryParse(salaryController.text) ?? 0,
                  'currency': 'IDR',
                  'period': 'monthly'
                },
              });

              if (success) {
                Navigator.of(context).pop();
                _loadJobs();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _viewApplications(BuildContext context, Job job) async {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    await jobProvider.getJob(job.id);

    if (jobProvider.selectedJob != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              JobApplicationsScreen(jobId: job.id, jobTitle: job.title),
        ),
      );
    }
  }

  Future<void> _toggleJobStatus(
      BuildContext context, Job job, bool activate) async {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final success = activate
        ? await jobProvider.activateJob(job.id)
        : await jobProvider.deactivateJob(job.id);

    if (success) {
      _loadJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pekerjaan Saya'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadJobs,
            tooltip: 'Muat Ulang Pekerjaan',
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
                child: Text('🔄 Hapus Token & Login Ulang'),
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
          if (jobProvider.isLoading && jobProvider.companyJobs.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (jobProvider.error != null && jobProvider.companyJobs.isEmpty) {
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

          if (jobProvider.companyJobs.isEmpty) {
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
                  const SizedBox(height: 16),
                  const Text(
                    'Data Issues? Try fixing data mapping:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          final jobProvider =
                              Provider.of<JobProvider>(context, listen: false);
                          final debug = await jobProvider.debugCompanyData();
                          if (debug != null) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Debug Info'),
                                content: SingleChildScrollView(
                                  child: Text(debug.toString()),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        child: const Text('Debug'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final jobProvider =
                              Provider.of<JobProvider>(context, listen: false);
                          final success = await jobProvider.fixCompanyData();
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Data fixed! Jobs should appear now.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Fix Data'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobProvider.companyJobs.length,
            itemBuilder: (context, index) {
              final job = jobProvider.companyJobs[index];
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
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Delete Job',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                            onSelected: (value) async {
                              switch (value) {
                                case 'edit':
                                  // TODO: Navigate to edit job screen
                                  _showEditJobDialog(context, job);
                                  break;
                                case 'view_applications':
                                  await _viewApplications(context, job);
                                  break;
                                case 'activate':
                                  await _toggleJobStatus(context, job, true);
                                  break;
                                case 'deactivate':
                                  await _toggleJobStatus(context, job, false);
                                  break;
                                case 'delete':
                                  await _deleteJob(context, job);
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

  Future<void> _deleteJob(BuildContext context, Job job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job'),
        content: Text(
            'Are you sure you want to permanently delete "${job.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _apiService.deleteJob(job.id);

        if (success.statusCode == 200) {
          _loadJobs(); // Refresh the job list

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Job "${job.title}" has been permanently deleted'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Failed to delete job: ${success.data['message'] ?? 'Unknown error'}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting job: $error'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
