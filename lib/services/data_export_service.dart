import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quick_log_app/data/database_helper.dart';
import 'package:quick_log_app/models/log_entry.dart';
import 'package:quick_log_app/models/log_tag.dart';
import 'package:quick_log_app/services/home_widget_service.dart';

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
          .map(
            (tag) => {
              'id': tag.id,
              'label': tag.label,
              'category': tag.category.name,
              'usageCount': tag.usageCount,
            },
          )
          .toList(),
      'entries': entries
          .map(
            (entry) => {
              'id': entry.id,
              'createdAt': entry.createdAt.toIso8601String(),
              'note': entry.note,
              'tags': entry.tags,
              'latitude': entry.latitude,
              'longitude': entry.longitude,
              'locationLabel': entry.locationLabel,
              'source': entry.source.name,
              'reviewStatus': entry.reviewStatus.name,
              'visitStartedAt': entry.visitStartedAt?.toIso8601String(),
              'visitEndedAt': entry.visitEndedAt?.toIso8601String(),
              'visitDurationMinutes': entry.visitDurationMinutes,
            },
          )
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
      'ID,Created At,Source,Review Status,Visit Started At,Visit Ended At,Visit Duration Minutes,Tags,Note,Latitude,Longitude,Location Label',
    );

    // CSV data rows
    for (var entry in entries) {
      final tagLabels = entry.tags.map((id) => tagMap[id] ?? id).join('; ');
      final note = entry.note?.replaceAll('"', '""') ?? '';
      final locationLabel = entry.locationLabel?.replaceAll('"', '""') ?? '';

      buffer.writeln(
        '${entry.id ?? ""},'
        '"${entry.createdAt.toIso8601String()}",'
        '${entry.source.name},'
        '${entry.reviewStatus.name},'
        '"${entry.visitStartedAt?.toIso8601String() ?? ""}",'
        '"${entry.visitEndedAt?.toIso8601String() ?? ""}",'
        '${entry.visitDurationMinutes ?? ""},'
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
    await _shareExportData(
      content: await exportToJson(),
      fileName: 'quick_log_export.json',
      mimeType: 'application/json',
      subject: 'Quick Log Export',
      text: 'Quick Log data export',
    );
  }

  /// Share exported data as CSV
  Future<void> shareCsvExport() async {
    await _shareExportData(
      content: await exportToCsv(),
      fileName: 'quick_log_export.csv',
      mimeType: 'text/csv',
      subject: 'Quick Log Export',
      text: 'Quick Log data export (CSV)',
    );
  }

  /// Export tags only to JSON format (for LLM customization)
  Future<String> exportTagsToJson() async {
    final tags = await DatabaseHelper.instance.getAllTags();

    final exportData = {
      'metadata': {
        'appName': 'Quick Log',
        'exportVersion': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'tagsCount': tags.length,
        'exportType': 'tags_only',
      },
      'tags': tags
          .map(
            (tag) => {
              'id': tag.id,
              'label': tag.label,
              'category': tag.category.name,
              'usageCount': tag.usageCount,
            },
          )
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Share tags export as JSON
  Future<void> shareTagsExport() async {
    await _shareExportData(
      content: await exportTagsToJson(),
      fileName: 'quick_log_tags.json',
      mimeType: 'application/json',
      subject: 'Quick Log Tags Export',
      text: 'Quick Log tags export - customize with LLM and re-import',
    );
  }

  Future<void> _shareExportData({
    required String content,
    required String fileName,
    required String mimeType,
    required String subject,
    required String text,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(utf8.encode(content), mimeType: mimeType)],
        fileNameOverrides: [fileName],
        subject: subject,
        text: text,
      ),
    );
  }

  /// Import tags only from JSON file
  Future<ImportResult> importTagsFromJson() async {
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
      int tagsUpdated = 0;

      // Import tags
      if (data['tags'] != null) {
        final tagsData = data['tags'] as List<dynamic>;
        final existingTags = await DatabaseHelper.instance.getAllTags();
        final existingTagIds = existingTags.map((t) => t.id).toSet();

        for (var tagData in tagsData) {
          final tagId = tagData['id'] as String;
          final tag = LogTag(
            id: tagId,
            label: tagData['label'] as String,
            category: TagCategory.values.firstWhere(
              (e) => e.name == tagData['category'],
              orElse: () => TagCategory.custom,
            ),
            usageCount: tagData['usageCount'] as int? ?? 0,
          );

          if (existingTagIds.contains(tagId)) {
            // Update existing tag (label and category, preserve usage count)
            final existingTag = existingTags.firstWhere((t) => t.id == tagId);
            final updatedTag = tag.copyWith(usageCount: existingTag.usageCount);
            await DatabaseHelper.instance.insertTag(updatedTag);
            tagsUpdated++;
          } else {
            // Insert new tag
            await DatabaseHelper.instance.insertTag(tag);
            tagsImported++;
          }
        }
      } else {
        return ImportResult(
          success: false,
          message: 'Invalid file format: no tags found',
        );
      }

      return ImportResult(
        success: true,
        message: 'Imported $tagsImported new tags, updated $tagsUpdated tags',
        tagsImported: tagsImported,
        entriesImported: 0,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Import failed: ${e.toString()}',
      );
    }
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
            tags: ((entryData['tags'] as List<dynamic>?) ?? const [])
                .map((e) => e as String)
                .toList(),
            latitude: (entryData['latitude'] as num?)?.toDouble(),
            longitude: (entryData['longitude'] as num?)?.toDouble(),
            locationLabel: entryData['locationLabel'] as String?,
            source: EntrySource.values.firstWhere(
              (value) => value.name == entryData['source'],
              orElse: () => EntrySource.manual,
            ),
            reviewStatus: EntryReviewStatus.values.firstWhere(
              (value) => value.name == entryData['reviewStatus'],
              orElse: () => EntryReviewStatus.none,
            ),
            visitStartedAt: entryData['visitStartedAt'] != null
                ? DateTime.parse(entryData['visitStartedAt'] as String)
                : null,
            visitEndedAt: entryData['visitEndedAt'] != null
                ? DateTime.parse(entryData['visitEndedAt'] as String)
                : null,
            visitDurationMinutes: entryData['visitDurationMinutes'] as int?,
          );
          await DatabaseHelper.instance.insertEntry(entry);
          entriesImported++;
        }
      }

      if (entriesImported > 0) {
        await QuickLogHomeWidgetService.instance.sync();
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
