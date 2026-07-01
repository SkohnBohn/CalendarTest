import 'package:flutter/material.dart';
import 'event.dart';
import 'event_store.dart';
import 'day_cell.dart';

const _bgColor = Color(0xFFf7c90f);
const _nearBlack = Color(0xFF2b2b2b);

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int _weekOffset = 0;
  Map<String, List<Event>> _eventsByDate = {};
  String? _selectedEventId;
  String? _editingEventId;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  DateTime get _topLeftDay {
    final today = DateTime.now();
    final mondayThisWeek = today.subtract(Duration(days: today.weekday - 1));
    return mondayThisWeek.add(Duration(days: _weekOffset * 7));
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadEvents() async {
    final start = _topLeftDay;
    final end = start.add(const Duration(days: 28));
    final events = await fetchEventsForRange(_isoDate(start), _isoDate(end));
    final map = <String, List<Event>>{};
    for (final e in events) {
      map.putIfAbsent(e.date, () => []).add(e);
    }
    for (final list in map.values) {
      _sortEvents(list);
    }
    if (mounted) setState(() => _eventsByDate = map);
  }

  bool _isValidTime(String t) {
    if (t.isEmpty) return false;
    final parts = t.split(':');
    if (parts.length != 2) return false;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    return h != null && m != null;
  }

  void _sortEvents(List<Event> list) {
    list.sort((a, b) {
      final aValid = _isValidTime(a.time);
      final bValid = _isValidTime(b.time);
      if (aValid && bValid) return a.time.compareTo(b.time);
      if (aValid) return -1;
      if (bValid) return 1;
      return 0;
    });
  }

  String _headerText() {
    final d = _topLeftDay;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  void _onEventCreated(Event e) {
    setState(() {
      final list = _eventsByDate.putIfAbsent(e.date, () => []);
      list.add(e);
      _sortEvents(list);
      _selectedEventId = e.id;
      _editingEventId = e.id;
    });
  }

  void _onEventUpdated(Event e) {
    setState(() {
      final list = _eventsByDate[e.date];
      if (list != null) _sortEvents(list);
    });
  }

  void _onEventDeleted(String id, String date) {
    setState(() {
      _eventsByDate[date]?.removeWhere((e) => e.id == id);
      if (_selectedEventId == id) _selectedEventId = null;
      if (_editingEventId == id) _editingEventId = null;
    });
  }

  void _onSelectEvent(String? id) {
    setState(() {
      _selectedEventId = id;
      _editingEventId = id;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedEventId = null;
      _editingEventId = null;
    });
  }

  Future<void> _onEventMoved(Event event, String newDate) async {
    if (event.date == newDate) return;
    final oldDate = event.date;
    setState(() {
      _eventsByDate[oldDate]?.removeWhere((e) => e.id == event.id);
      event.date = newDate;
      final list = _eventsByDate.putIfAbsent(newDate, () => []);
      if (!list.any((e) => e.id == event.id)) list.add(event);
      _sortEvents(list);
    });
    await updateEvent(event);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayStr = _isoDate(today);
    final topLeft = _topLeftDay;

    return GestureDetector(
      onTap: _clearSelection,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildGrid(topLeft, todayStr)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() => _weekOffset -= 4);
              _loadEvents();
            },
            icon: const Icon(Icons.chevron_left, color: _nearBlack),
          ),
          Expanded(
            child: Text(
              _headerText(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _nearBlack,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _weekOffset += 4);
              _loadEvents();
            },
            icon: const Icon(Icons.chevron_right, color: _nearBlack),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(DateTime topLeft, String todayStr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 19),
      child: LayoutBuilder(builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 7;
        return Column(
          children: List.generate(4, (row) {
            int maxEvents = 0;
            for (int col = 0; col < 7; col++) {
              final day = topLeft.add(Duration(days: row * 7 + col));
              final count = _eventsByDate[_isoDate(day)]?.length ?? 0;
              if (count > maxEvents) maxEvents = count;
            }
            // flex represents content height: 24px per event + 30px header, min 80
            final int flex = (maxEvents * 24 + 30).clamp(80, 9999);

            return Expanded(
              flex: flex,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(7, (col) {
                  final day = topLeft.add(Duration(days: row * 7 + col));
                  final dateStr = _isoDate(day);
                  final events =
                      List<Event>.from(_eventsByDate[dateStr] ?? []);
                  return SizedBox(
                    width: cellWidth,
                    child: DayCell(
                      date: day,
                      dateStr: dateStr,
                      isToday: dateStr == todayStr,
                      events: events,
                      showWeekday: row == 0,
                      selectedEventId: _selectedEventId,
                      editingEventId: _editingEventId,
                      onEventCreated: _onEventCreated,
                      onEventUpdated: _onEventUpdated,
                      onEventDeleted: _onEventDeleted,
                      onSelectEvent: _onSelectEvent,
                      onClearSelection: _clearSelection,
                      onEventMoved: _onEventMoved,
                    ),
                  );
                }),
              ),
            );
          }),
        );
      }),
    );
  }
}
