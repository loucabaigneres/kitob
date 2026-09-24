import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../models/book.dart';
import '../providers/books_provider.dart';

class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStatus = ref.watch(bookFilterProvider.select((s) => s.status));

    final filters = <(String, ReadingStatus?)>[
      ('Tous', null),
      ('Possédés', ReadingStatus.owned),
      ('À lire', ReadingStatus.toRead),
      ('Wishlit', ReadingStatus.wishList),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: filters.map((filter) {
          final isSelected = currentStatus == filter.$2;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter.$1),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceContainerLow,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              shape: const StadiumBorder(
                side: BorderSide(color: AppColors.outlineVariant, width: 0.8),
              ),
              onSelected: (_) {
                ref.read(bookFilterProvider.notifier).setStatus(filter.$2);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
