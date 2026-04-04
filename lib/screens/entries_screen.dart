import 'package:flutter/material.dart';
import 'package:quick_log_app/models/log_entry.dart';
import 'package:quick_log_app/models/log_tag.dart';
import 'package:quick_log_app/data/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:quick_log_app/services/home_widget_service.dart';

class EntriesScreen extends StatefulWidget {
  const EntriesScreen({super.key});

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  List<LogEntry> _entries = [];
  List<LogEntry> _filteredEntries = [];
  Map<String, LogTag> _tagMap = {};
  List<LogTag> _allTags = [];
  bool _isLoading = true;

  // Filter state
  final Set<String> _selectedFilterTags = {};
  DateTime? _startDate;
  DateTime? _endDate;
  bool?
  _hasLocation; // null = all, true = with location, false = without location

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final entries = await DatabaseHelper.instance.getAllEntries();
      final tags = await DatabaseHelper.instance.getAllTags();
      final tagMap = {for (var tag in tags) tag.id: tag};

      setState(() {
        _entries = entries;
        _tagMap = tagMap;
        _allTags = tags;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading entries: $e')));
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredEntries = _entries.where((entry) {
        // Tag filter
        if (_selectedFilterTags.isNotEmpty) {
          final hasAllTags = _selectedFilterTags.every(
            (tag) => entry.tags.contains(tag),
          );
          if (!hasAllTags) return false;
        }

        // Date range filter
        if (_startDate != null) {
          if (entry.createdAt.isBefore(_startDate!)) return false;
        }
        if (_endDate != null) {
          final endOfDay = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
            23,
            59,
            59,
          );
          if (entry.createdAt.isAfter(endOfDay)) return false;
        }

        // Location filter
        if (_hasLocation != null) {
          final entryHasLocation =
              entry.latitude != null && entry.longitude != null;
          if (_hasLocation! && !entryHasLocation) return false;
          if (!_hasLocation! && entryHasLocation) return false;
        }

        return true;
      }).toList();
    });
  }

  bool get _hasActiveFilters =>
      _selectedFilterTags.isNotEmpty ||
      _startDate != null ||
      _endDate != null ||
      _hasLocation != null;

  void _clearFilters() {
    setState(() {
      _selectedFilterTags.clear();
      _startDate = null;
      _endDate = null;
      _hasLocation = null;
    });
    _applyFilters();
  }

  int get _pendingReviewCount =>
      _entries.where((entry) => entry.needsReview).length;

  LogEntry? get _nextPendingReviewEntry {
    for (final entry in _entries) {
      if (entry.needsReview) {
        return entry;
      }
    }
    return null;
  }

  LogEntry _markReviewedIfNeeded(LogEntry entry) {
    if (entry.needsReview) {
      return entry.copyWith(reviewStatus: EntryReviewStatus.confirmed);
    }
    return entry;
  }

  String _entrySourceChipLabel(LogEntry entry) {
    if (entry.isPhotoCapture) {
      return 'Travel photo';
    }
    if (entry.isTravelCapture) {
      return 'Travel log';
    }
    return 'Location only';
  }

  String _reviewStatusLabel(LogEntry entry) {
    if (entry.isPhotoCapture) {
      return entry.needsReview
          ? 'Photo travel log pending review'
          : 'Photo travel log confirmed';
    }
    return entry.needsReview
        ? 'Travel log pending review'
        : 'Travel log confirmed';
  }

  Future<void> _saveUpdatedEntry(
    LogEntry entry, {
    required String successMessage,
  }) async {
    try {
      await DatabaseHelper.instance.updateEntry(entry);
      await QuickLogHomeWidgetService.instance.sync();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating entry: $e')));
      }
    }
  }

  Future<void> _confirmEntryReview(LogEntry entry) async {
    await _saveUpdatedEntry(
      _markReviewedIfNeeded(entry),
      successMessage: 'Travel log confirmed',
    );
  }

  Future<void> _deleteEntry(LogEntry entry, {bool confirm = true}) async {
    if (confirm) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Entry'),
          content: const Text('Are you sure you want to delete this entry?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    if (entry.id != null) {
      try {
        await DatabaseHelper.instance.deleteEntry(entry.id!);
        await QuickLogHomeWidgetService.instance.sync();
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Entry deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting entry: $e')));
        }
      }
    }
  }

  Future<void> _editEntry(LogEntry entry) async {
    final TextEditingController noteController = TextEditingController(
      text: entry.note ?? '',
    );
    final Set<String> selectedTags = Set.from(entry.tags);
    final canLeaveTagsEmpty = entry.hasLocation;
    final isReviewFlow = entry.needsReview;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isReviewFlow ? 'Review Travel Log' : 'Edit Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isReviewFlow) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'This travel log was created automatically. Confirm it after checking the place, tags, and any note you want to keep.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text('Tags', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allTags.map((tag) {
                    final isSelected = selectedTags.contains(tag.id);
                    return FilterChip(
                      label: Text(tag.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedTags.add(tag.id);
                          } else {
                            selectedTags.remove(tag.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    hintText: 'Add a note...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(isReviewFlow ? 'Confirm Log' : 'Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      if (selectedTags.isEmpty && !canLeaveTagsEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select at least one tag or keep location'),
            ),
          );
        }
        noteController.dispose();
        return;
      }
      try {
        final updatedEntry = _markReviewedIfNeeded(
          entry.copyWith(
            note: noteController.text.isEmpty ? null : noteController.text,
            tags: selectedTags.toList(),
          ),
        );
        await _saveUpdatedEntry(
          updatedEntry,
          successMessage: isReviewFlow
              ? 'Travel log reviewed'
              : 'Entry updated',
        );
      } finally {
        noteController.dispose();
      }
      return;
    }

    noteController.dispose();
  }

  void _showEntryDetails(LogEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM d, y • h:mm a').format(entry.createdAt),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text('Tags', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (entry.tags.isEmpty)
                Text(
                  'No tags yet',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                Wrap(
                  spacing: 8,
                  children: entry.tags.map((tagId) {
                    final tag = _tagMap[tagId];
                    return Chip(
                      label: Text(tag?.label ?? tagId),
                      avatar: Icon(
                        Icons.label,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    );
                  }).toList(),
                ),

              if (entry.isTravelCapture) ...[
                const SizedBox(height: 24),
                Text(
                  entry.isPhotoCapture ? 'Travel Capture' : 'Visit Detection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Icon(
                    entry.needsReview
                        ? Icons.pending_actions_outlined
                        : Icons.check_circle_outline,
                  ),
                  title: Text(
                    entry.isPhotoCapture
                        ? (entry.needsReview
                              ? 'Needs review'
                              : 'Confirmed photo log')
                        : (entry.needsReview
                              ? 'Needs review'
                              : 'Confirmed visit'),
                  ),
                  subtitle: Text(
                    [
                      if (entry.isPhotoCapture)
                        'Created from a new photo capture during Travel Mode',
                      if (entry.visitStartedAt != null)
                        'Started ${DateFormat('MMM d, y • h:mm a').format(entry.visitStartedAt!)}',
                      if (entry.visitEndedAt != null)
                        'Ended ${DateFormat('h:mm a').format(entry.visitEndedAt!)}',
                      if (entry.visitDurationMinutes != null)
                        '${entry.visitDurationMinutes} min stop',
                    ].join(' • '),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                if (entry.needsReview)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Review this travel log so it no longer stays pending. You can confirm it as-is or edit tags and notes first.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],

              // Note
              if (entry.note != null && entry.note!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Note', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(entry.note!),
              ],

              // Location
              if (entry.locationLabel != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Location',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(entry.locationLabel!),
                  subtitle: entry.latitude != null && entry.longitude != null
                      ? Text(
                          'Lat: ${entry.latitude!.toStringAsFixed(4)}, '
                          'Lon: ${entry.longitude!.toStringAsFixed(4)}',
                        )
                      : null,
                  contentPadding: EdgeInsets.zero,
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _editEntry(entry);
                  },
                  icon: Icon(
                    entry.needsReview ? Icons.rate_review : Icons.edit,
                  ),
                  label: Text(
                    entry.needsReview ? 'Review & Edit' : 'Edit Entry',
                  ),
                ),
              ),
              if (entry.needsReview) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmEntryReview(entry);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm as Visited'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteEntry(entry);
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete Entry'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Entries',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Tag filter
                Text('Tags', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Show entries with ALL selected tags',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allTags.map((tag) {
                    final isSelected = _selectedFilterTags.contains(tag.id);
                    return FilterChip(
                      label: Text(tag.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        setModalState(() {
                          if (selected) {
                            _selectedFilterTags.add(tag.id);
                          } else {
                            _selectedFilterTags.remove(tag.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Date range filter
                Text(
                  'Date Range',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setModalState(() => _startDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _startDate != null
                              ? DateFormat('MMM d, y').format(_startDate!)
                              : 'Start Date',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setModalState(() => _endDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _endDate != null
                              ? DateFormat('MMM d, y').format(_endDate!)
                              : 'End Date',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Location filter
                Text(
                  'Location',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('All')),
                    ButtonSegment(value: true, label: Text('With Location')),
                    ButtonSegment(value: false, label: Text('No Location')),
                  ],
                  selected: {_hasLocation},
                  onSelectionChanged: (Set<bool?> newSelection) {
                    setModalState(() {
                      _hasLocation = newSelection.first;
                    });
                  },
                ),

                const SizedBox(height: 32),

                // Apply and clear buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedFilterTags.clear();
                            _startDate = null;
                            _endDate = null;
                            _hasLocation = null;
                          });
                        },
                        child: const Text('Clear All'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          _applyFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_entries.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No entries yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Start logging or use Travel Mode to see entries here',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final displayEntries = _hasActiveFilters ? _filteredEntries : _entries;

    return Scaffold(
      body: Column(
        children: [
          if (_pendingReviewCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.pending_actions_outlined,
                            color: Theme.of(
                              context,
                            ).colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _pendingReviewCount == 1
                                  ? '1 travel log needs review'
                                  : '$_pendingReviewCount travel logs need review',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Travel Mode can quietly create place logs for later cleanup. Confirm or edit them so they no longer stay pending.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () {
                          final nextEntry = _nextPendingReviewEntry;
                          if (nextEntry != null) {
                            _showEntryDetails(nextEntry);
                          }
                        },
                        icon: const Icon(Icons.rate_review_outlined),
                        label: const Text('Review next travel log'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Filter status bar
          if (_hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${displayEntries.length} of ${_entries.length} entries',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: displayEntries.isEmpty
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
                          'No entries match filters',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear filters'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: displayEntries.length,
                      itemBuilder: (context, index) {
                        final entry = displayEntries[index];
                        return Dismissible(
                          key: Key('entry_${entry.id}'),
                          background: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            child: const Icon(Icons.edit, color: Colors.white),
                          ),
                          secondaryBackground: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              // Swipe right - Edit
                              await _editEntry(entry);
                              return false; // Don't dismiss, just edit
                            } else {
                              // Swipe left - Delete
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Entry'),
                                  content: const Text(
                                    'Are you sure you want to delete this entry?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              return confirmed == true;
                            }
                          },
                          onDismissed: (direction) {
                            if (direction == DismissDirection.endToStart) {
                              _deleteEntry(entry, confirm: false);
                            }
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  DateFormat('d').format(entry.createdAt),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 4,
                                      children: entry.tags.isEmpty
                                          ? [
                                              Chip(
                                                label: Text(
                                                  _entrySourceChipLabel(entry),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                            ]
                                          : entry.tags.take(3).map((tagId) {
                                              final tag = _tagMap[tagId];
                                              return Chip(
                                                label: Text(
                                                  tag?.label ?? tagId,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                              );
                                            }).toList(),
                                    ),
                                  ),
                                  if (entry.tags.length > 3)
                                    Chip(
                                      label: Text(
                                        '+${entry.tags.length - 3}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat(
                                      'MMM d, y • h:mm a',
                                    ).format(entry.createdAt),
                                  ),
                                  if (entry.note != null &&
                                      entry.note!.isNotEmpty)
                                    Text(
                                      entry.note!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (entry.locationLabel != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 12),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            entry.locationLabel!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (entry.isTravelCapture)
                                    Row(
                                      children: [
                                        Icon(
                                          entry.needsReview
                                              ? Icons.pending_actions_outlined
                                              : Icons.check_circle_outline,
                                          size: 14,
                                          color: entry.needsReview
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.secondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _reviewStatusLabel(entry),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              isThreeLine: true,
                              onTap: () => _showEntryDetails(entry),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _showEntryDetails(entry),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterDialog,
        tooltip: 'Filter entries',
        child: Badge(
          isLabelVisible: _hasActiveFilters,
          child: const Icon(Icons.filter_list),
        ),
      ),
    );
  }
}
