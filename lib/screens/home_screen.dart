import 'package:flutter/material.dart';
import 'package:june/june.dart';
import 'package:sumit/screens/display.dart';
import 'package:sumit/screens/keypad.dart';
import 'package:sumit/screens/calendar_view.dart';
import 'package:sumit/screens/settings/settings_block.dart';
import 'package:sumit/screens/records/record_list_view.dart';
import 'package:sumit/state/module.dart';
import 'package:sumit/utils/translations_extension.dart';
import 'package:sumit/services/translations_service.dart';
import 'package:sumit/utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showCalendar = false;
  bool _showRecordsList = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    final settingsState = June.getState(() => SettingsState());
    if (settingsState.userPreferences.language.isNotEmpty) {
      try {
        final language = settingsState.languages.firstWhere(
          (l) => l.id == settingsState.userPreferences.language,
        );
        TranslationsService().setLocale(language.i18nCode);
      } catch (e) {
        logger.e('Error setting locale from preferences: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        actionsPadding: const EdgeInsets.only(right: 24.0),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 10.0, 0, 10.0),
            child: IconButton(
              icon: Icon(
                _showRecordsList ? Icons.home : Icons.list,
                color: Theme.of(context).iconTheme.color,
                size: 38,
              ),
              tooltip:
                  _showRecordsList
                      ? context.translate('records.show_home')
                      : context.translate('records.show_list'),
              onPressed: () {
                setState(() {
                  _showRecordsList = !_showRecordsList;
                  final recordsState = June.getState(() => RecordsState());
                  recordsState.fetchRecords();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: IconButton(
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).iconTheme.color,
                size: 38,
              ),
              tooltip: context.translate('settings.title'),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Container(
                      height: 400,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).bottomSheetTheme.backgroundColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[SettingsBlock()],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      body:
          _showRecordsList
              ? const RecordListView()
              : JuneBuilder(
                () => DisplayState(),
                builder:
                    (vm) => Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Display(
                          openCalendar:
                              () => setState(() {
                                _showCalendar = !_showCalendar;
                              }),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (
                              Widget child,
                              Animation<double> animation,
                            ) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(
                                    _showCalendar ? -1.0 : 1.0,
                                    0.0,
                                  ),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              );
                            },
                            child:
                                !isKeyboardVisible
                                    ? (_showCalendar
                                        ? const CalendarView(
                                          key: ValueKey('calendar'),
                                        )
                                        : const Keypad(key: ValueKey('keypad')))
                                    : const SizedBox(
                                      height: 0,
                                      key: ValueKey('empty'),
                                    ),
                          ),
                        ),
                      ],
                    ),
              ),
    );
  }
}

bool isSameDay(DateTime? dateA, DateTime dateB) {
  if (dateA == null) return false;
  return dateA.year == dateB.year &&
      dateA.month == dateB.month &&
      dateA.day == dateB.day;
}
