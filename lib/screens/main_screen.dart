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
import 'package:quick_log_app/services/tag_suggestion_service.dart';
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
  List<LogTag> _suggestedTags = [];
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
    _loadSuggestedTags();
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

  Future<void> _loadSuggestedTags() async {
    try {
      // Get historical entries for pattern analysis (last 90 days)
      final now = DateTime.now();
      final ninetyDaysAgo = now.subtract(const Duration(days: 90));
      final historicalEntries = await DatabaseHelper.instance
          .getEntriesByDateRange(ninetyDaysAgo, now);

      final allTags = await DatabaseHelper.instance.getAllTags();

      // Get current location if available for location-based suggestions
      // Check if mounted before using context
      if (!mounted) return;

      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );

      Position? currentPos;
      if (settingsProvider.locationEnabled) {
        try {
          final permission = await Geolocator.checkPermission();
          if (permission != LocationPermission.denied &&
              permission != LocationPermission.deniedForever) {
            currentPos = await Geolocator.getCurrentPosition().timeout(
              const Duration(seconds: 5),
            );
          }
        } catch (e) {
          // Silently fail if location not available
        }
      }

      final suggested = TagSuggestionService.getSuggestedTags(
        historicalEntries: historicalEntries,
        allTags: allTags,
        currentTime: DateTime.now(),
        currentLatitude: currentPos?.latitude,
        currentLongitude: currentPos?.longitude,
      );

      if (mounted) {
        setState(() {
          _suggestedTags = suggested;
        });
      }
    } catch (e) {
      // Silently fail - suggestions are optional
      if (mounted) {
        setState(() {
          _suggestedTags = [];
        });
      }
    }
  }

  Future<void> _getCurrentLocation({bool force = false}) async {
    // Check if location is enabled in settings
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
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
      await _loadSuggestedTags(); // Refresh suggestions based on new entry

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
      builder: (context) => _TagSearchModal(
        allTags: _allTags,
        selectedTags: _selectedTags,
        onTagToggle: (tagId) {
          setState(() {
            _toggleTag(tagId);
          });
          Navigator.pop(context);
        },
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
            // Smart Suggested Tags Section (context-aware)
            if (_suggestedTags.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Suggested for You',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Based on time, day, and location patterns',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedTags.map((tag) {
                  return TagChipWidget(
                    tag: tag,
                    isSelected: _selectedTags.contains(tag.id),
                    onTap: () => _toggleTag(tag.id),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],

            // Recent Tags Section
            Text(
              'Recently Used Tags',
              style: Theme.of(context).textTheme.titleMedium,
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
                      ? (_currentPosition != null
                            ? Icons.location_on
                            : Icons.location_searching)
                      : Icons.location_disabled,
                  color:
                      settingsProvider.locationEnabled &&
                          _currentPosition != null
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
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
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

/// Modal widget for searching and selecting tags
class _TagSearchModal extends StatefulWidget {
  final List<LogTag> allTags;
  final Set<String> selectedTags;
  final Function(String) onTagToggle;

  const _TagSearchModal({
    required this.allTags,
    required this.selectedTags,
    required this.onTagToggle,
  });

  @override
  State<_TagSearchModal> createState() => _TagSearchModalState();
}

class _TagSearchModalState extends State<_TagSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  List<LogTag> _filteredTags = [];
  TagCategory? _filterCategory;

  @override
  void initState() {
    super.initState();
    _filteredTags = widget.allTags;
    _searchController.addListener(_filterTags);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTags() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTags = widget.allTags.where((tag) {
        final matchesSearch =
            query.isEmpty ||
            tag.label.toLowerCase().contains(query) ||
            tag.id.toLowerCase().contains(query);
        final matchesCategory =
            _filterCategory == null || tag.category == _filterCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Tags',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tags...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                const SizedBox(height: 12),
                // Category filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _filterCategory == null,
                        onSelected: (_) {
                          setState(() {
                            _filterCategory = null;
                            _filterTags();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...TagCategory.values.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              category.name[0].toUpperCase() +
                                  category.name.substring(1),
                            ),
                            selected: _filterCategory == category,
                            onSelected: (_) {
                              setState(() {
                                _filterCategory = category;
                                _filterTags();
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Results
          Expanded(
            child: _filteredTags.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tags found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: _filteredTags.length,
                    itemBuilder: (context, index) {
                      final tag = _filteredTags[index];
                      final isSelected = widget.selectedTags.contains(tag.id);
                      return CheckboxListTile(
                        title: Text(tag.label),
                        subtitle: Text(
                          '${tag.category.name} • Used ${tag.usageCount} times',
                        ),
                        value: isSelected,
                        onChanged: (value) {
                          widget.onTagToggle(tag.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
