import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_log_app/providers/theme_provider.dart';
import 'package:quick_log_app/services/data_export_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildThemeSection(context),
          const Divider(),
          _buildDataSection(context),
          const Divider(),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Theme'),
          subtitle: Text(themeProvider.themeModeLabel),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showThemeDialog(context, themeProvider),
        ),
      ],
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            final isSelected = themeProvider.themeMode == mode;
            return ListTile(
              title: Text(_getThemeModeLabel(mode)),
              subtitle: Text(_getThemeModeDescription(mode)),
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              onTap: () {
                themeProvider.setThemeMode(mode);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  String _getThemeModeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Follow system settings';
      case ThemeMode.light:
        return 'Always use light theme';
      case ThemeMode.dark:
        return 'Always use dark theme';
    }
  }

  Widget _buildDataSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Data Management',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.upload_outlined),
          title: const Text('Export as JSON'),
          subtitle: const Text('LLM-friendly format with metadata'),
          onTap: () => _exportJson(context),
        ),
        ListTile(
          leading: const Icon(Icons.table_chart_outlined),
          title: const Text('Export as CSV'),
          subtitle: const Text('Spreadsheet compatible format'),
          onTap: () => _exportCsv(context),
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Import from JSON'),
          subtitle: const Text('Restore from backup'),
          onTap: () => _importJson(context),
        ),
      ],
    );
  }

  Future<void> _exportJson(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing export...')),
      );
      await DataExportService.instance.shareJsonExport();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing export...')),
      );
      await DataExportService.instance.shareCsvExport();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importJson(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'This will add imported data to your existing entries. '
          'Duplicate tags will be updated.\n\n'
          'Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await DataExportService.instance.importFromJson();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'About',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Quick Log'),
          subtitle: const Text('Version 1.0.0'),
          onTap: () => _showAboutDialog(context),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Quick Log',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.edit_note,
          size: 32,
          color: Colors.white,
        ),
      ),
      children: [
        const Text(
          'A tag-first logging application for quick note-taking '
          'with location tracking.',
        ),
      ],
    );
  }
}
