import 'package:flutter/material.dart';
import 'package:quick_log_app/models/log_tag.dart';

class TagChipWidget extends StatelessWidget {
  final LogTag tag;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showClose;

  const TagChipWidget({
    super.key,
    required this.tag,
    required this.isSelected,
    required this.onTap,
    this.showClose = false,
  });

  Color _getCategoryColor(BuildContext context, TagCategory category) {
    switch (category) {
      case TagCategory.activity:
        return Colors.blue.shade100;
      case TagCategory.location:
        return Colors.green.shade100;
      case TagCategory.mood:
        return Colors.orange.shade100;
      case TagCategory.people:
        return Colors.purple.shade100;
      case TagCategory.custom:
        return Colors.grey.shade100;
    }
  }

  Color _getTextColor(TagCategory category) {
    switch (category) {
      case TagCategory.activity:
        return Colors.blue.shade900;
      case TagCategory.location:
        return Colors.green.shade900;
      case TagCategory.mood:
        return Colors.orange.shade900;
      case TagCategory.people:
        return Colors.purple.shade900;
      case TagCategory.custom:
        return Colors.grey.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(tag.label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: _getCategoryColor(context, tag.category),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : _getTextColor(tag.category),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      deleteIcon: showClose ? const Icon(Icons.close, size: 18) : null,
      onDeleted: showClose ? onTap : null,
      showCheckmark: !showClose,
    );
  }
}
