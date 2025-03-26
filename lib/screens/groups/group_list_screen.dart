import 'package:flutter/material.dart';
import 'package:sumit/models/group.dart';
import 'package:sumit/router.dart';
import 'package:sumit/utils/translations_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

// TODO: Implement this
class _GroupListScreenState extends State<GroupListScreen> {
  bool _isLoading = true;
  String? _error;
  List<Group> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get all groups where the user is a member
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.translate("groups.title"))),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadGroups,
                      child: Text(context.translate("common.retry")),
                    ),
                  ],
                ),
              )
              : _groups.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(context.translate("groups.empty")),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => router.push('/group-creation'),
                      child: Text(context.translate("groups.create")),
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
                    return ListTile(
                      title: Text(group.groupName),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Navigate to group details
                      },
                    );
                  },
                ),
              ),
    );
  }
}
