import 'package:flutter/material.dart';
import 'package:june/june.dart';
import 'package:sumit/models/module.dart';
import 'package:sumit/state/module.dart';
import 'package:sumit/utils.dart';
import 'package:sumit/utils/translations_extension.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sumit/utils/flushbar_helper.dart';

class RecordListView extends StatefulWidget {
  const RecordListView({super.key});

  @override
  State<RecordListView> createState() => _RecordListViewState();
}

class _RecordListViewState extends State<RecordListView>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final Map<String, bool> _expandedFutureSections = {};
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, Animation<double>> _animations = {};
  late TabController _tabController;
  List<Group> _groups = [];
  bool _isLoadingGroups = true;
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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

      // Initialize the tab controller with the correct number of tabs (Personal + groups)
      _tabController = TabController(length: _groups.length + 1, vsync: this);
      _tabController.addListener(_handleTabChange);
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

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        if (_tabController.index == 0) {
          // Personal tab
          _selectedGroupId = null;
        } else {
          // Group tab
          _selectedGroupId = _groups[_tabController.index - 1].id;
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    // Dispose all animation controllers
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final recordsState = June.getState(() => RecordsState());
      recordsState.loadMoreRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return JuneBuilder(
      () => RecordsState(),
      builder: (recordsState) {
        if (_isLoadingGroups || recordsState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // If there are no records at all in the app
        if (recordsState.records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.subject_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  context.translate('records.empty'),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => recordsState.fetchRecords(),
                  icon: const Icon(Icons.refresh),
                  label: Text(context.translate('records.refresh')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Filter records based on the selected group tab
        final filteredRecords =
            _selectedGroupId == null
                ? recordsState.records.where((r) => r.groupId == null).toList()
                : recordsState.records
                    .where((r) => r.groupId == _selectedGroupId)
                    .toList();

        final settingsState = June.getState(() => SettingsState());
        final selectedCurrency = settingsState.selectedCurrency;
        final currencySymbol = selectedCurrency?.currency ?? '\$';
        final currencyFormatter = NumberFormat('#,##0.00 $currencySymbol');

        final recordsByMonth = _getFilteredRecordsByMonth(
          filteredRecords,
          Localizations.localeOf(context),
        );

        final months = recordsByMonth.keys.toList();

        return Column(
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Theme.of(context).colorScheme.primary,
              indicatorColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.7),
              tabs: [
                Tab(text: context.translate('groups.no_group')),
                ..._groups.map((group) => Tab(text: group.groupName)),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await recordsState.fetchRecords();
                },
                child:
                    filteredRecords.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.subject_outlined,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                context.translate(
                                  'records.no_records_in_group',
                                ),
                                style: Theme.of(context).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 8.0),
                          itemCount:
                              months.length +
                              (recordsState.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, monthIndex) {
                            if (monthIndex == months.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final month = months[monthIndex];
                            final monthRecords = recordsByMonth[month]!;

                            return _buildMonthSection(
                              context,
                              month,
                              monthRecords,
                              currencyFormatter,
                              recordsState,
                            );
                          },
                        ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper method to filter records by group and organize by month
  Map<String, List<Record>> _getFilteredRecordsByMonth(
    List<Record> records,
    Locale locale,
  ) {
    final Map<String, List<Record>> groupedRecords = {};
    final String languageCode = locale.languageCode;

    // Filter out deleted records
    final activeRecords = records.where((record) => !record.isDeleted).toList();

    for (var record in activeRecords) {
      final monthYear = DateFormat(
        'MMMM yyyy',
        languageCode,
      ).format(record.date);

      if (!groupedRecords.containsKey(monthYear)) {
        groupedRecords[monthYear] = [];
      }

      groupedRecords[monthYear]!.add(record);
    }

    return groupedRecords;
  }

  Widget _buildSlidableRecord(
    BuildContext context,
    Record record,
    Locale locale,
    NumberFormat currencyFormatter,
    RecordsState recordsState,
  ) {
    return Slidable(
      key: ValueKey(record.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text(
                        record.isRecurring
                            ? context.translate(
                              'records.delete_recurring_title',
                            )
                            : context.translate(
                              'records.delete_confirmation_title',
                            ),
                      ),
                      content: Text(
                        record.isRecurring
                            ? context.translate(
                              'records.delete_recurring_warning',
                            )
                            : context.translate(
                              'records.delete_confirmation_message',
                            ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(context.translate('records.cancel')),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(context.translate('records.delete')),
                        ),
                      ],
                    ),
              );

              if (confirmed == true) {
                try {
                  recordsState.optimisticallyDeleteRecord(record.id);

                  await recordsState.deleteRecord(record.id);

                  AppFlushbar.withAction(
                    context: context,
                    message: context.translate('records.deleted'),
                    mainButton: TextButton(
                      onPressed: () {
                        recordsState.restoreRecord(record);
                      },
                      child: Text(
                        context.translate('records.undo'),
                        style: TextStyle(color: Colors.amber),
                      ),
                    ),
                  ).show(context);
                } catch (e) {
                  recordsState.restoreRecord(record);
                  AppFlushbar.error(
                    context: context,
                    message: context.translate('records.delete_error'),
                  ).show(context);
                }
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: context.translate('records.delete'),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(color: Theme.of(context).cardColor),
        child: _buildRecordCard(context, record, locale, currencyFormatter),
      ),
    );
  }

  Widget _buildRecordCard(
    BuildContext context,
    Record record,
    Locale locale,
    NumberFormat currencyFormatter,
  ) {
    final isExpense = record.isNegative;
    final isFutureRecord = record.date.isAfter(DateTime.now());
    final textColor =
        isFutureRecord
            ? Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withValues(alpha: 0.6)
            : Theme.of(context).textTheme.titleMedium?.color;
    final amountColor =
        isFutureRecord
            ? Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withValues(alpha: 0.6)
            : (isExpense
                ? Colors.redAccent.shade200
                : Colors.greenAccent.shade200);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  record.tag.isEmpty
                      ? context.translate('records.no_tag')
                      : record.tag,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                DateFormat('HH:mm', locale.languageCode).format(record.date),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      isFutureRecord
                          ? Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withValues(alpha: 0.5)
                          : Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (record.isRecurring)
                      Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Icon(
                          Icons.repeat,
                          size: 14.0,
                          color:
                              isFutureRecord
                                  ? Theme.of(context).textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.5)
                                  : Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        _getRecurringText(context, record, locale),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              isFutureRecord
                                  ? Theme.of(context).textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.5)
                                  : Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isExpense ? '-' : ''}${currencyFormatter.format(double.parse(record.isNegative ? record.amountValue : record.amount))}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRecurringText(BuildContext context, Record record, Locale locale) {
    if (!record.isRecurring) {
      return DateFormat('E, MMM d, y', locale.languageCode).format(record.date);
    }

    final now = DateTime.now();
    final isToday =
        record.date.year == now.year &&
        record.date.month == now.month &&
        record.date.day == now.day;

    if (isToday) {
      return context.translate('records.today') != 'records.today'
          ? context.translate('records.today')
          : 'Today';
    }
    final dayFormatter = DateFormat('EEEE', locale.languageCode);
    final shortDayFormatter = DateFormat('E dd', locale.languageCode);

    String shortDayWithSeparator(DateTime date) {
      return "${shortDayFormatter.format(date)} -";
    }

    switch (record.recurringTypeEnum) {
      case RecurringType.daily:
        return "${shortDayWithSeparator(record.date)} ${context.translate('display.recurring.daily')}";
      case RecurringType.weekly:
        return "${shortDayWithSeparator(record.date)} ${context.translate('display.recurring.weekly', args: {'day': dayFormatter.format(record.date)})}";
      case RecurringType.biweekly:
        return "${shortDayWithSeparator(record.date)} ${context.translate('display.recurring.bi_weekly', args: {'day': dayFormatter.format(record.date)})}";
      case RecurringType.monthly:
        return "${shortDayWithSeparator(record.date)} ${context.translate('display.recurring.monthly', args: {'day': DateFormat('d').format(record.date), 'suffix': _getDaySuffix(context, record.date.day, locale)})}";
      case RecurringType.yearly:
        return "${shortDayWithSeparator(record.date)} ${context.translate('display.recurring.yearly', args: {'month': DateFormat('MMMM', locale.languageCode).format(record.date), 'day': DateFormat('d').format(record.date)})}";
      case RecurringType.lastMonthDay:
        return "${shortDayWithSeparator(record.date)} ${context.translate('display.recurring.last_month_day')}";
      case RecurringType.lastBusinessDay:
        return "${shortDayWithSeparator(record.date)} ${context.translate('display.recurring.last_business_day')}";
      default:
        return DateFormat(
          'E, MMM d, y',
          locale.languageCode,
        ).format(record.date);
    }
  }

  String _getDaySuffix(BuildContext context, int day, Locale locale) {
    final String languageCode = locale.languageCode;

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

  double _calculateMonthTotal(List<Record> records, bool expenses) {
    return records
        .where((r) => r.isNegative == expenses)
        .fold(
          0.0,
          (sum, record) =>
              sum + double.parse(expenses ? record.amountValue : record.amount),
        );
  }

  Map<String, _TagStats> _getTagStatistics(List<Record> records) {
    final stats = <String, _TagStats>{};

    for (var record in records) {
      final tag = record.tag.isEmpty ? 'No Tag' : record.tag;
      final amount = double.parse(
        record.isNegative ? record.amountValue : record.amount,
      );

      if (!stats.containsKey(tag)) {
        stats[tag] = _TagStats();
      }

      if (record.isNegative) {
        stats[tag]!.expenses += amount;
        stats[tag]!.expenseCount++;
      } else {
        stats[tag]!.income += amount;
        stats[tag]!.incomeCount++;
      }
      stats[tag]!.totalCount();
    }

    return stats;
  }

  Widget _buildMonthHeader(
    BuildContext context,
    String month,
    List<Record> monthRecords,
    NumberFormat currencyFormatter,
  ) {
    final tagStats = _getTagStatistics(monthRecords);
    final sortedTags =
        tagStats.entries.toList()..sort(
          (a, b) => b.value.totalCount().compareTo(a.value.totalCount()),
        );

    final topTags = sortedTags.take(3).toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),

            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      month,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormatter.format(
                          _calculateMonthTotal(monthRecords, false),
                        ),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.greenAccent.shade200,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currencyFormatter.format(
                          _calculateMonthTotal(monthRecords, true),
                        ),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.redAccent.shade200,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (topTags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  context.translate('records.frequent_tags'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      topTags.map((entry) {
                        final tag = entry.key;
                        final stats = entry.value;
                        final totalAmount = stats.income - stats.expenses;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).cardColor
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).shadowColor.withValues(alpha: 0.03),
                                blurRadius: 1,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    tag,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      stats.totalCount().toString(),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormatter.format(totalAmount),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color:
                                      totalAmount >= 0
                                          ? Colors.greenAccent.shade200
                                          : Colors.redAccent.shade200,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSection(
    BuildContext context,
    String month,
    List<Record> monthRecords,
    NumberFormat currencyFormatter,
    RecordsState recordsState,
  ) {
    final now = DateTime.now();
    final currentRecords =
        monthRecords.where((r) => !r.date.isAfter(now)).toList();
    final futureRecords =
        monthRecords.where((r) => r.date.isAfter(now)).toList();
    final hasFutureRecords = futureRecords.isNotEmpty;
    final isExpanded = _expandedFutureSections[month] ?? false;

    // Create animation controller for this month if it doesn't exist
    if (!_animationControllers.containsKey(month) && hasFutureRecords) {
      _animationControllers[month] = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      _animations[month] = CurvedAnimation(
        parent: _animationControllers[month]!,
        curve: Curves.easeInOut,
      );
    }

    if (hasFutureRecords) {
      if (isExpanded) {
        _animationControllers[month]?.forward();
      } else {
        _animationControllers[month]?.reverse();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMonthHeader(context, month, monthRecords, currencyFormatter),
        Container(
          decoration: BoxDecoration(color: Theme.of(context).cardColor),
          child: Column(
            children: [
              if (hasFutureRecords) ...[
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedFutureSections[month] = !isExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(
                                context,
                              ).cardColor.withValues(alpha: 0.3)
                              : Colors.grey.shade100,
                    ),
                    child: Row(
                      children: [
                        const Spacer(),
                        Text(
                          context.translate(
                            'records.future_records',
                            args: {'count': futureRecords.length.toString()},
                          ),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        const Spacer(),
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: isExpanded ? 0.5 : 0,
                          child: Icon(
                            Icons.expand_more,
                            color: Theme.of(
                              context,
                            ).iconTheme.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizeTransition(
                  sizeFactor: _animations[month]!,
                  child: Column(
                    children:
                        futureRecords
                            .map(
                              (record) => _buildSlidableRecord(
                                context,
                                record,
                                Localizations.localeOf(context),
                                currencyFormatter,
                                recordsState,
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
              ...currentRecords.map(
                (record) => _buildSlidableRecord(
                  context,
                  record,
                  Localizations.localeOf(context),
                  currencyFormatter,
                  recordsState,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TagStats {
  double income = 0;
  double expenses = 0;
  int incomeCount = 0;
  int expenseCount = 0;
  int totalCount() => incomeCount + expenseCount;
}
