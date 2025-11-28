import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quick_log_app/data/database_helper.dart';
import 'package:quick_log_app/models/log_entry.dart';
import 'package:quick_log_app/models/log_tag.dart';

class DataExportService {
  static final DataExportService instance = DataExportService._init();

  DataExportService._init();

  /// Export all data to JSON format (LLM-friendly with metadata)
  Future<String> exportToJson() async {
    final entries = await DatabaseHelper.instance.getAllEntries();
    final tags = await DatabaseHelper.instance.getAllTags();

    final exportData = {
      'metadata': {
        'appName': 'Quick Log',
        'exportVersion': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'entriesCount': entries.length,
        'tagsCount': tags.length,
      },
      'tags': tags
          .map((tag) => {
                'id': tag.id,
                'label': tag.label,
                'category': tag.category.name,
                'usageCount': tag.usageCount,
              })
          .toList(),
      'entries': entries
          .map((entry) => {
                'id': entry.id,
                'createdAt': entry.createdAt.toIso8601String(),
                'note': entry.note,
                'tags': entry.tags,
                'latitude': entry.latitude,
                'longitude': entry.longitude,
                'locationLabel': entry.locationLabel,
              })
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Export entries to CSV format
  Future<String> exportToCsv() async {
    final entries = await DatabaseHelper.instance.getAllEntries();
    final tags = await DatabaseHelper.instance.getAllTags();
    final tagMap = {for (var tag in tags) tag.id: tag.label};

    final buffer = StringBuffer();

    // CSV header
    buffer.writeln(
        'ID,Created At,Tags,Note,Latitude,Longitude,Location Label');

    // CSV data rows
    for (var entry in entries) {
      final tagLabels =
          entry.tags.map((id) => tagMap[id] ?? id).join('; ');
      final note = entry.note?.replaceAll('"', '""') ?? '';
      final locationLabel = entry.locationLabel?.replaceAll('"', '""') ?? '';

      buffer.writeln(
        '${entry.id ?? ""},'
        '"${entry.createdAt.toIso8601String()}",'
        '"$tagLabels",'
        '"$note",'
        '${entry.latitude ?? ""},'
        '${entry.longitude ?? ""},'
        '"$locationLabel"',
      );
    }

    return buffer.toString();
  }

  /// Share exported data as a file
  Future<void> shareJsonExport() async {
    final jsonData = await exportToJson();
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/quick_log_export_$timestamp.json');
    await file.writeAsString(jsonData);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Quick Log Export',
      text: 'Quick Log data export',
    );
  }

  /// Share exported data as CSV
  Future<void> shareCsvExport() async {
    final csvData = await exportToCsv();
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/quick_log_export_$timestamp.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Quick Log Export',
      text: 'Quick Log data export (CSV)',
    );
  }

  /// Import data from JSON file
  Future<ImportResult> importFromJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      return ImportResult(success: false, message: 'No file selected');
    }

    try {
      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      int tagsImported = 0;
      int entriesImported = 0;

      // Import tags - only add new tags, preserve existing ones
      if (data['tags'] != null) {
        final tagsData = data['tags'] as List<dynamic>;
        final existingTags = await DatabaseHelper.instance.getAllTags();
        final existingTagIds = existingTags.map((t) => t.id).toSet();

        for (var tagData in tagsData) {
          final tagId = tagData['id'] as String;
          // Only import tags that don't already exist to preserve usage counts
          if (!existingTagIds.contains(tagId)) {
            final tag = LogTag(
              id: tagId,
              label: tagData['label'] as String,
              category: TagCategory.values.firstWhere(
                (e) => e.name == tagData['category'],
                orElse: () => TagCategory.custom,
              ),
              usageCount: tagData['usageCount'] as int? ?? 0,
            );
            await DatabaseHelper.instance.insertTag(tag);
            tagsImported++;
          }
        }
      }

      // Import entries
      if (data['entries'] != null) {
        final entriesData = data['entries'] as List<dynamic>;
        for (var entryData in entriesData) {
          final entry = LogEntry(
            createdAt: DateTime.parse(entryData['createdAt'] as String),
            note: entryData['note'] as String?,
            tags: (entryData['tags'] as List<dynamic>)
                .map((e) => e as String)
                .toList(),
            latitude: (entryData['latitude'] as num?)?.toDouble(),
            longitude: (entryData['longitude'] as num?)?.toDouble(),
            locationLabel: entryData['locationLabel'] as String?,
          );
          await DatabaseHelper.instance.insertEntry(entry);
          entriesImported++;
        }
      }

      return ImportResult(
        success: true,
        message: 'Imported $tagsImported tags and $entriesImported entries',
        tagsImported: tagsImported,
        entriesImported: entriesImported,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Import failed: ${e.toString()}',
      );
    }
  }
}

class ImportResult {
  final bool success;
  final String message;
  final int tagsImported;
  final int entriesImported;

  ImportResult({
    required this.success,
    required this.message,
    this.tagsImported = 0,
    this.entriesImported = 0,
  });
}
