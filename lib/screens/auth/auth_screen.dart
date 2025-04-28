import 'package:flutter/material.dart';
import 'package:june/june.dart';
import 'package:sumit/router.dart';
import 'package:sumit/state/module.dart';
import 'package:sumit/utils.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:sumit/utils/translations_extension.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sumit/services/version_service.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.translate('user_verified'))),
        );
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
                      const SizedBox(height: 24),

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
                                    redirectTo: 'ar.com.sumit://auth-callback',
                                    onSignInComplete: (response) {
                                      logger.i('Sign in complete: $response');
                                      handleSignIn(response);
                                    },
                                    onSignUpComplete: (response) {
                                      logger.i('Sign up complete');
                                      if (response.session != null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              context.translate(
                                                'auth.signup.success',
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      // Redirect to the sign in screen
                                      router.push('/auth');
                                    },
                                    onError: (error) {
                                      logger.e('Error: $error');
                                      final errorCode =
                                          (error as AuthException).code;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            context.translate(
                                              'auth.error.$errorCode',
                                            ),
                                          ),
                                        ),
                                      );
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
                      // Version number
                      Text(
                        'v$_version',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
