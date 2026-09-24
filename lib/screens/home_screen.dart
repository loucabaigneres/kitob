import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../models/book.dart';
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
        tooltip: 'Ajouter un livre (test)',
        onPressed: () async {
          final repo = ref.read(bookRepositoryProvider);
          final mockBook = Book()
            ..title = 'Anna Karénine'
            ..author = 'Léon Tolstoï'
            ..status = ReadingStatus.owned
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now()
            ..synopsis = 'Ce livre raconte l’histoire d’Anna Karénine, une femme mariée qui tombe amoureuse d’un officier, le comte Vronski, et qui doit faire face aux conséquences de sa passion dans la société russe du XIXe siècle.';
          
          await repo.saveBook(mockBook);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
