enum TagCategory { activity, location, mood, people, custom }

class LogTag {
  final String id;
  final String label;
  final TagCategory category;
  final int usageCount;

  LogTag({
    required this.id,
    required this.label,
    required this.category,
    this.usageCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'category': category.name,
      'usageCount': usageCount,
    };
  }

  factory LogTag.fromMap(Map<String, dynamic> map) {
    return LogTag(
      id: map['id'] as String,
      label: map['label'] as String,
      category: TagCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TagCategory.custom,
      ),
      usageCount: map['usageCount'] as int? ?? 0,
    );
  }

  LogTag copyWith({
    String? id,
    String? label,
    TagCategory? category,
    int? usageCount,
  }) {
    return LogTag(
      id: id ?? this.id,
      label: label ?? this.label,
      category: category ?? this.category,
      usageCount: usageCount ?? this.usageCount,
    );
  }
}
