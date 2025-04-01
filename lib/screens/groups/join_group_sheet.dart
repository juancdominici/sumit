import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sumit/services/encryption_service.dart';
import 'package:sumit/utils.dart';
import 'package:sumit/utils/translations_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JoinGroupSheet extends StatefulWidget {
  /// Called after successfully joining a group
  final VoidCallback onGroupJoined;

  const JoinGroupSheet({super.key, required this.onGroupJoined});

  @override
  State<JoinGroupSheet> createState() => _JoinGroupSheetState();
}

class _JoinGroupSheetState extends State<JoinGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  // Process invite code to strip any whitespace
  String _processInviteCode(String code) {
    return code.trim();
  }

  Future<void> _joinGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final inviteCode = _processInviteCode(_inviteCodeController.text);
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw context.translate('auth.group_join.error.user_not_found');
      }

      // Attempt to get group ID from invite code
      String? groupId;

      try {
        // Try to decrypt the invite code
        groupId = EncryptionService.decryptInviteCode(inviteCode);

        // Validate the group ID structure (basic UUID validation)
        if (groupId.isEmpty ||
            !RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
            ).hasMatch(groupId)) {
          throw Exception("Invalid group ID format");
        }
      } catch (e) {
        logger.e('Error decrypting invite code: $e');
        throw context.translate('auth.group_invite.invalid_code');
      }

      // Check if the group exists
      try {
        final groupResponse =
            await supabase.from('groups').select().eq('id', groupId).single();

        if (groupResponse.isEmpty) {
          throw context.translate('auth.group_join.error.group_not_found');
        }
      } catch (e) {
        logger.e('Error finding group: $e');
        throw context.translate('auth.group_join.error.group_not_found');
      }

      // Check if user is already a member
      try {
        final existingMember = await supabase
            .from('group_members')
            .select()
            .eq('group_id', groupId)
            .eq('user_id', user.id);

        if (existingMember.isNotEmpty) {
          // User is already a member
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.translate('auth.group_join.error.already_member'),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
          return;
        }
      } catch (e) {
        logger.e('Error checking membership: $e');
      }

      // Add user as a member
      try {
        final memberData = {
          'group_id': groupId,
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

          // Close the sheet and refresh the groups list
          Navigator.pop(context);
          widget.onGroupJoined();
        }
      } catch (e) {
        logger.e('Error adding group member: $e');
        throw context.translate('auth.group_invite.join_error');
      }
    } catch (e) {
      logger.e('Error joining group: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        // Add padding to avoid the keyboard
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle grip
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            context.translate('auth.group_join.title'),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Form
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _inviteCodeController,
              decoration: InputDecoration(
                labelText: context.translate('auth.group_invite.code_label'),
                hintText: context.translate('auth.group_invite.code_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.group_add),
              ),
              textInputAction: TextInputAction.done,
              onEditingComplete: _joinGroup,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.translate('auth.group_invite.code_required');
                }
                return null;
              },
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[\s]')),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 24),

          // Join button
          ElevatedButton(
            onPressed: _isLoading ? null : _joinGroup,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child:
                _isLoading
                    ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                    : Text(
                      context.translate('auth.group_join.join_button'),
                      style: const TextStyle(fontSize: 16),
                    ),
          ),
          const SizedBox(height: 8),

          // Cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.translate('auth.group_join.cancel_button'),
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
