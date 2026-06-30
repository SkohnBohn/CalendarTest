import 'package:flutter/material.dart';
import 'event.dart';
import 'event_store.dart';
import 'event_bar.dart';

const _bgColor = Color(0xFFc9a300);
const _nearBlack = Color(0xFF2b2b2b);
const _lightGrey = Color(0xFFb0b0b0);

const _weekdayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

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
  });

  Future<void> _handleTapEmpty(BuildContext context) async {
    onClearSelection();
    final event = await createEvent(dateStr, '', '');
    onEventCreated(event);
  }

  @override
  Widget build(BuildContext context) {
    final weekdayLabel = _weekdayLabels[date.weekday - 1];

    return GestureDetector(
      onTap: () => _handleTapEmpty(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: _lightGrey.withOpacity(0.5), width: 0.5),
          color: _bgColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekday label
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Text(
                weekdayLabel,
                style: const TextStyle(
                  color: _lightGrey,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Day number
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: isToday
                  ? Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: _nearBlack,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${date.day}',
                        style: const TextStyle(
                          color: Colors.white,
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
                    onTap: () {
                      onSelectEvent(event.id);
                    },
                    child: EventBar(
                      event: event,
                      isSelected: isSelected,
                      isEditing: isEditing,
                      onUpdated: () => onEventUpdated(event),
                      onDeleted: () => onEventDeleted(event.id, event.date),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
