import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/book.dart';
import '../services/gemini_vision_service.dart';
import '../services/google_books_service.dart';
import 'books_provider.dart';

final availableCamerasProvider = FutureProvider<List<CameraDescription>>((ref) async {
  return await availableCameras();
});

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

  Future<void> processCapturedFile(File file) async {
    try {
      state = state.copyWith(step: ScanStep.capturing, capturedImageFile: file, errorMessage: null);

      final bytes = await file.readAsBytes();
      final mimeType = file.path.endsWith('.png') ? 'image/png' : 'image/jpeg';

      final geminiService = ref.read(geminiVisionServiceProvider);
      final extraction = await geminiService.extractBookDetails(bytes, mimeType);

      if (!extraction.isBook || extraction.title == null || extraction.title!.trim().isEmpty) {
        throw Exception('Aucun livre reconnu. Assurez-vous que la couverture ou la tranche est bien cadrée et nette.');
      }

      final extractedTitle = extraction.title!.trim();
      final extractedAuthor = extraction.author?.trim() ?? 'Auteur inconnu';

      state = state.copyWith(step: ScanStep.enrichingMetadata);
      final booksService = ref.read(googleBooksServiceProvider);
      final metadata = await booksService.searchBook(
        title: extractedTitle,
        author: extractedAuthor,
      );

      state = state.copyWith(step: ScanStep.checkingDuplicates);
      final repository = ref.read(bookRepositoryProvider);
      final duplicate = await repository.findDuplicateBook(
        isbn: metadata?.isbn,
        title: metadata?.title ?? extractedTitle,
        author: metadata?.author ?? extractedAuthor,
      );

      final candidate = Book()
          ..title = metadata?.title ?? extractedTitle
          ..author = metadata?.author ?? extractedAuthor
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
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        step: ScanStep.error,
        errorMessage: message,
      );
    }
  }

  Future<void> pickFromGallery() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      await processCapturedFile(File(pickedFile.path));
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
