import 'package:flutter/material.dart';
import 'event.dart';
import 'event_store.dart';
import 'day_cell.dart';

const kBgColor = Color(0xFFf7c90f);
const kNearBlack = Color(0xFF2b2b2b);

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

  void _sortList(List<Event> list) {
    list.sort((a, b) {
      final at = a.time;
      final bt = b.time;
      if (at.isEmpty && bt.isEmpty) return 0;
      if (at.isEmpty) return 1;
      if (bt.isEmpty) return -1;
      return at.compareTo(bt);
    });
  }

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
      _sortList(list);
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
      _sortList(list);
      _selectedEventId = e.id;
      _editingEventId = e.id;
    });
  }

  void _onEventUpdated(Event e) {
    setState(() {
      final list = _eventsByDate[e.date];
      if (list != null) _sortList(list);
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

  Future<void> _onEventMoved(Event event, String newDateStr) async {
    if (event.date == newDateStr) return;
    final oldDate = event.date;
    setState(() {
      _eventsByDate[oldDate]?.removeWhere((e) => e.id == event.id);
      event.date = newDateStr;
      final list = _eventsByDate.putIfAbsent(newDateStr, () => []);
      list.add(event);
      _sortList(list);
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
        backgroundColor: kBgColor,
        body: LayoutBuilder(builder: (context, constraints) {
          // ~0.5cm padding, scales proportionally with window width
          final hPad = constraints.maxWidth * 0.012;
          final vPad = constraints.maxHeight * 0.008;
          return Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, vPad),
                  child: _buildGrid(topLeft, todayStr),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() => _weekOffset -= 4);
              _loadEvents();
            },
            icon: const Icon(Icons.chevron_left, color: kNearBlack),
          ),
          Expanded(
            child: Text(
              _headerText(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kNearBlack,
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
            icon: const Icon(Icons.chevron_right, color: kNearBlack),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(DateTime topLeft, String todayStr) {
    return Column(
      children: List.generate(5, (row) {
        int maxEvents = 0;
        for (int col = 0; col < 7; col++) {
          final day = topLeft.add(Duration(days: row * 7 + col));
          final count = _eventsByDate[_isoDate(day)]?.length ?? 0;
          if (count > maxEvents) maxEvents = count;
        }
        final flex = maxEvents > 5 ? maxEvents : 5;

        return Expanded(
          flex: flex,
          child: LayoutBuilder(builder: (context, constraints) {
            final cellWidth = constraints.maxWidth / 7;
            return Row(
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
            );
          }),
        );
      }),
    );
  }
}
