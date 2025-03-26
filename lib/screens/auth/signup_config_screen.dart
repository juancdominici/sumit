import 'package:flutter/material.dart';
import 'package:june/june.dart';
import 'package:sumit/router.dart';
import 'package:sumit/state/module.dart';
import 'package:sumit/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sumit/utils/translations_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumit/services/translations_service.dart';

class SignupConfigScreen extends StatefulWidget {
  const SignupConfigScreen({super.key});

  @override
  SignupConfigScreenState createState() => SignupConfigScreenState();
}

class SignupConfigScreenState extends State<SignupConfigScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isDataLoading = true;
  bool _defaultToExpense = false;
  bool _darkMode = false;
  String _selectedCurrency = 'USD';
  String _selectedLanguage = 'en';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final _prefs = SharedPreferences.getInstance();

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

    // Show welcome message when user arrives after email verification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize settings data
      _loadSettings();
      _loadPreferences();
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await _prefs;
    setState(() {
      _defaultToExpense = prefs.getBool('default_negative') ?? false;
    });
  }

  Future<void> _toggleDefaultToExpense(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool('default_negative', value);
    setState(() {
      _defaultToExpense = value;
    });
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isDataLoading = true;
    });

    final settingsState = June.getState(() => SettingsState());
    try {
      // Only initialize if not already loaded
      if (settingsState.isLoading) {
        await settingsState.initializeData();
      }
      // Initialize dark mode from settings state
      setState(() {
        _darkMode = settingsState.userPreferences.darkMode;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings data: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDataLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveUserPreferences() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not found!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Save to Supabase
      await supabase.from('user_preferences').upsert({
        'user_id': user.id,
        'dark_mode': _darkMode,
        'currency': _selectedCurrency,
        'language': _selectedLanguage,
        'first_login': true,
      });

      // Save default_to_expense to shared preferences
      final prefs = await _prefs;
      await prefs.setBool('default_negative', _defaultToExpense);

      // Update settings state
      final settingsState = June.getState(() => SettingsState());
      await settingsState.updatePreferences(
        darkMode: _darkMode,
        currency: _selectedCurrency,
        language: _selectedLanguage,
        hasFirstLogin: true,
      );

      await _navigateWithAnimation('/group-creation');
    } catch (e) {
      logger.e(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateWithAnimation(String route) async {
    // Replace the current slide animation
    setState(() {
      _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );
      _slideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0, -1.0),
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInCubic,
        ),
      );
    });

    // Play exit animation
    _animationController.forward(from: 0);

    // Wait for animation to complete
    await Future.delayed(_animationController.duration!);

    // Navigate to the destination
    if (mounted) {
      router.go(route);
    }
  }

  void _showCurrencyPicker(BuildContext context, SettingsState settingsState) {
    if (settingsState.currencies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.translate('settings.error.noCurrencies')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadSettings();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 4,
                  width: 32,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: AppBar(
                    title: Text(
                      context.translate('settings.selectCountryCurrency'),
                    ),
                    leading: CloseButton(),
                    backgroundColor: Colors.transparent,
                    centerTitle: true,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    onChanged: settingsState.updateCurrencySearch,
                    decoration: InputDecoration(
                      hintText: context.translate(
                        'settings.searchCountryCurrency',
                      ),
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: settingsState,
                    builder: (context, _) {
                      final currencies = settingsState.filteredCurrencies;
                      return ListView.builder(
                        itemCount: currencies.length,
                        itemBuilder: (context, index) {
                          final currency = currencies[index];
                          final isSelected = _selectedCurrency == currency.id;
                          return ListTile(
                            title: Text(currency.country),
                            subtitle: Text(
                              '${currency.currency} - ${currency.currencyName}',
                            ),
                            selected: isSelected,
                            trailing:
                                isSelected
                                    ? Icon(
                                      Icons.check,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    )
                                    : null,
                            onTap: () {
                              setState(() {
                                _selectedCurrency = currency.id;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsState settingsState) {
    if (settingsState.languages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.translate('settings.error.noLanguages')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadSettings();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => JuneBuilder(
            () => TranslationsService(),
            builder:
                (translationsService) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      height: 4,
                      width: 32,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade600
                                : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: AppBar(
                        title: Text(
                          context.translate('settings.selectLanguage'),
                        ),
                        leading: CloseButton(),
                        backgroundColor: Colors.transparent,
                        centerTitle: true,
                      ),
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: settingsState.languages.length,
                        itemBuilder: (context, index) {
                          final language = settingsState.languages[index];
                          final isSelected = _selectedLanguage == language.id;
                          return ListTile(
                            title: Text(
                              context.translate(
                                'settings.languages.${language.i18nCode}',
                              ),
                            ),
                            selected: isSelected,
                            trailing:
                                isSelected
                                    ? Icon(
                                      Icons.check,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    )
                                    : null,
                            onTap: () {
                              setState(() {
                                _selectedLanguage = language.id;
                              });
                              // Update the app's locale immediately and trigger a rebuild
                              translationsService.setLocale(language.i18nCode);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  // Get currency display text for the selected currency
  String _getCurrencyDisplayText(SettingsState settingsState) {
    if (_selectedCurrency.isEmpty || settingsState.currencies.isEmpty) {
      return context.translate('settings.currencySubtitle');
    }

    final selectedCurrency =
        settingsState.currencies
            .where((c) => c.id == _selectedCurrency)
            .firstOrNull;
    if (selectedCurrency != null) {
      return '${selectedCurrency.currency} - ${selectedCurrency.currencyName}';
    }

    return context.translate('settings.currencySubtitle');
  }

  // Get language display text for the selected language
  String _getLanguageDisplayText(SettingsState settingsState) {
    if (_selectedLanguage.isEmpty || settingsState.languages.isEmpty) {
      return context.translate('settings.languageSubtitle');
    }

    final selectedLanguage =
        settingsState.languages
            .where((l) => l.id == _selectedLanguage)
            .firstOrNull;
    if (selectedLanguage != null) {
      return context.translate(
        'settings.languages.${selectedLanguage.i18nCode}',
      );
    }

    return context.translate('settings.languageSubtitle');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return JuneBuilder(
      () => TranslationsService(),
      builder:
          (translationsService) => JuneBuilder(
            () => SettingsState(),
            builder:
                (settingsState) => Scaffold(
                  body: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SafeArea(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                      context.translate(
                                        'auth.signup_config.title',
                                      ),
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),

                                    // Subtitle
                                    Text(
                                      context.translate(
                                        'auth.signup_config.subtitle',
                                      ),
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.7),
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 48),

                                    // Currency Selection
                                    Card(
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: theme.colorScheme.outline
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      margin: EdgeInsets.zero,
                                      child: ListTile(
                                        title: Text(
                                          context.translate(
                                            'settings.currency',
                                          ),
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        subtitle:
                                            _isDataLoading
                                                ? Row(
                                                  children: [
                                                    SizedBox(
                                                      height: 12,
                                                      width: 12,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                theme
                                                                    .colorScheme
                                                                    .primary,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      context.translate(
                                                        'settings.loading',
                                                      ),
                                                      style:
                                                          theme
                                                              .textTheme
                                                              .bodySmall,
                                                    ),
                                                  ],
                                                )
                                                : Text(
                                                  _getCurrencyDisplayText(
                                                    settingsState,
                                                  ),
                                                  style:
                                                      theme.textTheme.bodySmall,
                                                ),
                                        trailing: Icon(
                                          Icons.chevron_right,
                                          color: theme.iconTheme.color,
                                        ),
                                        onTap:
                                            _isDataLoading
                                                ? null
                                                : () => _showCurrencyPicker(
                                                  context,
                                                  settingsState,
                                                ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Language Selection
                                    Card(
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: theme.colorScheme.outline
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      margin: EdgeInsets.zero,
                                      child: ListTile(
                                        title: Text(
                                          context.translate(
                                            'settings.language',
                                          ),
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        subtitle:
                                            _isDataLoading
                                                ? Row(
                                                  children: [
                                                    SizedBox(
                                                      height: 12,
                                                      width: 12,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                theme
                                                                    .colorScheme
                                                                    .primary,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      context.translate(
                                                        'settings.loading',
                                                      ),
                                                      style:
                                                          theme
                                                              .textTheme
                                                              .bodySmall,
                                                    ),
                                                  ],
                                                )
                                                : Text(
                                                  _getLanguageDisplayText(
                                                    settingsState,
                                                  ),
                                                  style:
                                                      theme.textTheme.bodySmall,
                                                ),
                                        trailing: Icon(
                                          Icons.chevron_right,
                                          color: theme.iconTheme.color,
                                        ),
                                        onTap:
                                            _isDataLoading
                                                ? null
                                                : () => _showLanguagePicker(
                                                  context,
                                                  settingsState,
                                                ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Dark Mode
                                    SwitchListTile(
                                      title: Text(
                                        context.translate('settings.darkMode'),
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      subtitle: Text(
                                        context.translate(
                                          'settings.darkModeSubtitle',
                                        ),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      value: _darkMode,
                                      onChanged: (value) async {
                                        setState(() {
                                          _darkMode = value;
                                        });
                                        // Update settings state immediately
                                        await settingsState.updatePreferences(
                                          darkMode: value,
                                        );
                                      },
                                      activeColor: theme.colorScheme.primary,
                                    ),

                                    // Default to Expense
                                    SwitchListTile(
                                      title: Text(
                                        context.translate(
                                          'settings.defaultExpense',
                                        ),
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      subtitle: Text(
                                        context.translate(
                                          'settings.defaultExpenseSubtitle',
                                        ),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      value: _defaultToExpense,
                                      onChanged: _toggleDefaultToExpense,
                                      activeColor: theme.colorScheme.primary,
                                    ),

                                    const SizedBox(height: 24),

                                    // Finish button
                                    ElevatedButton(
                                      onPressed:
                                          _isLoading
                                              ? null
                                              : _saveUserPreferences,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        backgroundColor:
                                            theme.colorScheme.primary,
                                        foregroundColor:
                                            theme.colorScheme.onPrimary,
                                      ),
                                      child:
                                          _isLoading
                                              ? SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color:
                                                          theme
                                                              .colorScheme
                                                              .onPrimary,
                                                    ),
                                              )
                                              : Text(
                                                context.translate(
                                                  'auth.signup_config.finishButton',
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
