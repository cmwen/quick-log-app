class LogEntry {
  final int? id;
  final DateTime createdAt;
  final String? note;
  final List<String> tags;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;

  LogEntry({
    this.id,
    required this.createdAt,
    this.note,
    required this.tags,
    this.latitude,
    this.longitude,
    this.locationLabel,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'note': note,
      'tags': tags.join(','),
      'latitude': latitude,
      'longitude': longitude,
      'locationLabel': locationLabel,
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      id: map['id'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      note: map['note'] as String?,
      tags: (map['tags'] as String)
          .split(',')
          .where((t) => t.isNotEmpty)
          .toList(),
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      locationLabel: map['locationLabel'] as String?,
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
  }) {
    return LogEntry(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationLabel: locationLabel ?? this.locationLabel,
    );
  }
}
