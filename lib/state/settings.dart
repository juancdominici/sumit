import 'package:june/june.dart';
import 'package:sumit/models/module.dart';
import 'package:sumit/services/translations_service.dart';
import 'package:sumit/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsState extends JuneState {
  UserPreferences userPreferences = UserPreferences(
    userId: '',
    currency: '',
    darkMode: false,
    language: '',
    hasFirstLogin: false,
    hasCreatedGroup: false,
  );

  List<Currency> currencies = [];
  List<Language> languages = [];
  String _currencySearchQuery = '';
  bool _isLoading = true;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currencySearchQuery => _currencySearchQuery;

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> initializeData() async {
    _isLoading = true;
    _error = null;
    setState();

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _error = 'User not authenticated';
        _isLoading = false;
        setState();
        return;
      }

      await fetchUserPreferences();
      await Future.wait([fetchCurrencies(), fetchLanguages()]);
    } catch (e) {
      _error = 'Error loading settings: $e';
      logger.e(_error);
    } finally {
      _isLoading = false;
      setState();
    }
  }

  List<Currency> get filteredCurrencies {
    if (_currencySearchQuery.isEmpty) return currencies;
    final query = _currencySearchQuery.toLowerCase();
    return currencies
        .where(
          (c) =>
              c.country.toLowerCase().contains(query) ||
              c.currency.toLowerCase().contains(query) ||
              c.currencyName.toLowerCase().contains(query),
        )
        .toList();
  }

  Currency? get selectedCurrency {
    if (userPreferences.currency.isEmpty) return null;
    try {
      return currencies.firstWhere((c) => c.id == userPreferences.currency);
    } catch (e) {
      return null;
    }
  }

  void updateCurrencySearch(String query) {
    _currencySearchQuery = query;
    setState();
  }

  Future<void> fetchUserPreferences() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      var response =
          await Supabase.instance.client
              .from('user_preferences')
              .select()
              .eq('user_id', userId)
              .limit(1)
              .maybeSingle();

      if (response != null) {
        userPreferences = UserPreferences.fromJson(response);
      } else {
        userPreferences = UserPreferences(
          userId: userId,
          currency: '',
          darkMode: false,
          language: '',
          hasFirstLogin: false,
          hasCreatedGroup: false,
        );
        await Supabase.instance.client
            .from('user_preferences')
            .upsert(userPreferences.toJson());
      }
    } catch (e) {
      logger.e('Error fetching user preferences: $e');
      rethrow;
    }
  }

  Future<void> fetchCurrencies() async {
    try {
      final response = await Supabase.instance.client
          .from('currencies')
          .select()
          .order('country', ascending: true);
      currencies =
          (response as List).map((json) => Currency.fromJson(json)).toList();
      setState();
    } catch (e) {
      logger.e('Error fetching currencies: $e');
      rethrow;
    }
  }

  Future<void> fetchLanguages() async {
    try {
      final response = await Supabase.instance.client
          .from('languages')
          .select()
          .order('name');
      languages =
          (response as List).map((json) => Language.fromJson(json)).toList();
      setState();
    } catch (e) {
      logger.e('Error fetching languages: $e');
      rethrow;
    }
  }

  Future<void> updatePreferences({
    bool? darkMode,
    String? currency,
    String? language,
    bool? hasFirstLogin,
    bool? hasCreatedGroup,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    userPreferences = UserPreferences(
      userId: userId,
      darkMode: darkMode ?? userPreferences.darkMode,
      currency: currency ?? userPreferences.currency,
      language: language ?? userPreferences.language,
      hasFirstLogin: hasFirstLogin ?? userPreferences.hasFirstLogin,
      hasCreatedGroup: hasCreatedGroup ?? userPreferences.hasCreatedGroup,
    );

    try {
      await Supabase.instance.client
          .from('user_preferences')
          .upsert(userPreferences.toJson());

      if (language != null && language.isNotEmpty) {
        try {
          final selectedLanguage = languages.firstWhere(
            (l) => l.id == language,
          );
          TranslationsService().setLocale(selectedLanguage.i18nCode);
        } catch (e) {
          logger.e('Error setting language: $e');
        }
      }

      setState();
    } catch (e) {
      logger.e('Error updating preferences: $e');
      rethrow;
    }
  }
}
