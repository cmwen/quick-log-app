import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_log_app/models/log_entry.dart';
import 'package:quick_log_app/models/log_tag.dart';
import 'package:quick_log_app/data/database_helper.dart';
import 'package:quick_log_app/screens/entries_screen.dart';
import 'package:quick_log_app/screens/tags_screen.dart';
import 'package:quick_log_app/screens/map_screen.dart';
import 'package:quick_log_app/screens/settings_screen.dart';
import 'package:quick_log_app/widgets/tag_chip.dart';
import 'package:quick_log_app/providers/settings_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _noteController = TextEditingController();
  final Set<String> _selectedTags = {};
  List<LogTag> _recentTags = [];
  List<LogTag> _allTags = [];
  bool _isLoading = true;
  Position? _currentPosition;
  String? _locationLabel;
  bool _isGettingLocation = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTags();
    // Location will be fetched when needed based on settings
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    try {
      final recentTags = await DatabaseHelper.instance.getRecentTags(limit: 12);
      final allTags = await DatabaseHelper.instance.getAllTags();
      setState(() {
        _recentTags = recentTags;
        _allTags = allTags;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading tags: $e')));
      }
    }
  }

  Future<void> _getCurrentLocation({bool force = false}) async {
    // Check if location is enabled in settings
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    if (!settingsProvider.locationEnabled && !force) {
      setState(() {
        _currentPosition = null;
        _locationLabel = null;
        _isGettingLocation = false;
      });
      return;
    }

    setState(() => _isGettingLocation = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied) {
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentPosition = position;
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _locationLabel = [
            place.name,
            place.locality,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        }
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() => _isGettingLocation = false);
    }
  }

  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedTags.contains(tagId)) {
        _selectedTags.remove(tagId);
      } else {
        _selectedTags.add(tagId);
      }
    });
  }

  Future<void> _saveEntry() async {
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one tag')),
      );
      return;
    }

    final entry = LogEntry(
      createdAt: DateTime.now(),
      note: _noteController.text.isEmpty ? null : _noteController.text,
      tags: _selectedTags.toList(),
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
      locationLabel: _locationLabel,
    );

    try {
      await DatabaseHelper.instance.insertEntry(entry);

      // Reset form
      setState(() {
        _selectedTags.clear();
        _noteController.clear();
      });

      await _loadTags(); // Refresh to update usage counts

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving entry: $e')));
      }
    }
  }

  void _showAllTags() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Tags',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _allTags.length,
                itemBuilder: (context, index) {
                  final tag = _allTags[index];
                  return CheckboxListTile(
                    title: Text(tag.label),
                    subtitle: Text(
                      '${tag.category.name} • Used ${tag.usageCount} times',
                    ),
                    value: _selectedTags.contains(tag.id),
                    onChanged: (value) {
                      setState(() {
                        _toggleTag(tag.id);
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) => SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Tags Section
          Text(
            'Quick Select Tags',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentTags.map((tag) {
              return TagChipWidget(
                tag: tag,
                isSelected: _selectedTags.contains(tag.id),
                onTap: () => _toggleTag(tag.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _showAllTags,
            icon: const Icon(Icons.more_horiz),
            label: const Text('See all tags'),
          ),

          // Selected Tags Section
          if (_selectedTags.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Selected Tags (${_selectedTags.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedTags.map((tagId) {
                final tag = _allTags.firstWhere((t) => t.id == tagId);
                return TagChipWidget(
                  tag: tag,
                  isSelected: true,
                  onTap: () => _toggleTag(tag.id),
                  showClose: true,
                );
              }).toList(),
            ),
          ],

          // Note Section
          const SizedBox(height: 24),
          Text(
            'Add Note (Optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'What\'s happening?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 4,
          ),

          // Location Section
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: Icon(
                settingsProvider.locationEnabled
                    ? (_currentPosition != null ? Icons.location_on : Icons.location_searching)
                    : Icons.location_disabled,
                color: settingsProvider.locationEnabled && _currentPosition != null
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(
                settingsProvider.locationEnabled
                    ? (_locationLabel ?? 'Location not available')
                    : 'Location tracking disabled',
              ),
              subtitle: settingsProvider.locationEnabled
                  ? (_currentPosition != null
                      ? Text(
                          'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                          'Lon: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                        )
                      : const Text('Tap refresh to get location'))
                  : const Text('Enable in Settings to track location'),
              trailing: settingsProvider.locationEnabled
                  ? (_isGettingLocation
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => _getCurrentLocation(force: true),
                        ))
                  : null,
            ),
          ),

          // Save Button
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveEntry,
              icon: const Icon(Icons.save),
              label: const Text('Save Entry'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ),
        ],
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildMainContent(),
      const EntriesScreen(),
      const TagsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
              );
            },
            tooltip: 'Map View',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About Quick Log'),
                  content: const Text(
                    'A tag-first logging application for quick note-taking with location tracking.\n\n'
                    'Simply select tags, add an optional note, and save your entry!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.edit), label: 'Record'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Entries'),
          NavigationDestination(icon: Icon(Icons.label), label: 'Tags'),
        ],
      ),
    );
  }
}
