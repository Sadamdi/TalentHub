import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class SearchFilterBar extends StatelessWidget {
  final TextEditingController? searchController;
  final String? searchQuery;
  final Function(String)? onSearchChanged;
  final VoidCallback? onFilterPressed;

  const SearchFilterBar({
    super.key,
    this.searchController,
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
                  child: TextField(
                    controller: searchController,
                    onSubmitted: (_) =>
                        onSearchChanged?.call(searchController?.text ?? ''),
                    decoration: InputDecoration(
                      hintText: 'search a job here...',
                      hintStyle: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      suffixIcon: GestureDetector(
                        onTap: () {
                          searchController?.clear();
                          onSearchChanged?.call('');
                        },
                        child: const Icon(
                          Icons.clear,
                          size: 16,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
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
          child: GestureDetector(
            onTap: () {
              // Trigger search when filter/search button is pressed
              onSearchChanged?.call(searchController?.text ?? '');
            },
            child: const Icon(
              Icons.search,
              size: 20,
              color: AppColors.textLight,
            ),
          ),
        ),
      ],
    );
  }
}
