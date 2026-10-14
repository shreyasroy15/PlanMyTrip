import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _darkMode = true;
  String _selectedCurrency = 'USD (\$)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Preferences', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _darkMode,
                  onChanged: (val) => setState(() => _darkMode = val),
                  title: const Text('Dark Mode Theme', style: TextStyle(color: AppColors.textPrimary)),
                  secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                ),
                const Divider(color: AppColors.glassBorder),
                SwitchListTile(
                  value: _pushNotifications,
                  onChanged: (val) => setState(() => _pushNotifications = val),
                  title: const Text('Push Notifications', style: TextStyle(color: AppColors.textPrimary)),
                  secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Regional', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.attach_money, color: AppColors.primary),
              title: const Text('Default Currency', style: TextStyle(color: AppColors.textPrimary)),
              trailing: DropdownButton<String>(
                value: _selectedCurrency,
                dropdownColor: AppColors.surface,
                underline: const SizedBox(),
                items: ['USD (\$)', 'EUR (€)', 'GBP (£)', 'INR (₹)']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCurrency = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
