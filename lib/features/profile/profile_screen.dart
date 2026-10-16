import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Dialog to Edit Display Name
  void _showEditNameDialog(String currentName) {
    final nameController = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.glassBorder),
              ),
              title: const Text(
                'Edit Display Name',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Enter your new display name as it will appear across your trips and itineraries.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Full Name',
                      hint: 'Alex Traveler',
                      controller: nameController,
                      prefixIcon: Icons.person_outline,
                      validator: (val) => Validators.validateRequired(val, 'Display name'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(ctx);
                            setDialogState(() => isSaving = true);
                            final success = await ref
                                .read(authProvider.notifier)
                                .updateDisplayName(nameController.text.trim());
                            if (mounted) {
                              navigator.pop();
                              if (success) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Display name updated successfully!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } else {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to update name. Please try again.'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Changes', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog to Change Password
  void _showChangePasswordDialog(bool hasLocalPassword) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    String? localError;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.glassBorder),
              ),
              title: Text(
                hasLocalPassword ? 'Change Password' : 'Set Local Password',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!hasLocalPassword) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Your account was created via social login. Setting a password enables email and password sign-in as an alternative.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (localError != null) ...[
                        Text(
                          localError!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (hasLocalPassword) ...[
                        CustomTextField(
                          label: 'Current Password',
                          hint: '••••••••',
                          controller: currentPasswordController,
                          isPassword: obscureCurrent,
                          prefixIcon: Icons.lock_clock_outlined,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Current password is required';
                            return null;
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureCurrent ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                            onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      CustomTextField(
                        label: 'New Password',
                        hint: 'At least 6 characters',
                        controller: newPasswordController,
                        isPassword: obscureNew,
                        prefixIcon: Icons.lock_outline,
                        validator: Validators.validatePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Confirm New Password',
                        hint: '••••••••',
                        controller: confirmPasswordController,
                        isPassword: obscureNew,
                        prefixIcon: Icons.lock_reset,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please confirm new password';
                          if (val != newPasswordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(ctx);
                            setDialogState(() {
                              isSaving = true;
                              localError = null;
                            });

                            final success = await ref.read(authProvider.notifier).changePassword(
                                  currentPassword: currentPasswordController.text.trim(),
                                  newPassword: newPasswordController.text.trim(),
                                  confirmPassword: confirmPasswordController.text.trim(),
                                );

                            if (mounted) {
                              if (success) {
                                navigator.pop();
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Password updated successfully! Other sessions have been rotated.'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } else {
                                final authErr = ref.read(authProvider).errorMessage;
                                setDialogState(() {
                                  isSaving = false;
                                  localError = authErr ?? 'Password update failed. Verify current password.';
                                });
                              }
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Update Password', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Logout Confirmation Dialog
  void _confirmLogout({required bool allDevices}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: Text(
          allDevices ? 'Logout from All Devices' : 'Sign Out',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          allDevices
              ? 'Are you sure you want to invalidate all active sessions across all devices? You will need to sign in again.'
              : 'Are you sure you want to sign out from this device?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final router = GoRouter.of(context);
              Navigator.of(ctx).pop();
              if (allDevices) {
                await ref.read(authProvider.notifier).logoutAll();
              } else {
                await ref.read(authProvider.notifier).logout();
              }
              if (mounted) {
                router.go('/login');
              }
            },
            child: const Text('Confirm Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.userModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Profile & Account',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Avatar with Edit Name Icon
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primary,
                        backgroundImage: (user?.photoUrl.isNotEmpty == true &&
                                user!.photoUrl.startsWith('http'))
                            ? NetworkImage(user.photoUrl)
                            : null,
                        child: (user?.photoUrl.isEmpty != false ||
                                !user!.photoUrl.startsWith('http'))
                            ? Text(
                                (user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _showEditNameDialog(user?.name ?? ''),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.background, width: 2),
                            ),
                            child: const Icon(Icons.edit, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Name & Edit Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user?.name ?? 'Traveler',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                      onPressed: () => _showEditNameDialog(user?.name ?? ''),
                      tooltip: 'Change Display Name',
                    ),
                  ],
                ),
                Text(
                  user?.email ?? 'user@example.com',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 8),

                // Provider & Role Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'ROLE: ${(user?.role ?? 'user').toUpperCase()}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (user?.isEmailVerified ?? false)
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        (user?.isEmailVerified ?? false) ? '✓ EMAIL VERIFIED' : '⚠ UNVERIFIED',
                        style: TextStyle(
                          color: (user?.isEmailVerified ?? false) ? AppColors.success : AppColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Account Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Status',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.isActive == true ? 'Active' : 'Deactivated',
                            style: TextStyle(
                              color: user?.isActive == true ? AppColors.success : AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: user?.isActive ?? true,
                        activeThumbColor: AppColors.success,
                        onChanged: (val) {
                          if (user != null) {
                            ref.read(authProvider.notifier).toggleAccountActivation(user.uid, val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Profile Menu Sections
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'Display Name',
                  subtitle: user?.name ?? 'Set your public display name',
                  onTap: () => _showEditNameDialog(user?.name ?? ''),
                ),
                _buildMenuItem(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  subtitle: user?.hasPassword == true
                      ? 'Update your secret password'
                      : 'Set a password for email login',
                  onTap: () => _showChangePasswordDialog(user?.hasPassword ?? true),
                ),
                if (user?.role == 'admin') ...[
                  _buildMenuItem(
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Dashboard',
                    subtitle: 'Manage platform users, trips, destinations, analytics',
                    iconColor: AppColors.accent,
                    onTap: () => context.push('/admin'),
                  ),
                ],
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Trip alerts, AI updates, and security logs',
                  onTap: () => context.push('/notifications'),
                ),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'App Settings',
                  subtitle: 'Theme, currency, language, travel preferences',
                  onTap: () => context.push('/settings'),
                ),

                const SizedBox(height: 28),

                // Sign Out Current Device
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(allDevices: false),
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Logout All Devices Option (Security Feature)
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _confirmLogout(allDevices: true),
                    icon: const Icon(Icons.devices, color: AppColors.textMuted, size: 18),
                    label: const Text(
                      'Sign Out from All Devices',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 15),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
        ),
      ),
    );
  }
}
