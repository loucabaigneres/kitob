import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar_community/isar.dart';

import '../constants/app_colors.dart';
import '../models/book.dart';
import '../providers/book_detail_provider.dart';

class BookDetailScreen extends ConsumerWidget {
  final Id bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookStreamProvider(bookId));
    final actionState = ref.watch(bookDetailActionProvider);
    final theme = Theme.of(context);

    final isBusy = actionState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails'),
        actions: [
          IconButton(
            icon: isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Supprimer ce livre',
            onPressed: isBusy ? null : () => _confirmDeletion(context, ref),
          ),
        ],
      ),
      body: bookAsync.when(
        data: (book) {
          if (book == null) {
            return const Center(child: Text('Ce livre n\'existe plus.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 170,
                    height: 240,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.onSurface.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildCover(book),
                  ),
                ),
                const SizedBox(height: 24),

                Center(
                  child: Column(
                    children: [
                      Text(
                        book.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        book.volumeNumber != null
                            ? '${book.author} - Tome ${book.volumeNumber}'
                            : book.author,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text('Statut de lecture', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ReadingStatus>(
                    segments: const [
                      ButtonSegment(value: ReadingStatus.owned, label: Text('Possédé')),
                      ButtonSegment(value: ReadingStatus.toRead, label: Text('À lire')),
                      ButtonSegment(value: ReadingStatus.wishlist, label: Text('Wishlist')),
                    ],
                    selected: {book.status},
                    onSelectionChanged: isBusy
                        ? null
                        : (selection) {
                            ref
                                .read(bookDetailActionProvider.notifier)
                                .updateStatus(book.id, selection.first);
                        },
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      _buildMetaRow('Éditeur', book.publisher ?? 'Non renseigné'),
                      const SizedBox(height: 20),
                      _buildMetaRow('Nombre de pages', book.pageCount != null ? '${book.pageCount} p.' : 'Inconnu'),
                      const SizedBox(height: 20),
                      _buildMetaRow('ISBN', book.isbn ?? 'Non renseigné'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (book.synopsis != null && book.synopsis!.isNotEmpty) ...[
                  Text('Synopsis', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    book.synopsis!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurface,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
      ),
    );
  }
  
  Widget _buildCover(Book book) {
    if (book.coverUrl != null && book.coverUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: book.coverUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => _fallbackCover(),
      );
    } else if (book.localCoverPath != null && book.localCoverPath!.isNotEmpty) {
      return Image.file(
        File(book.localCoverPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackCover(),
      );
    }
    return _fallbackCover();
  }

  Widget _fallbackCover() {
    return const Center(
      child: Icon(Icons.book_outlined, size: 48, color: AppColors.outline),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Future<void> _confirmDeletion(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce livre ?'),
        content: const Text('Cette action retirera définitivement cet ouvrage de votre collection.'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => ctx.pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(bookDetailActionProvider.notifier).deleteBook(bookId);
      if (context.mounted) {
        context.pop();
      }
    }
  }
}
