class Event {
  final String id;
  String date;
  String time;
  String text;
  String notes;
  String updatedAt;

  Event({
    required this.id,
    required this.date,
    required this.time,
    required this.text,
    required this.notes,
    required this.updatedAt,
  });

  factory Event.fromMap(Map<String, dynamic> m) => Event(
        id: m['id'] as String,
        date: m['date'] as String,
        time: m['time'] as String,
        text: m['text'] as String,
        notes: m['notes'] as String? ?? '',
        updatedAt: m['updated_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'time': time,
        'text': text,
        'notes': notes,
        'updated_at': updatedAt,
      };
}
