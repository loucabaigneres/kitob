import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../providers/books_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/filter_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(booksStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Kitob', style: theme.textTheme.headlineSmall),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: SearchBar(
              hintText: 'Rechercher par titre, auteur...',
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: const WidgetStatePropertyAll(AppColors.surfaceContainerLow),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              leading: const Icon(Icons.search, color: AppColors.outline),
              onChanged: (val) {
                ref.read(bookFilterProvider.notifier).setSearchQuery(val);
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const FilterBar(),
          const SizedBox(height: 12),
          Expanded(
            child: bookAsync.when(
              data: (books) {
                if (books.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucun ouvrage dans cette section.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return BookCard(
                      book: book,
                      onTap: () {
                        // TODO: Navigate to book details page
                      }
                    );
                  }
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Erreur Isar : $err', style: theme.textTheme.bodyMedium),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Numériser un livre',
        onPressed: () => context.push('/scan'),
        child: const Icon(Icons.camera_alt_outlined),
      ),
    );
  }
}
