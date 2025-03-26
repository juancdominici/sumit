import 'package:flutter/material.dart';
import '../services/translations_service.dart';

extension TranslationsExtension on BuildContext {
  String translate(String key, {Map<String, String>? args}) {
    return TranslationsService().translate(key, args: args);
  }
}
