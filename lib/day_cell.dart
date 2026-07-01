import 'package:flutter/material.dart';
import 'event.dart';
import 'event_store.dart';
import 'event_bar.dart';

const _bgColor = Color(0xFFf7c90f);
const _nearBlack = Color(0xFF2b2b2b);
const _lightGrey = Color(0xFFb0b0b0);
const _todayCircleColor = Color(0xFFFFE55C);

const _weekdayLabels = ['MO', 'TUE', 'WED', 'THU', 'FRI', 'SA', 'SUN'];

class DayCell extends StatelessWidget {
  final DateTime date;
  final String dateStr;
  final bool isToday;
  final bool showWeekday;
  final List<Event> events;
  final String? selectedEventId;
  final String? editingEventId;
  final void Function(Event) onEventCreated;
  final void Function(Event) onEventUpdated;
  final void Function(String id, String date) onEventDeleted;
  final void Function(String? id) onSelectEvent;
  final VoidCallback onClearSelection;
  final Future<void> Function(Event, String) onEventMoved;

  const DayCell({
    super.key,
    required this.date,
    required this.dateStr,
    required this.isToday,
    required this.showWeekday,
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

  Future<void> _handleTapEmpty(BuildContext context) async {
    onClearSelection();
    final event = await createEvent(dateStr);
    onEventCreated(event);
  }

  @override
  Widget build(BuildContext context) {
    final weekdayLabel = _weekdayLabels[date.weekday - 1];

    return DragTarget<Event>(
      onWillAcceptWithDetails: (details) => details.data.date != dateStr,
      onAcceptWithDetails: (details) => onEventMoved(details.data, dateStr),
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () => _handleTapEmpty(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: candidateData.isNotEmpty
                ? _bgColor.withOpacity(0.7)
                : _bgColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 2, bottom: 1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      isToday
                          ? Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: _todayCircleColor,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${date.day}',
                                style: const TextStyle(
                                  color: _nearBlack,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Text(
                              '${date.day}',
                              style: const TextStyle(
                                color: _nearBlack,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      if (showWeekday) ...[  
                        const SizedBox(width: 3),
                        Text(
                          weekdayLabel,
                          style: const TextStyle(
                            color: _nearBlack,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Events – no scrolling, column grows with content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: events.map((event) {
                    final isSelected = event.id == selectedEventId;
                    final isEditing = event.id == editingEventId;
                    return Draggable<Event>(
                      key: ValueKey('drag_${event.id}'),
                      data: event,
                      feedback: Material(
                        elevation: 4,
                        color: Colors.transparent,
                        child: Container(
                          width: 120,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFFfef08a),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${event.time} ${event.text}'.trim(),
                            style: const TextStyle(
                                fontSize: 11, color: _nearBlack),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: EventBar(
                          key: ValueKey('shadow_${event.id}'),
                          event: event,
                          isSelected: false,
                          isEditing: false,
                          onUpdated: () {},
                          onDeleted: () {},
                        ),
                      ),
                      child: GestureDetector(
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
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
