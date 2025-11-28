import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:quick_log_app/data/database_helper.dart';
import 'package:quick_log_app/models/log_entry.dart';
import 'package:quick_log_app/models/log_tag.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<LogEntry> _entriesWithLocation = [];
  Map<String, LogTag> _tagMap = {};
  bool _isLoading = true;
  final MapController _mapController = MapController();

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

      // Filter entries that have location data
      final entriesWithLocation = entries
          .where((e) => e.latitude != null && e.longitude != null)
          .toList();

      setState(() {
        _entriesWithLocation = entriesWithLocation;
        _tagMap = {for (var tag in tags) tag.id: tag};
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _showEntryDetails(LogEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.7,
        minChildSize: 0.3,
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

              // Tags
              Text('Tags', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: entry.tags.map((tagId) {
                  final tag = _tagMap[tagId];
                  return Chip(
                    label: Text(tag?.label ?? tagId),
                    avatar: Icon(
                      Icons.label,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  );
                }).toList(),
              ),

              // Note
              if (entry.note != null && entry.note!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Note', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(entry.note!),
              ],

              // Location
              if (entry.locationLabel != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Location',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(entry.locationLabel!),
                  subtitle: Text(
                    'Lat: ${entry.latitude!.toStringAsFixed(4)}, '
                    'Lon: ${entry.longitude!.toStringAsFixed(4)}',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_entriesWithLocation.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Map'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No location data',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Enable location when creating entries\nto see them on the map',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Calculate center point based on entries
    double avgLat = 0;
    double avgLng = 0;
    for (var entry in _entriesWithLocation) {
      avgLat += entry.latitude!;
      avgLng += entry.longitude!;
    }
    avgLat /= _entriesWithLocation.length;
    avgLng /= _entriesWithLocation.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Map (${_entriesWithLocation.length} entries)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(avgLat, avgLng),
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.quicklog.app',
          ),
          MarkerLayer(
            markers: _entriesWithLocation.map((entry) {
              return Marker(
                point: LatLng(entry.latitude!, entry.longitude!),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => _showEntryDetails(entry),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Fit map to show all markers
          if (_entriesWithLocation.isNotEmpty) {
            final points = _entriesWithLocation
                .map((e) => LatLng(e.latitude!, e.longitude!))
                .toList();

            final bounds = LatLngBounds.fromPoints(points);
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(50),
              ),
            );
          }
        },
        child: const Icon(Icons.fit_screen),
      ),
    );
  }
}
