import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import '../providers/scan_provider.dart';
import '../widgets/scan_result_sheet.dart';

class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanProvider);
    final theme = Theme.of(context);

    ref.listen(scanProvider, (previous, next) {
      if (next.step == ScanStep.completed && next.candidateBook != null) {
        showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => ScanResultSheet(
            candidateBook: next.candidateBook!,
            isDuplicate: next.isDuplicate,
          ),
        ).then((saved) {
          if (saved == true && context.mounted) {
            context.pop();
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Numériser un livre'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.width * 1.05,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
              ),
            ),
          ),

          if (scanState.step != ScanStep.idle && 
              scanState.step != ScanStep.completed &&
              scanState.step != ScanStep.error)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      _resolveStepLabel(scanState.step),
                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
                    ),
                  ]
                ),
              ),
            ),
          
          if (scanState.step == ScanStep.error)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  scanState.errorMessage ?? 'Une erreur est survenue.',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filledTonal(
                  iconSize: 28,
                  onPressed: () => ref.read(scanProvider.notifier).processImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                ),
                GestureDetector(
                  onTap: () => ref.read(scanProvider.notifier).processImage(ImageSource.camera),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
                  ),
                ),
                IconButton.filledTonal(
                  iconSize: 28,
                  onPressed: () => ref.read(scanProvider.notifier).reset(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _resolveStepLabel(ScanStep step) {
    switch (step) {
      case ScanStep.capturing:
        return 'Capture de l\'image...';
      case ScanStep.analyzingImage:
        return 'Analyse IA Gemini Vision...';
      case ScanStep.enrichingMetadata:
        return 'Recherche Google Books...';
      case ScanStep.checkingDuplicates:
        return 'Vérification des doublons...';
      default:
        return 'Chargement...';
    }
  }
}
