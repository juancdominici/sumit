import 'package:flutter/material.dart';
import 'package:june/june.dart';
import 'package:sumit/state/module.dart';
import 'package:sumit/utils.dart';
import 'package:sumit/utils/translations_extension.dart';
import 'package:sumit/router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupJoinScreen extends StatefulWidget {
  final String groupId;

  const GroupJoinScreen({super.key, required this.groupId});

  @override
  State<GroupJoinScreen> createState() => _GroupJoinScreenState();
}

class _GroupJoinScreenState extends State<GroupJoinScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isJoining = false;
  String? _error;
  Map<String, dynamic>? _groupData;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    try {
      final supabase = Supabase.instance.client;
      final response =
          await supabase
              .from('groups')
              .select()
              .eq('id', widget.groupId)
              .single();

      setState(() {
        _groupData = response;
        _isLoading = false;
      });
    } catch (e) {
      logger.e(e);
      setState(() {
        _error = 'Group not found';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinGroup() async {
    if (_isJoining) return;

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw 'User not found';
      }

      // Check if user is already a member
      final existingMember =
          await supabase
              .from('group_members')
              .select()
              .eq('group_id', widget.groupId)
              .eq('user_id', user.id)
              .single();

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
            content: Text(
              context.translate('auth.group_join.joined_successfully'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Navigate to home screen after a short delay
      await Future.delayed(const Duration(seconds: 2));
      await _navigateWithAnimation('/');
    } catch (e) {
      logger.e(e);
      setState(() {
        _error = e.toString();
        _isJoining = false;
      });
    }
  }

  Future<void> _navigateWithAnimation(String route) async {
    if (mounted) {
      router.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _navigateWithAnimation('/'),
                child: Text(context.translate('auth.group_join.back_to_home')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Group icon
                  Icon(Icons.group, size: 80, color: theme.colorScheme.primary),
                  const SizedBox(height: 24),

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
                    _groupData?['group_name'] ?? '',
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
                              context.translate('auth.group_join.join_button'),
                              style: const TextStyle(fontSize: 16),
                            ),
                  ),
                  const SizedBox(height: 16),

                  // Cancel button
                  TextButton(
                    onPressed:
                        _isJoining ? null : () => _navigateWithAnimation('/'),
                    child: Text(
                      context.translate('auth.group_join.cancel_button'),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
