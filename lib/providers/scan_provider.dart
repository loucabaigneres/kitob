import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/book.dart';
import '../services/gemini_vision_service.dart';
import '../services/google_books_service.dart';
import 'books_provider.dart';

final geminiVisionServiceProvider = Provider<GeminiVisionService>((ref) => GeminiVisionService());
final googleBooksServiceProvider = Provider<GoogleBooksService>((ref) => GoogleBooksService());

enum ScanStep {
  idle,
  capturing,
  analyzingImage,
  enrichingMetadata,
  checkingDuplicates,
  completed,
  error,
}

class ScanState {
  final ScanStep step;
  final String? errorMessage;
  final File? capturedImageFile;
  final Book? candidateBook;
  final bool isDuplicate;

  const ScanState({
    this.step = ScanStep.idle,
    this.errorMessage,
    this.capturedImageFile,
    this.candidateBook,
    this.isDuplicate = false,
  });

  ScanState copyWith({
    ScanStep? step,
    String? errorMessage,
    File? capturedImageFile,
    Book? candidateBook,
    bool? isDuplicate,
  }) {
    return ScanState(
      step: step ?? this.step,
      errorMessage: errorMessage,
      capturedImageFile: capturedImageFile ?? this.capturedImageFile,
      candidateBook: candidateBook ?? this.candidateBook,
      isDuplicate: isDuplicate ?? this.isDuplicate,
    );
  }
}

class ScanNotifier extends Notifier<ScanState> {
  @override
  ScanState build() => const ScanState();

  final ImagePicker _picker = ImagePicker();

  Future<void> processImage(ImageSource source) async {
    try {
      state = state.copyWith(step: ScanStep.capturing, errorMessage: null);

      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        state = state.copyWith(step: ScanStep.idle);
        return;
      }

      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final mimeType = pickedFile.mimeType ?? 'image/jpeg';

      state = state.copyWith(step: ScanStep.analyzingImage, capturedImageFile: file);
      final geminiService = ref.read(geminiVisionServiceProvider);
      final extraction = await geminiService.extractBookDetails(bytes, mimeType);

      state = state.copyWith(step: ScanStep.enrichingMetadata);
      final booksService = ref.read(googleBooksServiceProvider);
      final metadata = await booksService.searchBook(
        title: extraction.title,
        author: extraction.author,
      );

      state = state.copyWith(step: ScanStep.checkingDuplicates);
      final repository = ref.read(bookRepositoryProvider);
      final duplicate = await repository.findDuplicateBook(
        isbn: metadata?.isbn,
        title: metadata?.title ?? extraction.title,
        author: metadata?.author ?? extraction.author,
      );

      final candidate = Book()
          ..title = metadata?.title ?? extraction.title
          ..author = metadata?.author ?? extraction.author
          ..volumeNumber = extraction.volumeNumber
          ..isbn = metadata?.isbn
          ..coverUrl = metadata?.coverUrl
          ..localCoverPath = file.path
          ..publisher = metadata?.publisher
          ..pageCount = metadata?.pageCount
          ..synopsis = metadata?.synopsis
          ..status = ReadingStatus.owned
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
      
      state = state.copyWith(
        step: ScanStep.completed,
        candidateBook: candidate,
        isDuplicate: duplicate != null,
      );
    } catch (e) {
      state = state.copyWith(
        step: ScanStep.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> confirmSave(ReadingStatus status) async {
    final book = state.candidateBook;
    if (book == null) return;

    book.status = status;
    book.updatedAt = DateTime.now();

    final repository = ref.read(bookRepositoryProvider);
    await repository.saveBook(book);
    state = const ScanState(); // Reset state after saving
  }

  void reset() {
    state = const ScanState();
  }
}

final scanProvider = NotifierProvider.autoDispose<ScanNotifier, ScanState>(
  ScanNotifier.new,
);
