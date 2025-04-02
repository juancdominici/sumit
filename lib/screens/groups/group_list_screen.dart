import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sumit/models/group.dart';
import 'package:sumit/router.dart';
import 'package:sumit/screens/groups/join_group_sheet.dart';
import 'package:sumit/utils.dart';
import 'package:sumit/utils/translations_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.translate("groups.invite_code_copied"))),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.translate("groups.deleted"))),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      logger.e('Error deleting group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.translate("common.error_occurred")}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.translate("groups.renamed"))),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.translate("common.error_occurred")),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
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
    return Scaffold(
      appBar: AppBar(title: Text(context.translate("groups.title"))),
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
                    : _groups.isEmpty
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
                      child: ListView.builder(
                        itemCount: _groups.length,
                        itemBuilder: (context, index) {
                          final group = _groups[index];
                          final isOwner =
                              group.groupOwner ==
                              Supabase.instance.client.auth.currentUser?.id;
                          final isDeleted = group.deleted != null;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            title: Text(
                              group.groupName,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    isDeleted
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5)
                                        : null,
                              ),
                            ),
                            subtitle: Text(
                              isDeleted
                                  ? context.translate("groups.deleted_status")
                                  : isOwner
                                  ? context.translate("groups.owner")
                                  : context.translate("groups.member"),
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            trailing:
                                isDeleted
                                    ? null
                                    : PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'copy':
                                            _copyInviteCode(group.id);
                                            break;
                                          case 'rename':
                                            if (isOwner) _renameGroup(group);
                                            break;
                                          case 'delete':
                                            if (isOwner)
                                              _showDeleteConfirmation(group);
                                            break;
                                        }
                                      },
                                      itemBuilder:
                                          (context) => [
                                            PopupMenuItem(
                                              value: 'copy',
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.copy),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    context.translate(
                                                      "groups.copy_invite",
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isOwner) ...[
                                              PopupMenuItem(
                                                value: 'rename',
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.edit),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      context.translate(
                                                        "groups.rename",
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete,
                                                      color:
                                                          Theme.of(
                                                            context,
                                                          ).colorScheme.error,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      context.translate(
                                                        "groups.delete",
                                                      ),
                                                      style: TextStyle(
                                                        color:
                                                            Theme.of(
                                                              context,
                                                            ).colorScheme.error,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                    ),
                          );
                        },
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
                  onPressed: () => router.push('/group-creation'),
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
}
