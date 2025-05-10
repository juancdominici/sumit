import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:june/june.dart';
import 'package:sumit/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sumit/models/language.dart';

class TranslationsService extends JuneState {
  static final TranslationsService _instance = TranslationsService._internal();
  factory TranslationsService() => _instance;
  TranslationsService._internal();

  Map<String, dynamic> _translations = {};
  Locale _currentLocale = const Locale('en');

  // Cached list of languages
  List<Language> _languages = [];
  List<Language> get languages => _languages;

  Locale get currentLocale => _currentLocale;

  Future<void> loadTranslations() async {
    try {
      final String enJson = await rootBundle.loadString(
        'assets/translations/en.json',
      );
      final String esJson = await rootBundle.loadString(
        'assets/translations/es.json',
      );

      _translations = {'en': json.decode(enJson), 'es': json.decode(esJson)};
      logger.i('Translations loaded successfully');
      setState();
    } catch (e) {
      logger.e('Error loading translations: $e');
    }
  }

  // Fetch and cache languages from Supabase
  Future<void> loadLanguages() async {
    try {
      final response = await Supabase.instance.client
          .from('languages')
          .select()
          .order('name');
      _languages =
          (response as List).map((json) => Language.fromJson(json)).toList();
      logger.i(
        'Languages loaded: \\${_languages.map((l) => l.i18nCode).toList()}',
      );
      setState();
    } catch (e) {
      logger.e('Error loading languages: $e');
    }
  }

  String translate(String key, {Map<String, String>? args}) {
    final keys = key.split('.');
    dynamic value = _translations[_currentLocale.languageCode];

    for (final k in keys) {
      if (value is Map) {
        value = value[k];
      } else {
        return key;
      }
    }

    if (value == null) {
      return key;
    }

    if (args != null) {
      String translated = value.toString();
      args.forEach((key, value) {
        translated = translated.replaceAll('{$key}', value);
      });
      return translated;
    }

    return value.toString();
  }

  void setLocale(String languageCode) {
    logger.i(
      'Setting locale to: $languageCode (current: ${_currentLocale.languageCode})',
    );
    if (_currentLocale.languageCode != languageCode) {
      _currentLocale = Locale(languageCode);
      logger.i('Locale changed to: $languageCode');
      setState();
    }
  }
}
