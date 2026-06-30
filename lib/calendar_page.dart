import 'package:flutter/material.dart';
import 'event.dart';
import 'event_store.dart';
import 'day_cell.dart';

const _bgColor = Color(0xFFc9a300);
const _nearBlack = Color(0xFF2b2b2b);
const _lightGrey = Color(0xFFb0b0b0);

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // Offset in weeks from the "base" week (week containing today)
  int _weekOffset = 0;

  // All loaded events keyed by ISO date string
  Map<String, List<Event>> _eventsByDate = {};

  // Currently selected event id (for showing X button)
  String? _selectedEventId;

  // Currently editing event id
  String? _editingEventId;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  DateTime get _topLeftDay {
    final today = DateTime.now();
    // Monday of the week containing today
    final mondayThisWeek =
        today.subtract(Duration(days: today.weekday - 1));
    return mondayThisWeek.add(Duration(days: _weekOffset * 7));
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadEvents() async {
    final start = _topLeftDay;
    final end = start.add(const Duration(days: 34));
    final events =
        await fetchEventsForRange(_isoDate(start), _isoDate(end));
    final map = <String, List<Event>>{};
    for (final e in events) {
      map.putIfAbsent(e.date, () => []).add(e);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.time.compareTo(b.time));
    }
    if (mounted) setState(() => _eventsByDate = map);
  }

  String _headerText() {
    final d = _topLeftDay;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  void _onEventCreated(Event e) {
    setState(() {
      final list = _eventsByDate.putIfAbsent(e.date, () => []);
      list.add(e);
      list.sort((a, b) => a.time.compareTo(b.time));
      _selectedEventId = e.id;
      _editingEventId = e.id;
    });
  }

  void _onEventUpdated(Event e) {
    setState(() {
      final list = _eventsByDate[e.date];
      if (list != null) {
        list.sort((a, b) => a.time.compareTo(b.time));
      }
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
              setState(() => _weekOffset--);
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
              setState(() => _weekOffset++);
              _loadEvents();
            },
            icon: const Icon(Icons.chevron_right, color: _nearBlack),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(DateTime topLeft, String todayStr) {
    return LayoutBuilder(builder: (context, constraints) {
      final cellWidth = constraints.maxWidth / 7;

      return Column(
        children: List.generate(5, (row) {
          // Find max events in this row to determine row height scaling
          int maxEvents = 0;
          for (int col = 0; col < 7; col++) {
            final day = topLeft.add(Duration(days: row * 7 + col));
            final dateStr = _isoDate(day);
            final count = _eventsByDate[dateStr]?.length ?? 0;
            if (count > maxEvents) maxEvents = count;
          }
          // Base height per cell; if >5 events, row grows
          final int displayedEvents = maxEvents > 5 ? maxEvents : 5;

          return Expanded(
            flex: displayedEvents,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(7, (col) {
                final day = topLeft.add(Duration(days: row * 7 + col));
                final dateStr = _isoDate(day);
                final events = List<Event>.from(
                    _eventsByDate[dateStr] ?? []);
                return SizedBox(
                  width: cellWidth,
                  child: DayCell(
                    date: day,
                    dateStr: dateStr,
                    isToday: dateStr == todayStr,
                    events: events,
                    selectedEventId: _selectedEventId,
                    editingEventId: _editingEventId,
                    onEventCreated: _onEventCreated,
                    onEventUpdated: _onEventUpdated,
                    onEventDeleted: _onEventDeleted,
                    onSelectEvent: _onSelectEvent,
                    onClearSelection: _clearSelection,
                  ),
                );
              }),
            ),
          );
        }),
      );
    });
  }
}
