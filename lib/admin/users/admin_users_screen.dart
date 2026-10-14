import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';

enum UserFilterCategory { all, active, inactive, admins, users }

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  UserFilterCategory _selectedFilter = UserFilterCategory.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showViewDetailsDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.person, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(user.name, style: const TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('UID', user.uid),
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Phone', user.phone.isNotEmpty ? user.phone : 'Not provided'),
              _buildDetailRow('Role', user.role.toUpperCase()),
              _buildDetailRow('Status', user.isActive ? 'Active' : 'Deactivated'),
              _buildDetailRow('Created At', user.createdAt),
              _buildDetailRow('Updated At', user.updatedAt),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
          SelectableText(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }

  void _showChangeRoleDialog(UserModel user) {
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Change Role for ${user.name}', style: const TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'user', label: Text('User'), icon: Icon(Icons.person)),
                  ButtonSegment(value: 'admin', label: Text('Admin'), icon: Icon(Icons.shield)),
                ],
                selected: {selectedRole},
                onSelectionChanged: (newSelection) {
                  setModalState(() => selectedRole = newSelection.first);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                ref.read(userListProvider.notifier).changeUserRole(user.uid, selectedRole);
                Navigator.pop(ctx);
              },
              child: const Text('Save Role'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete User?', style: TextStyle(color: AppColors.error)),
        content: Text('Are you sure you want to delete "${user.name}"? This action cannot be undone.', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(userListProvider.notifier).deleteUser(user.uid);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('User ${user.name} deleted.')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                content,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.secondary),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exported data copied to clipboard!')),
              );
            },
            child: const Text('Copy to Clipboard', style: TextStyle(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(userListProvider);

    final filteredUsers = users.where((u) {
      final matchesSearch = _searchQuery.isEmpty ||
          u.name.toLowerCase().contains(_searchQuery) ||
          u.email.toLowerCase().contains(_searchQuery) ||
          u.phone.contains(_searchQuery);

      if (!matchesSearch) return false;

      switch (_selectedFilter) {
        case UserFilterCategory.all:
          return true;
        case UserFilterCategory.active:
          return u.isActive;
        case UserFilterCategory.inactive:
          return !u.isActive;
        case UserFilterCategory.admins:
          return u.role == 'admin';
        case UserFilterCategory.users:
          return u.role == 'user';
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download, color: AppColors.primary),
            tooltip: 'Export Users',
            onSelected: (val) {
              final notifier = ref.read(userListProvider.notifier);
              if (val == 'json') {
                _showExportDialog('Export Users (JSON)', notifier.exportUsersJson());
              } else if (val == 'csv') {
                _showExportDialog('Export Users (CSV)', notifier.exportUsersCsv());
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'json', child: Row(children: [Icon(Icons.code, size: 18), SizedBox(width: 8), Text('Export JSON')])),
              const PopupMenuItem(value: 'csv', child: Row(children: [Icon(Icons.table_chart, size: 18), SizedBox(width: 8), Text('Export CSV')])),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomTextField(
              label: '',
              hint: 'Search by name, email, or phone...',
              controller: _searchController,
              prefixIcon: Icons.search,
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: UserFilterCategory.values.map((cat) {
                final isSelected = _selectedFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(_getFilterLabel(cat)),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      setState(() => _selectedFilter = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filteredUsers.isEmpty
                ? const Center(child: Text('No users match your criteria.', style: TextStyle(color: AppColors.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final u = filteredUsers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.glassBorder),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            backgroundImage: u.photoUrl.isNotEmpty ? NetworkImage(u.photoUrl) : null,
                            child: u.photoUrl.isEmpty ? Text(u.name.isNotEmpty ? u.name.substring(0, 1).toUpperCase() : 'U') : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  u.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: u.role == 'admin' ? AppColors.accent.withValues(alpha: 0.2) : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  u.role.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: u.role == 'admin' ? AppColors.accent : AppColors.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                u.isActive ? 'Status: Active' : 'Status: Deactivated',
                                style: TextStyle(
                                  color: u.isActive ? AppColors.success : AppColors.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: u.isActive,
                                activeTrackColor: AppColors.success,
                                onChanged: (val) {
                                  ref.read(userListProvider.notifier).toggleUserActive(u.uid);
                                },
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                                onSelected: (val) {
                                  if (val == 'view') _showViewDetailsDialog(u);
                                  if (val == 'role') _showChangeRoleDialog(u);
                                  if (val == 'delete') _showDeleteUserDialog(u);
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'view', child: Text('View Details')),
                                  const PopupMenuItem(value: 'role', child: Text('Change Role')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete User', style: TextStyle(color: AppColors.error))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(UserFilterCategory cat) {
    switch (cat) {
      case UserFilterCategory.all:
        return 'All';
      case UserFilterCategory.active:
        return 'Active';
      case UserFilterCategory.inactive:
        return 'Inactive';
      case UserFilterCategory.admins:
        return 'Admins';
      case UserFilterCategory.users:
        return 'Users';
    }
  }
}
