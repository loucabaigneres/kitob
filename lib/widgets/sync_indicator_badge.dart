import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../providers/sync_provider.dart';

class SyncIndicatorBadge extends ConsumerWidget {
  const SyncIndicatorBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCountAsync = ref.watch(pendingSyncCountProvider);
    final syncState = ref.watch(syncActionProvider);

    final isSyncing = syncState.isLoading;
    final pendingCount = pendingCountAsync.value ?? 0;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        tooltip: isSyncing
            ? 'Synchronisation en cours...'
            : (pendingCount > 0 ? '$pendingCount élément(s) en attente ' : 'Synchronisé avec le Cloud'),
        onPressed: isSyncing ? null : () => ref.read(syncActionProvider.notifier).syncNow(),
        icon: isSyncing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              )
            : Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              backgroundColor: AppColors.tertiary,
              child: Icon(
                pendingCount > 0 ? Icons.cloud_queue : Icons.cloud_done_outlined,
                color: pendingCount > 0 ? AppColors.tertiary : AppColors.secondary,
              ),
            ),
      ),
    );
  }
}
