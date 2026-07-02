import 'package:uuid/uuid.dart';
import 'db.dart';
import 'event.dart';

const _uuid = Uuid();

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime? _parseUntilDate(String s) {
  final parts = s.trim().split('/');
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  var year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  if (year < 100) year += 2000;
  try {
    return DateTime(year, month, day);
  } catch (_) {
    return null;
  }
}

Future<List<Event>> fetchEventsForRange(
    String startDate, String endDate) async {
  final db = await getDb();
  final rows = await db.query(
    'events',
    where: 'date >= ? AND date <= ?',
    whereArgs: [startDate, endDate],
  );
  return rows.map(Event.fromMap).toList();
}

Future<Event> createEvent(String date) async {
  final db = await getDb();
  final event = Event(
    id: _uuid.v4(),
    date: date,
    time: '',
    text: '',
    notes: '',
    updatedAt: DateTime.now().toIso8601String(),
  );
  await db.insert('events', event.toMap());
  return event;
}

Future<void> updateEvent(Event event) async {
  final db = await getDb();
  event.updatedAt = DateTime.now().toIso8601String();
  await db.update('events', event.toMap(),
      where: 'id = ?', whereArgs: [event.id]);
}

Future<void> deleteEvent(String id) async {
  final db = await getDb();
  await db.delete('events', where: 'id = ?', whereArgs: [id]);
  // Also delete clones of this event
  await db.delete('events', where: 'parent_id = ?', whereArgs: [id]);
}

Future<List<Event>> applyRecurrence(Event event) async {
  final db = await getDb();
  // Remove old clones
  await db.delete('events', where: 'parent_id = ?', whereArgs: [event.id]);

  if (event.recurrenceType == 'none') return [];

  final DateTime? untilDate = _parseUntilDate(event.recurrenceUntil);
  if (untilDate == null) return [];

  DateTime start;
  try {
    start = DateTime.parse(event.date);
  } catch (_) {
    return [];
  }

  final clones = <Event>[];
  DateTime current = start;
  int safety = 0;

  while (safety < 2000) {
    safety++;
    DateTime next;
    switch (event.recurrenceType) {
      case 'weekly':
        next = current.add(const Duration(days: 7));
        break;
      case 'monthly':
        next = DateTime(current.year, current.month + 1, current.day);
        break;
      case 'yearly':
        next = DateTime(current.year + 1, current.month, current.day);
        break;
      case 'custom':
        final interval =
            event.recurrenceInterval > 0 ? event.recurrenceInterval : 1;
        next = current.add(Duration(days: interval));
        break;
      default:
        return clones;
    }
    if (next.isAfter(untilDate)) break;

    final clone = Event(
      id: _uuid.v4(),
      date: _isoDate(next),
      time: event.time,
      text: event.text,
      notes: event.notes,
      updatedAt: DateTime.now().toIso8601String(),
      parentId: event.id,
    );
    await db.insert('events', clone.toMap());
    clones.add(clone);
    current = next;
  }
  return clones;
}
