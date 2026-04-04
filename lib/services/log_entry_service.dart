import 'package:quick_log_app/data/database_helper.dart';
import 'package:quick_log_app/models/log_entry.dart';
import 'package:quick_log_app/services/home_widget_service.dart';

class LogEntryService {
  LogEntryService._();

  static final LogEntryService instance = LogEntryService._();

  Future<LogEntry> save(LogEntry entry) async {
    final id = await DatabaseHelper.instance.insertEntry(entry);
    final savedEntry = entry.copyWith(id: id);
    await QuickLogHomeWidgetService.instance.sync();
    return savedEntry;
  }
}
