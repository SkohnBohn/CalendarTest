import 'package:flutter/material.dart';
import 'event.dart';
import 'event_store.dart';
import 'event_bar.dart';

const _bgColor = Color(0xFFf7c90f);
const _nearBlack = Color(0xFF2b2b2b);
const _todayCircleColor = Color(0xFFFFE55C);

const _weekdayLabels = ['MO', 'TUE', 'WED', 'THU', 'FRI', 'SA', 'SUN'];

// Height of the O : X hover row inside EventBar
const _hoverRowH = 14.0;

class DayCell extends StatefulWidget {
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
  final VoidCallback onDoneEditing;
  final void Function(bool) onHoverChanged;
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
    required this.onDoneEditing,
    required this.onHoverChanged,
    required this.onEventMoved,
  });

  @override
  State<DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<DayCell> {
  // GlobalKey to measure the actual rendered content height (header + events)
  final _contentKey = GlobalKey();
  // Latest allocated height from LayoutBuilder (updated every build)
  double _allocatedHeight = double.infinity;

  Future<void> _handleTapEmpty(BuildContext context) async {
    widget.onClearSelection();
    final event = await createEvent(widget.dateStr);
    widget.onEventCreated(event);
  }

  // Called by EventBar on hover enter/exit. Only propagate true if the hover
  // row would actually overflow the allocated cell height.
  void _handleBarHover(bool hovered) {
    if (hovered) {
      final rb =
          _contentKey.currentContext?.findRenderObject() as RenderBox?;
      final contentH = rb?.size.height ?? 0.0;
      final wouldOverflow = contentH + _hoverRowH > _allocatedHeight;
      widget.onHoverChanged(wouldOverflow);
    } else {
      widget.onHoverChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekdayLabel = _weekdayLabels[widget.date.weekday - 1];

    return DragTarget<Event>(
      onWillAcceptWithDetails: (details) =>
          details.data.date != widget.dateStr,
      onAcceptWithDetails: (details) =>
          widget.onEventMoved(details.data, widget.dateStr),
      builder: (context, candidateData, rejectedData) {
        return LayoutBuilder(builder: (ctx, constraints) {
          // Store allocated height so _handleBarHover can compare against it
          _allocatedHeight = constraints.maxHeight;

          return GestureDetector(
            onTap: () => _handleTapEmpty(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: candidateData.isNotEmpty
                  ? _bgColor.withOpacity(0.7)
                  : _bgColor,
              child: Column(
                key: _contentKey,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 4, top: 2, bottom: 1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        widget.isToday
                            ? Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: _todayCircleColor,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${widget.date.day}',
                                  style: const TextStyle(
                                    color: _nearBlack,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : Text(
                                '${widget.date.day}',
                                style: const TextStyle(
                                  color: _nearBlack,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        if (widget.showWeekday) ...[
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: widget.events.map((event) {
                      final isSelected = event.id == widget.selectedEventId;
                      final isEditing = event.id == widget.editingEventId;
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
                            padding: const EdgeInsets.symmetric(horizontal: 4),
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
                            onDoneEditing: () {},
                            onHoverChanged: (_) {},
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () => widget.onSelectEvent(event.id),
                          child: EventBar(
                            key: ValueKey(event.id),
                            event: event,
                            isSelected: isSelected,
                            isEditing: isEditing,
                            onUpdated: () => widget.onEventUpdated(event),
                            onDeleted: () =>
                                widget.onEventDeleted(event.id, event.date),
                            onDoneEditing: widget.onDoneEditing,
                            onHoverChanged: _handleBarHover,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
