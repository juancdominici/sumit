import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
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
import 'package:sumit/router.dart';

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
        toolbarHeight: 100,
        actionsPadding: const EdgeInsets.only(right: 24.0),
        title:
            _showRecordsList ? Text(context.translate("records.title")) : null,
        actions: [
          SpeedDial(
            icon: Icons.more_horiz,
            activeIcon: Icons.close_rounded,
            iconTheme: IconThemeData(size: 36),
            buttonSize: const Size(60, 60),
            shape: const CircleBorder(),
            direction: SpeedDialDirection.down,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0),
            activeBackgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.2),
            foregroundColor: Theme.of(context).colorScheme.primary,
            overlayColor: Theme.of(context).colorScheme.surface,
            spacing: 12,
            spaceBetweenChildren: 8,
            elevation: 0,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.group),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
                foregroundColor: Theme.of(context).colorScheme.primary,
                label: context.translate("groups.title"),
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
                labelShadow: const [],
                labelBackgroundColor: Colors.transparent,
                shape: const CircleBorder(),
                elevation: 0,
                onTap: () => router.push('/groups'),
              ),
              SpeedDialChild(
                child:
                    _showRecordsList
                        ? const Icon(Icons.home)
                        : const Icon(Icons.list),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
                foregroundColor: Theme.of(context).colorScheme.primary,
                label:
                    _showRecordsList
                        ? context.translate("records.show_home")
                        : context.translate("records.show_list"),
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
                labelShadow: const [],
                labelBackgroundColor: Colors.transparent,
                shape: const CircleBorder(),
                elevation: 0,
                onTap:
                    () => setState(() {
                      _showRecordsList = !_showRecordsList;
                    }),
              ),
              SpeedDialChild(
                child: const Icon(Icons.settings),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
                foregroundColor: Theme.of(context).colorScheme.primary,
                label: context.translate("settings.title"),
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
                labelShadow: const [],
                labelBackgroundColor: Colors.transparent,
                shape: const CircleBorder(),
                elevation: 0,
                onTap:
                    () => showModalBottomSheet(
                      context: context,
                      builder:
                          (BuildContext context) => Container(
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).bottomSheetTheme.backgroundColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                  ),
                                  child: Container(
                                    height: 4,
                                    width: 200,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey.shade600
                                              : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(2.5),
                                    ),
                                  ),
                                ),
                                const SettingsBlock(),
                              ],
                            ),
                          ),
                      isDismissible: true,
                      enableDrag: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                    ),
              ),
            ],
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
                        Expanded(
                          child: Display(
                            openCalendar:
                                () => setState(() {
                                  _showCalendar = !_showCalendar;
                                }),
                            calendarOpen: _showCalendar,
                          ),
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
