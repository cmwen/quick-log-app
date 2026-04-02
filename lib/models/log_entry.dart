enum EntrySource { manual, autoVisit }

enum EntryReviewStatus { none, needsReview, confirmed }

class LogEntry {
  final int? id;
  final DateTime createdAt;
  final String? note;
  final List<String> tags;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;
  final EntrySource source;
  final EntryReviewStatus reviewStatus;
  final DateTime? visitStartedAt;
  final DateTime? visitEndedAt;
  final int? visitDurationMinutes;

  LogEntry({
    this.id,
    required this.createdAt,
    this.note,
    List<String>? tags,
    this.latitude,
    this.longitude,
    this.locationLabel,
    this.source = EntrySource.manual,
    this.reviewStatus = EntryReviewStatus.none,
    this.visitStartedAt,
    this.visitEndedAt,
    this.visitDurationMinutes,
  }) : tags = List.unmodifiable(tags ?? const <String>[]);

  bool get hasLocation => latitude != null && longitude != null;
  bool get isAutoTracked => source == EntrySource.autoVisit;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'note': note,
      'tags': tags.join(','),
      'latitude': latitude,
      'longitude': longitude,
      'locationLabel': locationLabel,
      'source': source.name,
      'reviewStatus': reviewStatus.name,
      'visitStartedAt': visitStartedAt?.millisecondsSinceEpoch,
      'visitEndedAt': visitEndedAt?.millisecondsSinceEpoch,
      'visitDurationMinutes': visitDurationMinutes,
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    final rawTags = map['tags'];
    return LogEntry(
      id: map['id'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      note: map['note'] as String?,
      tags: rawTags is String
          ? rawTags.split(',').where((t) => t.isNotEmpty).toList()
          : const <String>[],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationLabel: map['locationLabel'] as String?,
      source: EntrySource.values.firstWhere(
        (value) => value.name == map['source'],
        orElse: () => EntrySource.manual,
      ),
      reviewStatus: EntryReviewStatus.values.firstWhere(
        (value) => value.name == map['reviewStatus'],
        orElse: () => EntryReviewStatus.none,
      ),
      visitStartedAt: _readEpochMillis(map['visitStartedAt']),
      visitEndedAt: _readEpochMillis(map['visitEndedAt']),
      visitDurationMinutes: map['visitDurationMinutes'] as int?,
    );
  }

  LogEntry copyWith({
    int? id,
    DateTime? createdAt,
    String? note,
    List<String>? tags,
    double? latitude,
    double? longitude,
    String? locationLabel,
    EntrySource? source,
    EntryReviewStatus? reviewStatus,
    DateTime? visitStartedAt,
    DateTime? visitEndedAt,
    int? visitDurationMinutes,
  }) {
    return LogEntry(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationLabel: locationLabel ?? this.locationLabel,
      source: source ?? this.source,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      visitStartedAt: visitStartedAt ?? this.visitStartedAt,
      visitEndedAt: visitEndedAt ?? this.visitEndedAt,
      visitDurationMinutes: visitDurationMinutes ?? this.visitDurationMinutes,
    );
  }

  static DateTime? _readEpochMillis(Object? value) {
    final millis = value as int?;
    if (millis == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
}
