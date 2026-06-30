import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'event.dart';
import 'event_store.dart';

const _nearBlack = Color(0xFF2b2b2b);
const _barColor = Color(0xFFe0c840); // slightly lighter yellow-gold for bars

class EventBar extends StatefulWidget {
  final Event event;
  final bool isSelected;
  final bool isEditing;
  final VoidCallback onUpdated;
  final VoidCallback onDeleted;

  const EventBar({
    super.key,
    required this.event,
    required this.isSelected,
    required this.isEditing,
    required this.onUpdated,
    required this.onDeleted,
  });

  @override
  State<EventBar> createState() => _EventBarState();
}

class _EventBarState extends State<EventBar> {
  late TextEditingController _timeCtrl;
  late TextEditingController _textCtrl;
  late FocusNode _timeFocus;
  late FocusNode _textFocus;

  @override
  void initState() {
    super.initState();
    _timeCtrl = TextEditingController(text: widget.event.time);
    _textCtrl = TextEditingController(text: widget.event.text);
    _timeFocus = FocusNode()..addListener(_onFocusChange);
    _textFocus = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(EventBar old) {
    super.didUpdateWidget(old);
    if (!widget.isEditing) {
      // sync display text when not editing
      if (_timeCtrl.text != widget.event.time) {
        _timeCtrl.text = widget.event.time;
      }
      if (_textCtrl.text != widget.event.text) {
        _textCtrl.text = widget.event.text;
      }
    }
    if (widget.isEditing && !old.isEditing) {
      // newly selected: focus the text field
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _textFocus.requestFocus();
      });
    }
  }

  void _onFocusChange() {
    if (!_timeFocus.hasFocus && !_textFocus.hasFocus) {
      _save();
    }
  }

  Future<void> _save() async {
    widget.event.time = _timeCtrl.text;
    widget.event.text = _textCtrl.text;
    await updateEvent(widget.event);
    widget.onUpdated();
  }

  @override
  void dispose() {
    _timeFocus.removeListener(_onFocusChange);
    _textFocus.removeListener(_onFocusChange);
    _timeCtrl.dispose();
    _textCtrl.dispose();
    _timeFocus.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      height: 20,
      decoration: BoxDecoration(
        color: _barColor,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          // Time field
          SizedBox(
            width: 36,
            child: widget.isEditing
                ? TextField(
                    controller: _timeCtrl,
                    focusNode: _timeFocus,
                    style: const TextStyle(
                        fontSize: 9, color: _nearBlack, height: 1),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      border: InputBorder.none,
                      hintText: 'hh:mm',
                      hintStyle: TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                    onSubmitted: (_) => _textFocus.requestFocus(),
                  )
                : Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      widget.event.time,
                      style: const TextStyle(
                          fontSize: 9, color: _nearBlack),
                      overflow: TextOverflow.clip,
                    ),
                  ),
          ),
          // Text field
          Expanded(
            child: widget.isEditing
                ? TextField(
                    controller: _textCtrl,
                    focusNode: _textFocus,
                    style: const TextStyle(
                        fontSize: 9, color: _nearBlack, height: 1),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      border: InputBorder.none,
                      hintText: 'label',
                      hintStyle: TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                    onSubmitted: (_) => _save(),
                  )
                : Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      widget.event.text,
                      style: const TextStyle(
                          fontSize: 9, color: _nearBlack),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
          // X delete button (only when selected)
          if (widget.isSelected)
            GestureDetector(
              onTap: () async {
                await deleteEvent(widget.event.id);
                widget.onDeleted();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Icon(Icons.close, size: 12, color: _nearBlack),
              ),
            ),
        ],
      ),
    );
  }
}
