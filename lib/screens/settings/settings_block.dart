import 'package:flutter/material.dart';
import 'package:june/june.dart';
import 'package:sumit/router.dart';
import 'package:sumit/state/module.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumit/utils/translations_extension.dart';
import 'package:sumit/services/version_service.dart';
import 'package:sumit/utils/flushbar_helper.dart';

class SettingsBlock extends StatefulWidget {
  const SettingsBlock({super.key});

  @override
  State<SettingsBlock> createState() => _SettingsBlockState();
}

class _SettingsBlockState extends State<SettingsBlock> {
  bool _defaultNegative = false;
  final _prefs = SharedPreferences.getInstance();
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadVersion();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _prefs;
    setState(() {
      _defaultNegative = prefs.getBool('default_negative') ?? false;
    });
  }

  Future<void> _loadVersion() async {
    final version = await VersionService.getVersionString();
    setState(() {
      _version = version;
    });
  }

  Future<void> _toggleDefaultOperator(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool('default_negative', value);
    setState(() {
      _defaultNegative = value;
    });
  }

  void _showSelectionSheet({
    required BuildContext context,
    required SettingsState settingsState,
    required String title,
    required Widget content,
  }) {
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
                    title: Text(title),
                    leading: CloseButton(),
                    backgroundColor: Colors.transparent,
                    centerTitle: true,
                  ),
                ),
                Expanded(child: content),
              ],
            ),
          ),
    );
  }

  void _showCurrencyPicker(BuildContext context, SettingsState settingsState) {
    _showSelectionSheet(
      context: context,
      settingsState: settingsState,
      title: context.translate('settings.selectCountryCurrency'),
      content: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              onChanged: settingsState.updateCurrencySearch,
              decoration: InputDecoration(
                hintText: context.translate('settings.searchCountryCurrency'),
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
                    return ListTile(
                      title: Text(currency.country),
                      subtitle: Text(
                        '${currency.currency} - ${currency.currencyName}',
                      ),
                      selected:
                          settingsState.userPreferences.currency == currency.id,
                      onTap: () async {
                        try {
                          await settingsState.updatePreferences(
                            currency: currency.id,
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          AppFlushbar.error(
                            context: context,
                            message: context.translate(
                              'settings.error.updateCurrency',
                              args: {'error': e.toString()},
                            ),
                          ).show(context);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsState settingsState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Column(
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
                  title: Text(context.translate('settings.selectLanguage')),
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
                    return ListTile(
                      title: Text(
                        context.translate(
                          'settings.languages.${language.i18nCode}',
                        ),
                      ),
                      selected:
                          settingsState.userPreferences.language == language.id,
                      onTap: () async {
                        try {
                          await settingsState.updatePreferences(
                            language: language.id,
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          AppFlushbar.error(
                            context: context,
                            message: context.translate(
                              'settings.error.updateLanguage',
                              args: {'error': e.toString()},
                            ),
                          ).show(context);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return JuneBuilder(
      () => SettingsState(),
      builder: (settingsState) {
        if (settingsState.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amberAccent),
            ),
          );
        }

        if (settingsState.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  settingsState.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final state = June.getState(() => SettingsState());
                    state.initializeData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                  ),
                  child: Text(context.translate('settings.retry')),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            SwitchListTile(
              title: Text(
                context.translate('settings.defaultExpense'),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              subtitle: Text(
                context.translate('settings.defaultExpenseSubtitle'),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              value: _defaultNegative,
              onChanged: _toggleDefaultOperator,
            ),
            SwitchListTile(
              title: Text(
                context.translate('settings.darkMode'),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              subtitle: Text(
                context.translate('settings.darkModeSubtitle'),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              value: settingsState.userPreferences.darkMode,
              onChanged: (value) async {
                try {
                  await settingsState.updatePreferences(darkMode: value);
                } catch (e) {
                  if (mounted) {
                    AppFlushbar.error(
                      context: context,
                      message: context.translate(
                        'settings.error.updatePreferences',
                        args: {'error': e.toString()},
                      ),
                    ).show(context);
                  }
                }
              },
            ),
            ListTile(
              title: Text(
                context.translate('settings.currency'),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              subtitle: Text(
                settingsState.selectedCurrency != null
                    ? '${settingsState.selectedCurrency!.currency} - ${settingsState.selectedCurrency!.country}'
                    : context.translate('settings.currencySubtitle'),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).iconTheme.color,
              ),
              onTap: () => _showCurrencyPicker(context, settingsState),
            ),
            ListTile(
              title: Text(
                context.translate('settings.language'),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              subtitle: Text(
                settingsState.languages
                        .where(
                          (l) => l.id == settingsState.userPreferences.language,
                        )
                        .map(
                          (l) => context.translate(
                            'settings.languages.${l.i18nCode}',
                          ),
                        )
                        .firstOrNull ??
                    context.translate('settings.languageSubtitle'),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).iconTheme.color,
              ),
              onTap: () => _showLanguagePicker(context, settingsState),
            ),
            ListTile(
              title: Text(
                context.translate('settings.logout'),
                style: TextStyle(color: Colors.red.shade900),
              ),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                router.go('/login');
              },
            ),
            ListTile(
              title: Text(
                'v$_version',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.5),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        );
      },
    );
  }
}
