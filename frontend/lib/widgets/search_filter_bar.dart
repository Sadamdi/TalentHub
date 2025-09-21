import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class SearchFilterBar extends StatelessWidget {
  final String? searchQuery;
  final Function(String)? onSearchChanged;
  final VoidCallback? onFilterPressed;

  const SearchFilterBar({
    super.key,
    this.searchQuery,
    this.onSearchChanged,
    this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 10,
                  offset: Offset(1, 0),
                ),
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 4,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  size: 20,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'search a job here...',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                      height: 1.50,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 53,
          height: 42,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 10,
                offset: Offset(1, 0),
              ),
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.filter_list,
            size: 20,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}
