class Event {
  final String id;
  String date;
  String time;
  String text;
  String notes;
  String updatedAt;
  String recurrenceType;     // 'none' | 'weekly' | 'monthly' | 'yearly' | 'custom'
  int recurrenceInterval;    // days between for 'custom'
  String recurrenceUntil;    // DD/MM/YY input stored as-is
  String parentId;           // '' for master/standalone, parent event id for clones

  Event({
    required this.id,
    required this.date,
    required this.time,
    required this.text,
    this.notes = '',
    required this.updatedAt,
    this.recurrenceType = 'none',
    this.recurrenceInterval = 0,
    this.recurrenceUntil = '',
    this.parentId = '',
  });

  factory Event.fromMap(Map<String, dynamic> m) => Event(
        id: m['id'] as String,
        date: m['date'] as String,
        time: m['time'] as String,
        text: m['text'] as String,
        notes: (m['notes'] as String?) ?? '',
        updatedAt: m['updated_at'] as String,
        recurrenceType: (m['recurrence_type'] as String?) ?? 'none',
        recurrenceInterval: (m['recurrence_interval'] as int?) ?? 0,
        recurrenceUntil: (m['recurrence_until'] as String?) ?? '',
        parentId: (m['parent_id'] as String?) ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'time': time,
        'text': text,
        'notes': notes,
        'updated_at': updatedAt,
        'recurrence_type': recurrenceType,
        'recurrence_interval': recurrenceInterval,
        'recurrence_until': recurrenceUntil,
        'parent_id': parentId,
      };
}
