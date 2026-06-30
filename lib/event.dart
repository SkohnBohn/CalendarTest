class Event {
  final String id;
  final String date; // ISO date e.g. 2026-06-30
  String time;       // raw text, unvalidated
  String text;
  String updatedAt;

  Event({
    required this.id,
    required this.date,
    required this.time,
    required this.text,
    required this.updatedAt,
  });

  factory Event.fromMap(Map<String, dynamic> m) => Event(
        id: m['id'] as String,
        date: m['date'] as String,
        time: m['time'] as String,
        text: m['text'] as String,
        updatedAt: m['updated_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'time': time,
        'text': text,
        'updated_at': updatedAt,
      };
}
