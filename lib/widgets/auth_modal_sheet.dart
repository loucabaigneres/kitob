import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';

class AuthModalSheet extends ConsumerStatefulWidget {
  final User? currentUser;

  const AuthModalSheet({super.key, required this.currentUser});

  @override
  ConsumerState<AuthModalSheet> createState() => _AuthModalSheetState();
}

class _AuthModalSheetState extends ConsumerState<AuthModalSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _errorMessage = null);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.length < 6) {
      setState(() => _errorMessage = 'Email valide et mot de passe de 6+ caractères requis.');
      return;
    }

    try {
      if (_isLoginMode) {
        await ref.read(authActionProvider.notifier).signIn(email, password);
      } else {
        await ref.read(authActionProvider.notifier).linkAccount(email, password);
      }

      // If the user is logged in, trigger a sync
      await ref.read(syncActionProvider.notifier).syncNow();

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authActionState = ref.watch(authActionProvider);
    final isBusy = authActionState.isLoading;
    final isAnonymous = widget.currentUser?.isAnonymous ?? true;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isAnonymous ? 'Sauvegarder ma bibliothèque' : 'Mon Compte Kitob',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            isAnonymous
                ? 'Associez un email pour synchroniser vos livres sur le Cloud et ne jamais perdre vos données.'
                : 'Connecté en tant que : ${widget.currentUser?.email}',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          if (isAnonymous) ...[
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Adresse email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe (6+ caractères)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder(),
              ),
              onPressed: isBusy ? null : _handleSubmit,
              child: isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isLoginMode ? 'Se connecter' : 'Créer mon compte'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: isBusy ? null : () => setState(() => _isLoginMode = !_isLoginMode),
              child: Text(_isLoginMode
                  ? 'Pas encore de compte ? Créez-en un.'
                  : 'Vous avez déjà un compte ? Connectez-vous.'),
            ),
          ] else ...[
            FilledButton.tonal(
              onPressed: isBusy
                  ? null
                  : () async {
                    await ref.read(authActionProvider.notifier).signOut();
                    if (context.mounted) context.pop();
                  },
              child: const Text('Se déconnecter'),
            ),
          ],
        ],
      ),
    );
  }
}
