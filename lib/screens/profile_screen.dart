import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/sync_provider.dart';
import '../widgets/auth_modal_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value ??
                ref.read(authServiceProvider).currentUser;
    final stats = ref.watch(libraryStatsProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider).value ?? 0;
    final syncState = ref.watch(syncActionProvider);

    final isAnonymous = user?.isAnonymous ?? true;
    final isSyncing = syncState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil & Bibliothèque'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryContainer,
                    child: Icon(
                      isAnonymous ? Icons.person_outline : Icons.menu_book,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAnonymous ? 'Compte invité (Hors-ligne)' : 'Lecteur Kitob',
                          style: theme.textTheme.headlineSmall?.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAnonymous
                              ? 'Vos données sont stockées localement.'
                              : (user?.email ?? 'Compte synchronisé'),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: AppColors.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (_) => AuthModalSheet(currentUser: user),
                      );
                    },
                    child: Text(isAnonymous ? 'Associer' : 'Gérer'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text('Aperçu du catalogue', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    title: 'Volumes totaux',
                    value: '${stats?.totalBooks ?? 0}',
                    icon: Icons.auto_stories_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    title: 'Pages au total',
                    value: stats != null ? '${stats.totalPages}' : '—',
                    icon: Icons.pages_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    title: 'Possédés',
                    value: '${stats?.ownedCount ?? 0}',
                    accentColor: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    title: 'À lire',
                    value: '${stats?.toReadCount ?? 0}',
                    accentColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    title: 'Wishlist',
                    value: '${stats?.wishlistCount ?? 0}',
                    accentColor: AppColors.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Text('Synchronisation Cloud', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            pendingCount > 0 ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
                            color: pendingCount > 0 ? AppColors.tertiary : AppColors.secondary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            pendingCount > 0
                                ? '$pendingCount modification(s) en attente'
                                : 'Catalogue à jour sur le Cloud',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(44),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: isSyncing
                        ? null
                        : () => ref.read(syncActionProvider.notifier).syncNow(),
                    icon: isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sync, size: 18),
                    label: Text(isSyncing ? 'Synchronisation...' : 'Synchroniser maintenant'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    ThemeData theme, {
    required String title,
    required String value,
    IconData? icon,
    Color? accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppColors.outline),
            const SizedBox(height: 8),
          ],
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: accentColor ?? AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
