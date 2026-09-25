import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../models/book.dart';
import '../providers/scan_provider.dart';

class ScanResultSheet extends ConsumerStatefulWidget {
  final Book candidateBook;
  final bool isDuplicate;

  const ScanResultSheet({
    super.key,
    required this.candidateBook,
    required this.isDuplicate,
  });

  @override
  ConsumerState<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends ConsumerState<ScanResultSheet> {
  late ReadingStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.candidateBook.status;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = widget.candidateBook;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (widget.isDuplicate) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.onTertiaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ce titre semble déjà présent dans votre bibliothèque.',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Text(book.title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            book.volumeNumber != null
                ? '${book.author} - Tome ${book.volumeNumber}'
                : book.author,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          Text('Statut d\'acquisition :', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<ReadingStatus>(
            segments: const [
              ButtonSegment(value: ReadingStatus.owned, label: Text('Possédé')),
              ButtonSegment(value: ReadingStatus.toRead, label: Text('À lire')),
              ButtonSegment(value: ReadingStatus.wishlist, label: Text('Wishlist')),
            ],
            selected: {_selectedStatus},
            onSelectionChanged: (set) {
              setState(() => _selectedStatus = set.first);
            },
          ),
          const SizedBox(height: 24),

          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
            ),
            onPressed: () async {
              await ref.read(scanProvider.notifier).confirmSave(_selectedStatus);
              if (context.mounted) Navigator.of(context).pop(true);
            },
            child: const Text('Ajouter à la bibliothèque'),
          ),
        ],
      ),
    );
  }
}
