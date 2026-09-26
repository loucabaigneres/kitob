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
  String? _localValidationError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _localValidationError = null);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _localValidationError = 'Veuillez saisir une adresse email valide.');
      return;
    }
    if (password.length < 6) {
      setState(() => _localValidationError = 'Le mot de passe doit comporter au moins 6 caractères.');
      return;
    }

    if (_isLoginMode) {
      await ref.read(authActionProvider.notifier).signIn(email, password);
    } else {
      await ref.read(authActionProvider.notifier).linkAccount(email, password);
    }
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Identifiants incorrects. Vérifiez votre email et mot de passe.';
      case 'email-already-in-use':
      case 'credential-already-in-use':
        return 'Cet email est déjà associé à un autre compte Kitob.';
      case 'invalid-email':
        return 'Le format de l\'adresse email est invalide.';
      case 'weak-password':
        return 'Le mot de passe doit comporter au moins 6 caractères.';
      case 'network-request-failed':
        return 'Impossible de contacter les serveurs. Vérifiez votre connexion.';
      case 'too-many-requests':
        return 'Trop de tentatives infructueuses. Veuillez réessayer plus tard.';
      default:
        return 'Erreur d\'authentification ($code).';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authAction = ref.watch(authActionProvider);
    final isBusy = authAction.isLoading;
    final isAnonymous = widget.currentUser?.isAnonymous ?? true;

    ref.listen<AsyncValue<void>>(authActionProvider, (previous, next) {
      if (previous?.isLoading == true && next.hasValue && !next.hasError) {
        ref.read(syncActionProvider.notifier).syncNow();
        if (context.mounted) context.pop();
      }
    });

    String? resolvedError = _localValidationError;
    if (authAction.hasError) {
      final err = authAction.error;
      if (err is FirebaseAuthException) {
        resolvedError = _mapFirebaseAuthError(err.code);
      } else {
        resolvedError = 'Une erreur inattendue est survenue.';
      }
    }

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
            if (resolvedError != null) ...[
              const SizedBox(height: 12),
              Text(
                resolvedError,
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
                  },
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Se déconnecter'),
            ),
          ],
        ],
      ),
    );
  }
}
