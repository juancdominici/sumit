import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sumit/models/group.dart';
import 'package:sumit/router.dart';
import 'package:sumit/screens/groups/join_group_sheet.dart';
import 'package:sumit/utils.dart';
import 'package:sumit/utils/translations_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sumit/utils/flushbar_helper.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  bool _isLoading = true;
  String? _error;
  List<Group> _groups = [];
  final _renameController = TextEditingController();
  bool _hideDeletedGroups = true; // Default to hiding deleted groups

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception(context.translate("auth.error.not_authenticated"));
      }
      final response = await Supabase.instance.client
          .from('group_members')
          .select('group:groups(*)')
          .eq('user_id', userId);

      _groups =
          (response as List)
              .map(
                (item) => Group.fromJson(item['group'] as Map<String, dynamic>),
              )
              .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _copyInviteCode(String groupId) async {
    await Clipboard.setData(ClipboardData(text: groupId));
    if (mounted) {
      AppFlushbar.info(
        context: context,
        message: context.translate("groups.invite_code_copied"),
      ).show(context);
    }
  }

  Future<void> _deleteGroup(Group group) async {
    try {
      logger.d('Attempting to logically delete group with ID: ${group.id}');

      // Set the deleted timestamp instead of physically deleting

      final result = await Supabase.instance.client
          .from('groups')
          .update({'deleted': DateTime.now().toUtc().toIso8601String()})
          .eq('id', group.id);

      logger.d('Group logical deletion result: $result');

      await _loadGroups();
      if (mounted) {
        AppFlushbar.success(
          context: context,
          message: context.translate("groups.deleted"),
        ).show(context);
        Navigator.of(context).pop();
      }
    } catch (e) {
      logger.e('Error deleting group: $e');
      if (mounted) {
        AppFlushbar.error(
          context: context,
          message: "${context.translate("common.error_occurred")}: $e",
        ).show(context);
      }
    }
  }

  Future<void> _showDeleteConfirmation(Group group) async {
    logger.d('Showing delete confirmation for group: ${group.groupName}');
    await showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Text(context.translate("groups.delete_confirmation_title")),
            content: Text(
              context.translate("groups.delete_confirmation_message"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.translate("common.cancel")),
              ),
              TextButton(
                onPressed: () async {
                  logger.d('Delete button pressed');
                  await _deleteGroup(group);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(context.translate("common.delete")),
              ),
            ],
          ),
    );
    logger.d('Delete confirmation dialog closed');
  }

  Future<void> _renameGroup(Group group) async {
    _renameController.text = group.groupName;
    await showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Text(context.translate("groups.rename_title")),
            content: TextField(
              controller: _renameController,
              decoration: InputDecoration(
                labelText: context.translate("groups.name"),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.translate("common.cancel")),
              ),
              TextButton(
                onPressed: () async {
                  final newName = _renameController.text;
                  if (newName.isNotEmpty) {
                    await _updateGroupName(group, newName);
                  }
                },
                child: Text(context.translate("common.save")),
              ),
            ],
          ),
    );
  }

  Future<void> _updateGroupName(Group group, String newName) async {
    try {
      await Supabase.instance.client
          .from('groups')
          .update({'group_name': newName})
          .eq('id', group.id);
      await _loadGroups();
      if (mounted) {
        AppFlushbar.info(
          context: context,
          message: context.translate("groups.renamed"),
        ).show(context);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppFlushbar.error(
          context: context,
          message: context.translate("common.error_occurred"),
        ).show(context);
      }
    }
  }

  void _showJoinGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JoinGroupSheet(onGroupJoined: _loadGroups),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredGroups =
        _hideDeletedGroups
            ? _groups.where((group) => group.deleted == null).toList()
            : _groups;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate("groups.title")),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: PopupMenuThemeData(
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                position: PopupMenuPosition.under,
                elevation: 0,
                offset: const Offset(0, 8),
                constraints: const BoxConstraints(minWidth: 220),
                onSelected: (value) {
                  if (value == 'toggle_deleted') {
                    setState(() {
                      _hideDeletedGroups = !_hideDeletedGroups;
                    });
                  }
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem<String>(
                        padding: EdgeInsets.zero,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.all(4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: PopupMenuItem(
                              height: 48,
                              value: 'toggle_deleted',
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _hideDeletedGroups
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _hideDeletedGroups
                                          ? context.translate(
                                            "groups.show_deleted",
                                          )
                                          : context.translate(
                                            "groups.hide_deleted",
                                          ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.translate("common.error_occurred"),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadGroups,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                            ),
                            child: Text(
                              context.translate("common.retry"),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    )
                    : filteredGroups.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_off,
                            size: 80,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.translate("groups.empty"),
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadGroups,
                      child: ListView(
                        children: [
                          // Owner Groups Section
                          if (filteredGroups.any(
                            (g) =>
                                g.groupOwner ==
                                Supabase.instance.client.auth.currentUser?.id,
                          )) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                              child: Text(
                                context.translate("groups.your_groups"),
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...filteredGroups
                                .where(
                                  (g) =>
                                      g.groupOwner ==
                                      Supabase
                                          .instance
                                          .client
                                          .auth
                                          .currentUser
                                          ?.id,
                                )
                                .map((group) => _buildGroupTile(group)),
                          ],

                          // Add divider only if both sections exist
                          if (filteredGroups.any(
                                (g) =>
                                    g.groupOwner ==
                                    Supabase
                                        .instance
                                        .client
                                        .auth
                                        .currentUser
                                        ?.id,
                              ) &&
                              filteredGroups.any(
                                (g) =>
                                    g.groupOwner !=
                                    Supabase
                                        .instance
                                        .client
                                        .auth
                                        .currentUser
                                        ?.id,
                              ))
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              child: Divider(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.3),
                              ),
                            ),

                          // Member Groups Section
                          if (filteredGroups.any(
                            (g) =>
                                g.groupOwner !=
                                Supabase.instance.client.auth.currentUser?.id,
                          )) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                              child: Text(
                                context.translate("groups.other_groups"),
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...filteredGroups
                                .where(
                                  (g) =>
                                      g.groupOwner !=
                                      Supabase
                                          .instance
                                          .client
                                          .auth
                                          .currentUser
                                          ?.id,
                                )
                                .map((group) => _buildGroupTile(group)),
                          ],
                        ],
                      ),
                    ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final result = await router.push(
                      '/group-creation?fromList=true',
                    );
                    // If a group was created (result is true), refresh the list
                    if (result == true) {
                      _loadGroups();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    elevation: 1,
                  ),
                  child: Text(
                    context.translate("groups.create"),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _showJoinGroupSheet,
                  icon: Icon(
                    Icons.add_link,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    context.translate("groups.join_existing"),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTile(Group group) {
    final isOwner =
        group.groupOwner == Supabase.instance.client.auth.currentUser?.id;
    final isDeleted = group.deleted != null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        group.groupName,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color:
              isDeleted
                  ? Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5)
                  : null,
        ),
      ),
      subtitle: Text(
        isDeleted
            ? context.translate("groups.deleted_status")
            : isOwner
            ? context.translate("groups.owner")
            : context.translate("groups.member"),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing:
          isDeleted
              ? null
              : Theme(
                data: Theme.of(context).copyWith(
                  popupMenuTheme: PopupMenuThemeData(
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  position: PopupMenuPosition.under,
                  elevation: 0,
                  offset: const Offset(0, 8),
                  constraints: const BoxConstraints(minWidth: 200),
                  onSelected: (value) {
                    switch (value) {
                      case 'copy':
                        _copyInviteCode(group.id);
                        break;
                      case 'rename':
                        if (isOwner) _renameGroup(group);
                        break;
                      case 'delete':
                        if (isOwner) {
                          _showDeleteConfirmation(group);
                        }
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem<String>(
                          padding: EdgeInsets.zero,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.2),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: const EdgeInsets.all(4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PopupMenuItem(
                                    height: 48,
                                    value: 'copy',
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.copy,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            context.translate(
                                              "groups.copy_invite",
                                            ),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.copyWith(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isOwner) ...[
                                    const Divider(
                                      height: 1,
                                      indent: 16,
                                      endIndent: 16,
                                    ),
                                    PopupMenuItem(
                                      height: 48,
                                      value: 'rename',
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              context.translate(
                                                "groups.rename",
                                              ),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.copyWith(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      height: 48,
                                      value: 'delete',
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              context.translate(
                                                "groups.delete",
                                              ),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.copyWith(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.error,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                ),
              ),
    );
  }
}
