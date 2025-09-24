import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../utils/app_colors.dart';
import 'apply_job_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;

  const JobDetailScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isApplying = false;
  bool _hasApplied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<JobProvider>(context, listen: false).getJob(widget.jobId);

      // Check if user has already applied for this job
      final applicationProvider =
          Provider.of<ApplicationProvider>(context, listen: false);
      await applicationProvider.getApplications();

      if (applicationProvider.applications
          .any((app) => app.jobId == widget.jobId)) {
        setState(() {
          _hasApplied = true;
        });
      }
    });
  }

  Future<void> _applyForJob() async {
    if (_isApplying) return;

    setState(() {
      _isApplying = true;
    });

    final applicationProvider =
        Provider.of<ApplicationProvider>(context, listen: false);

    final result = await applicationProvider.applyForJob(
      jobId: widget.jobId,
      fullName: 'Test User', // TODO: Get from user profile
      email: 'test@example.com', // TODO: Get from user profile
      phone: '+6281234567890', // TODO: Get from user profile
      coverLetter: 'Saya tertarik dengan posisi ini dan ingin melamar.',
    );

    // Navigate to ApplyJobScreen instead of directly applying
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final job = jobProvider.getJobById(widget.jobId);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ApplyJobScreen(
          jobId: widget.jobId,
          job: job,
        ),
      ),
    ).then((_) {
      // Refresh applications when returning from ApplyJobScreen
      _refreshApplications();
    });
  }

  Future<void> _refreshApplications() async {
    setState(() {
      _isApplying = true;
    });

    final applicationProvider =
        Provider.of<ApplicationProvider>(context, listen: false);
    await applicationProvider.getApplications();

    // Check if user has applied for this job
    if (applicationProvider.applications
        .any((app) => app.jobId == widget.jobId)) {
      setState(() {
        _hasApplied = true;
      });
    }

    setState(() {
      _isApplying = false;
    });
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<JobProvider>(
        builder: (context, jobProvider, child) {
          if (jobProvider.isLoading && jobProvider.selectedJob == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (jobProvider.error != null && jobProvider.selectedJob == null) {
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
                    onPressed: () {
                      jobProvider.getJob(widget.jobId);
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final job = jobProvider.selectedJob;
          if (job == null) {
            return const Center(
              child: Text('Lowongan pekerjaan tidak ditemukan'),
            );
          }

          return CustomScrollView(
            slivers: [
              // Status bar
              SliverToBoxAdapter(
                child: Container(
                  height: 59,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          height: double.infinity,
                          padding: const EdgeInsets.only(left: 10, bottom: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 54,
                                height: 21,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Center(
                                  child: Text(
                                    '9:41',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontFamily: 'SF Pro Text',
                                      fontWeight: FontWeight.w600,
                                      height: 1.31,
                                      letterSpacing: -0.32,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 125,
                              height: 37,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: double.infinity,
                          padding: const EdgeInsets.only(right: 11),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 27.40,
                                height: 13,
                                child: Stack(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // App bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowMedium,
                              blurRadius: 10,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const Text(
                        'Job Details',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          height: 1.50,
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        child: const Icon(
                          Icons.share,
                          size: 24,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Job overview card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowDark,
                              blurRadius: 10,
                              offset: Offset(1, 0),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 79,
                                  height: 79,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppColors.shadowLight,
                                        blurRadius: 10,
                                        offset: Offset(1, 0),
                                      ),
                                    ],
                                  ),
                                  child: job.company?.logo != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                            job.company!.logo!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.business,
                                                  color: AppColors.primary,
                                                  size: 40,
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.business,
                                            color: AppColors.primary,
                                            size: 40,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        job.title,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          height: 1.50,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        job.company?.companyName ??
                                            'Perusahaan',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w500,
                                          height: 1.50,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Salary\nType\nLocation',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    height: 1.50,
                                  ),
                                ),
                                Text(
                                  '${job.salary.formattedSalary}\n${job.formattedJobType}\n${job.location}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: AppColors.info,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    height: 1.50,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Job description card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowDark,
                              blurRadius: 10,
                              offset: Offset(1, 0),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Job Descriptions',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                height: 1.50,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              job.description,
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                                height: 1.50,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Requirements card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowDark,
                              blurRadius: 10,
                              offset: Offset(1, 0),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Requirements',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                height: 1.50,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              job.requirements.join('\n'),
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                                height: 1.50,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100), // Space for bottom buttons
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.user?.role != 'talent') {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed:
                          _isApplying || _hasApplied ? null : _applyForJob,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _hasApplied ? AppColors.success : AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isApplying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _hasApplied ? 'Applied' : 'Apply Now',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                height: 1.50,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 78,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 11),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: AppColors.primary,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.bookmark_border,
                size: 24,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
