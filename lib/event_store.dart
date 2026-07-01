import 'package:uuid/uuid.dart';
import 'db.dart';
import 'event.dart';

const _uuid = Uuid();

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
}
