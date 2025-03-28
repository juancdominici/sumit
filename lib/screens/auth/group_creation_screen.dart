import 'package:flutter/material.dart';
import 'package:june/june.dart';
import 'package:sumit/router.dart';
import 'package:sumit/utils.dart';
import 'package:sumit/utils/translations_extension.dart';
import 'package:sumit/state/module.dart';
import 'package:sumit/services/translations_service.dart';
import 'package:sumit/models/group.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

class GroupCreationScreen extends StatefulWidget {
  const GroupCreationScreen({super.key});

  @override
  GroupCreationScreenState createState() => GroupCreationScreenState();
}

class GroupCreationScreenState extends State<GroupCreationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _groupCreated = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form fields
  final _groupNameController = TextEditingController();
  String _inviteLink = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not found!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Create the group
      final groupData = {
        'group_name': _groupNameController.text,
        'group_owner': user.id,
      };

      final groupResponse =
          await supabase.from('groups').insert(groupData).select().single();

      final group = Group.fromJson(groupResponse);

      // Add the creator as the first member
      final memberData = {
        'group_id': group.id,
        'user_id': user.id,
        'joined_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('group_members').insert(memberData);

      // Generate invite link with a proper URL format
      _inviteLink = 'https://sumit.app/join/${group.id}';

      // Update user preferences to mark group as created
      final settingsState = June.getState(() => SettingsState());
      await settingsState.updatePreferences(hasCreatedGroup: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.translate('auth.group_creation.created_successfully'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      setState(() {
        _groupCreated = true;
        _isLoading = false;
      });
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateWithAnimation(String route) async {
    setState(() {
      _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );
      _slideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0, -1.0),
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInCubic,
        ),
      );
    });

    _animationController.forward(from: 0);
    await Future.delayed(_animationController.duration!);

    if (mounted) {
      router.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return JuneBuilder(
      () => TranslationsService(),
      builder: (translationsService) => Scaffold(
        body: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Group icon
                          Icon(
                            Icons.group,
                            size: 80,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 24),

                          // Title
                          Text(
                            context.translate('auth.group_creation.title'),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            context.translate(
                              'auth.group_creation.subtitle',
                            ),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),

                          // Group Name Input or Display
                          if (!_groupCreated)
                            TextFormField(
                              controller: _groupNameController,
                              decoration: InputDecoration(
                                labelText: context.translate(
                                  'auth.group_creation.group_name',
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return context.translate(
                                    'auth.group_creation.group_name_required',
                                  );
                                }
                                return null;
                              },
                            )
                          else
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: theme.colorScheme.outline
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: theme.colorScheme.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            context.translate(
                                              'auth.group_creation.group_created',
                                            ),
                                            style: theme.textTheme.titleMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _groupNameController.text,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      context.translate(
                                        'auth.group_creation.share_invite',
                                      ),
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () async {
                                            final subject = context.translate(
                                              'auth.group_creation.share_subject',
                                              args: {
                                                'group_name':
                                                    _groupNameController.text,
                                              },
                                            );
                                            final message = context.translate(
                                              'auth.group_creation.share_message',
                                              args: {
                                                'group_name':
                                                    _groupNameController.text,
                                              },
                                            );
                                            await Share.share(
                                              '$message\n\n$_inviteLink',
                                              subject: subject,
                                            );
                                          },
                                          icon: const Icon(Icons.share),
                                          label: Text(
                                            context.translate(
                                              'auth.group_creation.share_button',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (!_groupCreated) const SizedBox(height: 24),

                          // Create Group Button or Continue Button
                          if (_groupCreated)
                            ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _navigateWithAnimation('/'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                              child: Text(
                                context.translate(
                                  'auth.group_creation.continue_button',
                                ),
                                style: const TextStyle(fontSize: 16),
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: _isLoading ? null : _createGroup,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                              child: _isLoading
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
                                        'auth.group_creation.create_group',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          const SizedBox(height: 16),
                          // Skip Button (only shown before group creation)
                          if (!_groupCreated)
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      // Update user preferences to mark group as created (skipped)
                                      final settingsState = June.getState(
                                        () => SettingsState(),
                                      );
                                      await settingsState.updatePreferences(
                                        hasCreatedGroup: true,
                                      );
                                      await _navigateWithAnimation('/');
                                    },
                              child: Text(
                                context.translate(
                                  'auth.group_creation.skip_button',
                                ),
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
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
          ),
        ),
      ),
    );
  }
}
