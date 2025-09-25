import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/job_card.dart';
import '../../widgets/search_filter_bar.dart';
import 'job_detail_screen.dart';
import 'job_search_screen.dart';

class TalentDashboard extends StatefulWidget {
  const TalentDashboard({super.key});

  @override
  State<TalentDashboard> createState() => _TalentDashboardState();
}

class _TalentDashboardState extends State<TalentDashboard> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  bool _isLoadingMore = false;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadJobs({bool refresh = false}) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    jobProvider.getJobs(
      page: refresh ? 1 : _currentPage,
      refresh: refresh,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      category: _selectedCategory != 'all' ? _selectedCategory : null,
    );
  }

  void _onSearchChanged(String query) {
    // This will be called by the SearchFilterBar
    _loadJobs(refresh: true);
  }

  void _onFilterChanged(String category) {
    setState(() {
      _selectedCategory = category.toLowerCase();
      _currentPage = 1;
    });
    _loadJobs(refresh: true);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Pekerjaan'),
        content: const Text('Opsi filter akan segera hadir!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreJobs();
    }
  }

  void _loadMoreJobs() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    if (!_isLoadingMore && jobProvider.pagination?.hasNext == true) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });

      _loadJobs();

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<JobProvider, AuthProvider>(
        builder: (context, jobProvider, authProvider, child) {
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
                    onPressed: () => _loadJobs(refresh: true),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            controller: _scrollController,
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
                              // Clock removed as requested
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
                            // Camera-like button removed as requested
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

              // Header dengan greeting
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                            'Selamat Siang, ${authProvider.user?.firstName ?? 'User'}.\n',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          height: 1.50,
                                        ),
                                      ),
                                      const TextSpan(
                                        text:
                                            'Mulai karir Anda di sini dengan ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w400,
                                          height: 1.50,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: 'TalentHub',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          height: 1.50,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowLight,
                                blurRadius: 10,
                                offset: Offset(1, 0),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Search dan filter bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SearchFilterBar(
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                    onFilterPressed: _showFilterDialog,
                  ),
                ),
              ),

              // Promotional banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowMedium,
                          blurRadius: 10,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Kami Merekrut UI/UX Designer',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Bergabung dengan tim kami dan ciptakan pengalaman luar biasa',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.work_outline,
                            size: 60,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),

              // Section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recommendation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const JobSearchScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'See all',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filter buttons
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua', _selectedCategory == 'all'),
                        const SizedBox(width: 15),
                        _buildFilterChip(
                            'Penulis', _selectedCategory == 'writer'),
                        const SizedBox(width: 15),
                        _buildFilterChip(
                            'Desainer', _selectedCategory == 'designer'),
                        const SizedBox(width: 15),
                        _buildFilterChip(
                            'Keuangan', _selectedCategory == 'finance'),
                        const SizedBox(width: 15),
                        _buildFilterChip(
                            'Pemasaran', _selectedCategory == 'marketing'),
                        const SizedBox(width: 15),
                        _buildFilterChip(
                            'Developer', _selectedCategory == 'developer'),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),

              // Job cards
              if (jobProvider.jobs.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 64,
                            color: AppColors.textLight,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada lowongan tersedia',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < jobProvider.jobs.length) {
                        final job = jobProvider.jobs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: JobCard(
                            job: job,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      JobDetailScreen(jobId: job.id),
                                ),
                              );
                            },
                          ),
                        );
                      } else if (_isLoadingMore) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return null;
                    },
                    childCount:
                        jobProvider.jobs.length + (_isLoadingMore ? 1 : 0),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _getFilterCategory(String label) {
    switch (label) {
      case 'Semua':
        return 'all';
      case 'Penulis':
        return 'writer';
      case 'Desainer':
        return 'designer';
      case 'Keuangan':
        return 'finance';
      case 'Pemasaran':
        return 'marketing';
      case 'Developer':
        return 'developer';
      default:
        return label.toLowerCase();
    }
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _onFilterChanged(
          label == 'Semua' ? 'all' : _getFilterCategory(label)),
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: AppColors.primary,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.primary,
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              height: 1.50,
            ),
          ),
        ),
      ),
    );
  }
}
