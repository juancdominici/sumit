import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:june/june.dart';
import 'package:sumit/state/module.dart';
import 'package:sumit/models/module.dart';
import 'package:sumit/models/group.dart';
import 'package:intl/intl.dart';
import 'package:sumit/utils/translations_extension.dart';
import 'package:sumit/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Display extends StatefulWidget {
  final Function openCalendar;
  const Display({super.key, required this.openCalendar});

  @override
  State<Display> createState() => _DisplayState();
}

class _DisplayState extends State<Display> {
  bool _isExpanded = false;
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _displayController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoadingGroups = false;
  List<Group> _groups = [];
  String? _selectedGroupName;

  @override
  void initState() {
    super.initState();
    _tagController.addListener(_updateTagInState);
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoadingGroups = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('group_members')
          .select('group:groups(*)')
          .eq('user_id', userId);

      _groups =
          (response as List)
              .map(
                (item) => Group.fromJson(item['group'] as Map<String, dynamic>),
              )
              .where((group) => group.deleted == null)
              .toList();

      // Update selected group name if there's a groupId selected
      _updateSelectedGroupName();
    } catch (e) {
      logger.e('Error loading groups: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGroups = false;
        });
      }
    }
  }

  void _updateSelectedGroupName() {
    final displayState = June.getState(() => DisplayState());
    if (displayState.groupId != null && _groups.isNotEmpty) {
      final selectedGroup = _groups.firstWhere(
        (group) => group.id == displayState.groupId,
        orElse: () => _groups[0],
      );
      _selectedGroupName = selectedGroup.groupName;
    } else {
      _selectedGroupName = null;
    }
  }

  void _updateTagInState() {
    final displayState = June.getState(() => DisplayState());
    if (displayState.tagInputValue != _tagController.text) {
      displayState.tagInputValue = _tagController.text;
    }
  }

  void _updateTagFromState(DisplayState displayState) {
    if (_tagController.text != displayState.tagInputValue) {
      _tagController.text = displayState.tagInputValue;

      if (displayState.tagInputValue.isEmpty && _isExpanded) {
        setState(() {
          _isExpanded = false;
        });
        _focusNode.unfocus();
      }
    }
  }

  String _getDateAndRecurringText(DateTime date, RecurringType recurringType) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    if (isToday) {
      return '';
    }

    final dayFormatter = DateFormat(
      'EEEE',
      Localizations.localeOf(context).languageCode,
    );

    String text = '';

    switch (recurringType) {
      case RecurringType.daily:
        text = context.translate('display.recurring.daily');
        break;
      case RecurringType.weekly:
        text = context.translate(
          'display.recurring.weekly',
          args: {'day': dayFormatter.format(date)},
        );
        break;
      case RecurringType.monthly:
        text = context.translate(
          'display.recurring.monthly',
          args: {
            'day': DateFormat('d').format(date),
            'suffix': _getDaySuffix(date.day),
          },
        );
        break;
      case RecurringType.yearly:
        text = context.translate(
          'display.recurring.yearly',
          args: {
            'month': DateFormat(
              'MMMM',
              Localizations.localeOf(context).languageCode,
            ).format(date),
            'day': DateFormat('d').format(date),
          },
        );
        break;
      case RecurringType.none:
        text = DateFormat('dd/MM/yyyy').format(date);
        break;
      case RecurringType.lastMonthDay:
        text = context.translate('display.recurring.last_month_day');
        break;
      case RecurringType.lastBusinessDay:
        text = context.translate('display.recurring.last_business_day');
        break;
      case RecurringType.biweekly:
        text = context.translate(
          'display.recurring.bi_weekly',
          args: {'day': dayFormatter.format(date)},
        );
        break;
    }

    return text;
  }

  String _getDaySuffix(int day) {
    final String languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      if (day >= 11 && day <= 13) {
        return 'th';
      }
      switch (day % 10) {
        case 1:
          return 'st';
        case 2:
          return 'nd';
        case 3:
          return 'rd';
        default:
          return 'th';
      }
    }

    if (languageCode == 'es') {
      return 'º';
    }

    return '';
  }

  bool _shouldShowDot(DateTime date, RecurringType recurringType) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    return !isToday || recurringType != RecurringType.none;
  }

  @override
  void dispose() {
    _tagController.removeListener(_updateTagInState);
    _tagController.dispose();
    _displayController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_focusNode);
      });
    } else {
      _focusNode.unfocus();
    }
  }

  void _showGroupSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => GroupSelectionSheet(
            groups: _groups,
            onGroupSelected: (groupId) {
              final displayState = June.getState(() => DisplayState());
              displayState.setGroupId(groupId);
              setState(() {
                _updateSelectedGroupName();
              });
            },
            selectedGroupId: June.getState(() => DisplayState()).groupId,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DisplayState displayState = June.getState(() => DisplayState());
    if (_displayController.text != displayState.displayValue) {
      _displayController.text = displayState.displayValue;
    }

    _updateTagFromState(displayState);

    return Container(
      height: MediaQuery.of(context).size.height * 0.35,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35 / 3,
            right: 42,
            child: Text(
              displayState.operator == "-"
                  ? context.translate('display.spending')
                  : context.translate('display.earned'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color:
                    displayState.operator == "-"
                        ? Colors.red.shade300
                        : Colors.green.shade300,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 12, 0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * .8,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: IntrinsicWidth(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width * .8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              TextField(
                                controller: _displayController,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]'),
                                  ),
                                  TextInputFormatter.withFunction((
                                    oldValue,
                                    newValue,
                                  ) {
                                    final text = newValue.text;
                                    return text.isEmpty
                                        ? newValue
                                        : double.tryParse(text) == null
                                        ? oldValue
                                        : newValue;
                                  }),
                                ],
                                onChanged: (value) {
                                  displayState.displayValue = value;
                                  displayState.selection = {
                                    'start': value.length,
                                    'end': value.length,
                                  };
                                },
                                keyboardType: TextInputType.none,
                                style: TextStyle(
                                  fontSize: 48,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color ??
                                      Colors.black54,
                                ),
                                textAlign: TextAlign.end,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  _getDateAndRecurringText(
                                    displayState.date,
                                    displayState.recurringExpenseType,
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color ??
                                        Colors.black38,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width: _isExpanded ? 200.0 : 0.0,
                      curve: Curves.easeInOut,
                      child:
                          _isExpanded
                              ? TextField(
                                textAlign: TextAlign.end,
                                maxLength: 20,
                                focusNode: _focusNode,
                                controller: _tagController,
                                decoration: InputDecoration(
                                  hintText: context.translate('display.tag'),
                                  hintStyle: TextStyle(
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                  ),
                                  counterStyle: TextStyle(
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.only(right: 5),
                                  isDense: true,
                                ),
                                onSubmitted: (value) {
                                  FocusScope.of(context).unfocus();
                                },
                              )
                              : null,
                    ),
                    IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.close : Icons.tag,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      iconSize: 32,
                      onPressed: _toggleExpand,
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.calendar_month,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          iconSize: 32,
                          onPressed: () => widget.openCalendar(),
                        ),
                        if (_shouldShowDot(
                          displayState.date,
                          displayState.recurringExpenseType,
                        ))
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.group,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          iconSize: 32,
                          onPressed: _showGroupSelectionSheet,
                        ),
                        if (_selectedGroupName != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GroupSelectionSheet extends StatelessWidget {
  final List<Group> groups;
  final Function(String?) onGroupSelected;
  final String? selectedGroupId;

  const GroupSelectionSheet({
    super.key,
    required this.groups,
    required this.onGroupSelected,
    this.selectedGroupId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  context.translate('groups.select_group'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.group_off,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.translate('groups.empty'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            )
          else
            ListView(
              shrinkWrap: true,
              children: [
                // Option to deselect group
                ListTile(
                  leading: Icon(
                    Icons.person,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  title: Text(context.translate('groups.no_group')),
                  selected: selectedGroupId == null,
                  selectedTileColor:
                      Theme.of(context).colorScheme.surfaceVariant,
                  onTap: () {
                    onGroupSelected(null);
                    Navigator.pop(context);
                  },
                ),
                ...groups.map((group) {
                  return ListTile(
                    leading: Icon(
                      Icons.group,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(group.groupName),
                    selected: group.id == selectedGroupId,
                    selectedTileColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                    onTap: () {
                      onGroupSelected(group.id);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ],
            ),
        ],
      ),
    );
  }
}
