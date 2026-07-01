import 'package:flutter/material.dart';
import 'event.dart';
import 'event_store.dart';
import 'event_bar.dart';
import 'calendar_page.dart' show kBgColor, kNearBlack;

const _lightGrey = Color(0xFFb0b0b0);
const _todayCircle = Color(0xFFfde68a); // light yellow for today
const _dragHover = Color(0xFFf0d840);

const _weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class DayCell extends StatelessWidget {
  final DateTime date;
  final String dateStr;
  final bool isToday;
  final List<Event> events;
  final String? selectedEventId;
  final String? editingEventId;
  final void Function(Event) onEventCreated;
  final void Function(Event) onEventUpdated;
  final void Function(String id, String date) onEventDeleted;
  final void Function(String? id) onSelectEvent;
  final VoidCallback onClearSelection;
  final Future<void> Function(Event, String newDateStr) onEventMoved;

  const DayCell({
    super.key,
    required this.date,
    required this.dateStr,
    required this.isToday,
    required this.events,
    required this.selectedEventId,
    required this.editingEventId,
    required this.onEventCreated,
    required this.onEventUpdated,
    required this.onEventDeleted,
    required this.onSelectEvent,
    required this.onClearSelection,
    required this.onEventMoved,
  });

  Future<void> _handleTapEmpty() async {
    onClearSelection();
    final event = await createEvent(dateStr);
    onEventCreated(event);
  }

  @override
  Widget build(BuildContext context) {
    final weekday = _weekdayShort[date.weekday - 1];

    return DragTarget<Event>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => onEventMoved(details.data, dateStr),
      builder: (context, candidateData, _) {
        final isHovered = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: _handleTapEmpty,
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              border:
                  Border.all(color: _lightGrey.withOpacity(0.5), width: 0.5),
              color: isHovered ? _dragHover : kBgColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day number + weekday label on same row
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 3, bottom: 1),
                  child: Row(
                    children: [
                      if (isToday)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: _todayCircle,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(
                              color: kNearBlack,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Text(
                          '${date.day}',
                          style: const TextStyle(
                            color: kNearBlack,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(width: 3),
                      Text(
                        weekday,
                        style: const TextStyle(
                          color: _lightGrey,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Event bars
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    physics: const NeverScrollableScrollPhysics(),
                    children: events.map((event) {
                      final isSelected = event.id == selectedEventId;
                      final isEditing = event.id == editingEventId;
                      return GestureDetector(
                        onTap: () => onSelectEvent(event.id),
                        child: EventBar(
                          key: ValueKey(event.id),
                          event: event,
                          isSelected: isSelected,
                          isEditing: isEditing,
                          onUpdated: () => onEventUpdated(event),
                          onDeleted: () =>
                              onEventDeleted(event.id, event.date),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
