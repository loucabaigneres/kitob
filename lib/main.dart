import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitob/providers/auth_provider.dart';

import 'constants/api_constants.dart';
import 'constants/app_theme.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final debugToken = ApiConstants.appCheckDebugToken;
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? AndroidDebugProvider(debugToken: debugToken)
        : AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? AppleDebugProvider(debugToken: debugToken)
        : AppleAppAttestProvider(),
  );

  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authActionProvider);

    return MaterialApp.router(
      title: 'Kitob',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
