import 'package:flutter/material.dart';
import 'package:june/june.dart';
import 'package:sumit/router.dart';
import 'package:sumit/state/module.dart';
import 'package:sumit/utils.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:sumit/utils/translations_extension.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sumit/services/version_service.dart';
import 'package:sumit/utils/flushbar_helper.dart';
import 'package:sumit/services/translations_service.dart';

class AuthScreen extends StatefulWidget {
  final String? error;
  final bool isCallback;

  const AuthScreen({super.key, this.error, this.isCallback = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
    _loadVersion();

    if (widget.isCallback) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppFlushbar.info(
          context: context,
          message: context.translate('user_verified'),
        ).show(context);
      });
    }
  }

  Future<void> _loadVersion() async {
    final version = await VersionService.getVersionString();
    setState(() {
      _version = version;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Future<void> handleSignIn(AuthResponse response) async {
      if (response.user == null) {
        logger.e('User is null');
        return;
      }
      // Set the user preferences in the june state and initialize data
      final settingsState = June.getState(() => SettingsState());
      await settingsState.initializeData();
      // Let the router handle navigation based on state
    }

    return Scaffold(
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App logo or icon
                      Icon(
                        Icons.account_balance_wallet,
                        size: 80,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      // Title
                      Text(
                        context.translate('auth.welcome'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        context.translate('auth.subtitle'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Auth UI
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Theme(
                          data: theme.copyWith(
                            inputDecorationTheme: InputDecorationTheme(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outline.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outline.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                            ),
                            elevatedButtonTheme: ElevatedButtonThemeData(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 24,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          child: FutureBuilder<bool>(
                            future: Posthog().isFeatureEnabled('magic-auth'),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }

                              final useMagicAuth = snapshot.data ?? false;

                              return useMagicAuth
                                  ? SupaMagicAuth(
                                    redirectUrl: 'ar.com.sumit://auth-callback',
                                    onSuccess: (response) {
                                      logger.i(
                                        'Magic auth complete: $response',
                                      );
                                    },
                                    onError: (error) {
                                      logger.e('Error: $error');
                                    },
                                  )
                                  : SupaEmailAuth(
                                    autofocus: false,
                                    localization: SupaEmailAuthLocalization(
                                      enterEmail: context.translate(
                                        'auth.email.label',
                                      ),
                                      validEmailError: context.translate(
                                        'auth.email.invalid',
                                      ),
                                      enterPassword: context.translate(
                                        'auth.password.label',
                                      ),
                                      passwordLengthError: context.translate(
                                        'auth.password.length_error',
                                      ),
                                      signIn: context.translate(
                                        'auth.signin.button',
                                      ),
                                      signUp: context.translate(
                                        'auth.signup.button',
                                      ),
                                      forgotPassword: context.translate(
                                        'auth.password.forgot',
                                      ),
                                      dontHaveAccount: context.translate(
                                        'auth.signup.cta',
                                      ),
                                      haveAccount: context.translate(
                                        'auth.signin.cta',
                                      ),
                                      sendPasswordReset: context.translate(
                                        'auth.password.reset.send',
                                      ),
                                      backToSignIn: context.translate(
                                        'auth.signin.back',
                                      ),
                                      unexpectedError: context.translate(
                                        'auth.error.unexpected',
                                      ),
                                      passwordResetSent: context.translate(
                                        'auth.password.reset.sent',
                                      ),
                                      requiredFieldError: context.translate(
                                        'auth.required_field_error',
                                      ),
                                    ),
                                    redirectTo: 'ar.com.sumit://auth-callback',
                                    onSignInComplete: (response) {
                                      logger.i('Sign in complete: $response');
                                      handleSignIn(response);
                                    },
                                    onSignUpComplete: (response) {
                                      logger.i('Sign up complete');
                                      if (response.session != null) {
                                        AppFlushbar.success(
                                          context: context,
                                          message: context.translate(
                                            'auth.signup.success',
                                          ),
                                        ).show(context);
                                      }
                                      // Redirect to the sign in screen
                                      router.push('/auth');
                                    },
                                    onError: (error) {
                                      logger.e('Error: $error');
                                      final errorCode =
                                          (error as AuthException).code;
                                      AppFlushbar.error(
                                        context: context,
                                        message: context.translate(
                                          'auth.error.$errorCode',
                                        ),
                                      ).show(context);
                                    },
                                    onPasswordResetEmailSent: () {
                                      logger.i('Password reset email sent');
                                    },
                                    prefixIconEmail: null,
                                    prefixIconPassword: null,
                                  );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      // Place version and locale row at the bottom using bottomNavigationBar
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'v$_version',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            JuneBuilder(
              () => TranslationsService(),
              builder: (translationsService) {
                final languages = translationsService.languages;
                if (languages.isEmpty) {
                  return const SizedBox.shrink();
                }
                final currentLocale =
                    translationsService.currentLocale.languageCode;
                int currentIndex = languages.indexWhere(
                  (l) => l.i18nCode == currentLocale,
                );
                if (currentIndex == -1) currentIndex = 0;
                final currentLanguage = languages[currentIndex];
                final languageName = context.translate(
                  'settings.languages.${currentLanguage.i18nCode}',
                );
                return TextButton.icon(
                  icon: const Icon(Icons.language),
                  label: Text(languageName),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    final nextIndex = (currentIndex + 1) % languages.length;
                    final nextLanguage = languages[nextIndex];
                    translationsService.setLocale(nextLanguage.i18nCode);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
