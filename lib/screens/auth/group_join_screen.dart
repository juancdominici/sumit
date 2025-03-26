import 'package:flutter/material.dart';
import 'package:june/june.dart';
import 'package:sumit/router.dart';
import 'package:sumit/utils.dart';
import 'package:sumit/utils/translations_extension.dart';
import 'package:sumit/services/translations_service.dart';
import 'package:sumit/models/group.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupJoinScreen extends StatefulWidget {
  final String groupId;

  const GroupJoinScreen({super.key, required this.groupId});

  @override
  GroupJoinScreenState createState() => GroupJoinScreenState();
}

// TODO: Finish implementing this

class GroupJoinScreenState extends State<GroupJoinScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isJoining = false;
  String? _error;
  Group? _group;

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    try {
      final supabase = Supabase.instance.client;
      final response =
          await supabase
              .from('groups')
              .select()
              .eq('id', widget.groupId)
              .single();

      setState(() {
        _group = Group.fromJson(response);
        _isLoading = false;
      });
    } catch (e) {
      logger.e(e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _joinGroup() async {
    if (_group == null) return;

    setState(() {
      _isJoining = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User not found');
      }

      // Check if user is already a member
      final existingMember =
          await supabase
              .from('group_members')
              .select()
              .eq('group_id', widget.groupId)
              .eq('user_id', user.id)
              .maybeSingle();

      if (existingMember != null) {
        // User is already a member, just navigate to home
        await _navigateWithAnimation('/');
        return;
      }

      // Add user as a member
      final memberData = {
        'group_id': widget.groupId,
        'user_id': user.id,
        'joined_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('group_members').insert(memberData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.translate('auth.group_join.success')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      await _navigateWithAnimation('/');
    } catch (e) {
      logger.e(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _navigateWithAnimation(String route) async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      router.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return JuneBuilder(
      () => TranslationsService(),
      builder:
          (translationsService) => Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Group icon
                      Icon(
                        Icons.group,
                        size: 80,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 24),

                      if (_isLoading) ...[
                        const CircularProgressIndicator(),
                      ] else if (_error != null) ...[
                        Text(
                          _error!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => router.go('/'),
                          child: Text(
                            context.translate('auth.group_join.back_to_home'),
                          ),
                        ),
                      ] else if (_group != null) ...[
                        // Title
                        Text(
                          context.translate('auth.group_join.title'),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Group name
                        Text(
                          _group!.groupName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Join button
                        ElevatedButton(
                          onPressed: _isJoining ? null : _joinGroup,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                          child:
                              _isJoining
                                  ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  )
                                  : Text(
                                    context.translate(
                                      'auth.group_join.join_button',
                                    ),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}
