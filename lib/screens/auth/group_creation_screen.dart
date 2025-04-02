import 'package:flutter/material.dart';
import 'package:june/june.dart';
import 'package:sumit/router.dart';
import 'package:sumit/utils.dart';
import 'package:sumit/utils/translations_extension.dart';
import 'package:sumit/state/module.dart';
import 'package:sumit/services/translations_service.dart';
import 'package:sumit/services/encryption_service.dart';
import 'package:sumit/models/group.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class GroupCreationScreen extends StatefulWidget {
  final bool fromGroupList;

  const GroupCreationScreen({super.key, this.fromGroupList = false});

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
  String _inviteCode = '';

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

      // Encrypt the group's UUID as the invite code
      _inviteCode = EncryptionService.encryptGroupId(group.id);

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

      // If coming from group list, don't show the success UI, just return to the list
      if (widget.fromGroupList) {
        if (mounted) {
          // Pop back to the group list screen with a result that indicates success
          Navigator.pop(context, true);
        }
        return;
      }
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
    return Scaffold(
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
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 24),

                        // Title
                        JuneBuilder(
                          () => TranslationsService(),
                          builder:
                              (translationsService) => Text(
                                context.translate('auth.group_creation.title'),
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        JuneBuilder(
                          () => TranslationsService(),
                          builder:
                              (translationsService) => Text(
                                context.translate(
                                  'auth.group_creation.subtitle',
                                ),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                        ),
                        const SizedBox(height: 48),

                        // Group Name Input or Display
                        if (!_groupCreated)
                          JuneBuilder(
                            () => TranslationsService(),
                            builder:
                                (translationsService) => TextFormField(
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
                                ),
                          )
                        else
                          Card(
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: JuneBuilder(
                                          () => TranslationsService(),
                                          builder:
                                              (translationsService) => Text(
                                                context.translate(
                                                  'auth.group_creation.group_created',
                                                ),
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.titleMedium,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _groupNameController.text,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  JuneBuilder(
                                    () => TranslationsService(),
                                    builder:
                                        (translationsService) => Text(
                                          context.translate(
                                            'auth.group_creation.share_invite',
                                          ),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ShareButton(
                                        groupName: _groupNameController.text,
                                        inviteCode: _inviteCode,
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
                          JuneBuilder(
                            () => TranslationsService(),
                            builder:
                                (translationsService) => ElevatedButton(
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () => _navigateWithAnimation('/'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  child: Text(
                                    context.translate(
                                      'auth.group_creation.continue_button',
                                    ),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                    ),
                                  ),
                                ),
                          )
                        else
                          JuneBuilder(
                            () => TranslationsService(),
                            builder:
                                (translationsService) => ElevatedButton(
                                  onPressed: _isLoading ? null : _createGroup,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  child:
                                      _isLoading
                                          ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary,
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
                          ),
                        const SizedBox(height: 16),
                        // Skip Button (only shown before group creation and not from group list)
                        if (!_groupCreated && !widget.fromGroupList)
                          JuneBuilder(
                            () => TranslationsService(),
                            builder:
                                (translationsService) => TextButton(
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () async {
                                            // Update user preferences to mark group as created (skipped)
                                            final settingsState = June.getState(
                                              () => SettingsState(),
                                            );
                                            await settingsState
                                                .updatePreferences(
                                                  hasCreatedGroup: true,
                                                );
                                            await _navigateWithAnimation('/');
                                          },
                                  child: Text(
                                    context.translate(
                                      'auth.group_creation.skip_button',
                                    ),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
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
    );
  }
}

class ShareButton extends StatefulWidget {
  final String groupName;
  final String inviteCode;

  const ShareButton({
    super.key,
    required this.groupName,
    required this.inviteCode,
  });

  @override
  State<ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<ShareButton> {
  Future<void> _handleShare() async {
    if (!mounted) return;

    final message = context.translate(
      'auth.group_creation.share_message',
      args: {'group_name': widget.groupName},
    );

    try {
      await Clipboard.setData(
        ClipboardData(text: '$message\n\n${widget.inviteCode}'),
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.translate('auth.group_creation.copied_to_clipboard'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.translate('auth.group_creation.copy_error')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _handleShare,
      icon: const Icon(Icons.copy),
      label: Text(context.translate('auth.group_creation.copy_button')),
    );
  }
}
