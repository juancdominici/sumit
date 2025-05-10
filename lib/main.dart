import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:sumit/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sumit/services/translations_service.dart';
import 'package:june/june.dart';
import 'package:sumit/state/settings.dart';
import 'package:sumit/utils.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sumit/utils/translations_extension.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // Initialize Supabase with deep link support
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    debug: true,
  );

  logger.i('Supabase URL: ${dotenv.env['SUPABASE_URL']}');
  logger.i('Supabase initialized successfully');

  // Initialize PostHog

  final config = PostHogConfig(dotenv.env['POSTHOG_API_KEY']!);
  config.host = 'https://us.i.posthog.com';
  config.debug = true;

  await Posthog().setup(config);
  logger.i('PostHog initialized successfully');

  final translationsService = TranslationsService();
  await translationsService.loadTranslations();
  await translationsService.loadLanguages();

  final settingsState = June.getState(() => SettingsState());
  await settingsState.initializeData();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final appRouter = router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final settingsState = June.getState(() => SettingsState());
      settingsState.initializeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return OfflineBuilder(
      connectivityBuilder: (
        BuildContext context,
        List<ConnectivityResult> connectivity,
        Widget child,
      ) {
        final bool connected = !connectivity.contains(ConnectivityResult.none);

        if (connected) {
          return JuneBuilder(
            () => SettingsState(),
            builder: (settingsState) {
              if (settingsState.isLoading) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: lightTheme,
                  darkTheme: darkTheme,
                  home: Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              return JuneBuilder(
                () => TranslationsService(),
                builder: (translationsService) {
                  return MaterialApp.router(
                    theme: lightTheme,
                    darkTheme: darkTheme,
                    themeMode:
                        settingsState.userPreferences.darkMode
                            ? ThemeMode.dark
                            : ThemeMode.light,
                    title: translationsService.translate('app.title'),
                    debugShowCheckedModeBanner: false,
                    routerConfig: appRouter,
                    localizationsDelegates: const [
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: const [Locale('en'), Locale('es')],
                    locale: translationsService.currentLocale,
                  );
                },
              );
            },
          );
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 90,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.translate('offline.message'),
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.translate('offline.description'),
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.cloud_off_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(context.translate('offline.message')),
          Text(context.translate('offline.description')),
        ],
      ),
    );
  }
}
