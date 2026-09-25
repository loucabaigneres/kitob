import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../providers/scan_provider.dart';
import '../widgets/scan_result_sheet.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await ref.read(availableCamerasProvider.future);
    if (cameras.isEmpty) return;

    final rearCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    
    _cameraController = CameraController(
      rearCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (_) {
      // Ignored: fallback UI will display if camera is missing (e.g., on simulator)
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || controller.value.isTakingPicture) {
      return;
    }

    try {
      final xFile = await controller.takePicture();
      await ref.read(scanProvider.notifier).processCapturedFile(File(xFile.path));
    } catch (e) {
      // Handled by ScanProvider state if processing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    final theme = Theme.of(context);

    // Triggers bottom sheet on scan completion
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

    final isBusy = scanState.step != ScanStep.idle &&
        scanState.step != ScanStep.completed &&
        scanState.step != ScanStep.error;

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
        fit: StackFit.expand,
        children: [
          if (_isCameraInitialized && _cameraController != null)
            Center(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: Text(
                'Caméra indisponible ou simulateur détecté. \nUtilisez le sélecteur de galerie.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),

          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.width * 1.05,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    spreadRadius: 2000,
                  ),
                ],
              ),
            ),
          ),

          if (isBusy)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
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
                  onPressed: isBusy ? null : () => ref.read(scanProvider.notifier).pickFromGallery(),
                  icon: const Icon(Icons.photo_library_outlined),
                ),
                GestureDetector(
                  onTap: isBusy ? null : _takePicture,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isBusy ? Colors.grey : AppColors.primary,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
                  ),
                ),
                IconButton.filledTonal(
                  iconSize: 28,
                  onPressed: isBusy ? null : () => ref.read(scanProvider.notifier).reset(),
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
