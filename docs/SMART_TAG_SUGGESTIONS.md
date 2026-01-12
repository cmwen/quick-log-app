# Smart Tag Suggestions Feature

## Overview

The Smart Tag Suggestions feature uses intelligent, rule-based pattern matching to recommend tags based on your usage history. It analyzes multiple contextual factors to predict which tags you're most likely to use at any given moment—without requiring AI or cloud services.

## How It Works

### Context Analysis

The system analyzes your historical entries from the last 90 days and scores each tag based on similarity to your current context:

1. **Time of Day Matching** (Weight: 2x)
   - Matches entries created at similar hours
   - Perfect match: Same hour (score 1.0)
   - Good match: Within 1 hour (score 0.8)
   - Acceptable: Within 2 hours (score 0.5)
   - Example: If you usually tag "Work" around 9am, it will be suggested at 9am

2. **Day of Week Patterns** (Weight: 1.5x)
   - Identifies weekly recurring activities
   - Perfect match: Same day of week (score 1.0)
   - Good match: Adjacent days (score 0.5)
   - Pattern match: Both weekdays or both weekend days (score 0.2-0.4)
   - Example: "Gym" tags on Mondays will be suggested on Mondays

3. **Day of Month Patterns** (Weight: 1x)
   - Detects monthly recurring events
   - Perfect match: Same day of month (score 1.0)
   - Good match: Within 1 day (score 0.3)
   - Example: "Bills" on the 1st will be suggested on the 1st

4. **Location Proximity** (Weight: 2.5x)
   - Uses GPS coordinates to find location-based patterns
   - Perfect match: < 100m away (score 1.0)
   - Good match: < 500m away (score 0.8)
   - Acceptable: < 1km away (score 0.5)
   - Example: "Coffee" at your favorite café location

5. **Recency Bonus** (Weight: 1x)
   - Prefers more recent patterns over old ones
   - Yesterday/Today: score 1.0
   - Within 3 days: score 0.8
   - Within 1 week: score 0.6
   - Older entries have progressively less influence

### Scoring Algorithm

For each historical entry:
1. Calculate similarity score for each context factor
2. Apply weighted scores (time and location are more important)
3. Average the weighted scores
4. Add the score to all tags in that entry

Final tag ranking:
- Tags are sorted by total score (descending)
- Tags with higher usage counts break ties
- Up to 8 top-scoring tags are suggested
- Only tags with significant scores (> 0.1 threshold) are shown

## User Interface

### Suggested Tags Section

When you open the Record tab, you'll see:

```
💡 Suggested for You
Based on time, day, and location patterns

[Tag] [Tag] [Tag] [Tag]
[Tag] [Tag] [Tag] [Tag]

─────────────────────────

Recently Used Tags
[Tag] [Tag] [Tag] [Tag]
```

- **Suggested Tags** appear first with a lightbulb icon
- **Recently Used Tags** appear below as a fallback
- Tap any tag to select/deselect it
- Both sections work together for maximum convenience

## Privacy & Performance

- **100% Local**: All analysis happens on your device
- **No AI Required**: Uses mathematical pattern matching
- **No Cloud**: Your data never leaves your device
- **Fast**: Suggestions load in milliseconds
- **Lightweight**: Minimal battery and memory impact

## Examples

### Example 1: Morning Commute
**Scenario**: It's 8:30am on Monday, you're at the train station

**Historical Pattern**:
- Last Monday 8:25am: Tagged "Commute", "Reading"
- Last week 8:30am: Tagged "Commute", "Podcast"
- Two weeks ago 8:35am: Tagged "Commute"

**Suggested Tags**: "Commute", "Reading", "Podcast"
- High score due to: Time match (8:30am), Day match (Monday), Location match

### Example 2: Evening Workout
**Scenario**: It's 6pm on Wednesday, you're at the gym

**Historical Pattern**:
- Last Wednesday 6pm: Tagged "Gym", "Exercise", "Motivated"
- Last Friday 6:15pm: Tagged "Gym", "Exercise"
- Last week same location: Tagged "Gym"

**Suggested Tags**: "Gym", "Exercise", "Motivated"
- High score due to: Time match (6pm), Location match (gym), Recency

### Example 3: Weekend Brunch
**Scenario**: It's 11am on Saturday, you're at your favorite café

**Historical Pattern**:
- Last Saturday 11:15am at café: Tagged "Brunch", "Friends", "Happy"
- Two weeks ago Saturday 10:45am at café: Tagged "Brunch", "Café"
- Last Sunday 11am at café: Tagged "Coffee", "Happy"

**Suggested Tags**: "Brunch", "Café", "Friends", "Happy"
- High score due to: Weekend pattern, Location match, Time match

## Technical Implementation

### Files Modified
- `lib/services/tag_suggestion_service.dart` - New service with scoring algorithm
- `lib/screens/main_screen.dart` - UI integration and data loading
- `test/tag_suggestion_service_test.dart` - Comprehensive test suite

### Key Methods

**`TagSuggestionService.getSuggestedTags()`**
```dart
List<LogTag> getSuggestedTags({
  required List<LogEntry> historicalEntries,
  required List<LogTag> allTags,
  required DateTime currentTime,
  double? currentLatitude,
  double? currentLongitude,
})
```

### Database Schema
No schema changes required! The feature uses existing tables:
- `entries` - Historical log entries with timestamps and location
- `tags` - Tag definitions with usage counts

### Performance Considerations
- Analyzes last 90 days of entries (configurable)
- Haversine distance calculation for location matching
- O(n × m) complexity where n = historical entries, m = unique tags
- Typically completes in < 100ms for 1000 entries

## Testing

Run the test suite:
```bash
flutter test test/tag_suggestion_service_test.dart
```

Test coverage includes:
- Empty historical data handling
- Time-of-day pattern matching
- Location-based suggestions
- Day-of-week patterns
- Recency scoring
- Maximum suggestion limit
- Entries without location data

All 8 tests pass successfully ✅

## Future Enhancements

Potential improvements for future versions:
1. **Configurable Weights**: Let users adjust importance of different factors
2. **Learning Rate**: Adapt to changing patterns over time
3. **Multi-Tag Patterns**: Suggest tag combinations that often appear together
4. **Confidence Scores**: Show how confident each suggestion is
5. **Negative Patterns**: Learn what tags NOT to suggest in certain contexts
6. **Manual Overrides**: Let users pin favorite tags to always appear
7. **Statistics Dashboard**: Visualize patterns and suggestion accuracy

## Troubleshooting

**Q: I don't see any suggestions**
- Suggestions require at least a few historical entries (recommended: 10+)
- Try using the app regularly for a week to build up patterns
- Check that you're using tags consistently

**Q: Suggestions don't seem relevant**
- The algorithm needs time to learn your patterns
- Suggestions improve with more data
- Try using location tracking for better context

**Q: Can I disable this feature?**
- Suggestions are non-intrusive and appear above recently used tags
- If no suggestions are available, only recently used tags show
- You can always use "See all tags" to browse the complete list

## Related Documentation

- [QUICK_LOG_README.md](../QUICK_LOG_README.md) - Main app documentation
- [FEATURE_RELEASE_v1.2.0.md](../FEATURE_RELEASE_v1.2.0.md) - Release notes
- [API Documentation](tag_suggestion_service.dart) - Source code with detailed comments
