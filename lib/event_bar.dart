import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'event.dart';
import 'event_store.dart';

const _nearBlack = Color(0xFF2b2b2b);
const _barColor = Color(0xFFfef08a);
const _notesBgColor = Color(0xFFfce17a);
const _buttonColor = Color(0x42000000); // very faded

const _eventStyle = TextStyle(
  fontSize: 12,
  color: _nearBlack,
  height: 1.1,
  letterSpacing: -0.5,
);

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
  late TextEditingController _notesCtrl;
  late FocusNode _timeFocus;
  late FocusNode _textFocus;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _timeCtrl = TextEditingController(text: widget.event.time);
    _textCtrl = TextEditingController(text: widget.event.text);
    _notesCtrl = TextEditingController(text: widget.event.notes);
    _timeFocus = FocusNode()..addListener(_onFocusChange);
    _textFocus = FocusNode()..addListener(_onFocusChange);

    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _timeFocus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(EventBar old) {
    super.didUpdateWidget(old);
    if (!widget.isEditing) {
      if (_timeCtrl.text != widget.event.time) _timeCtrl.text = widget.event.time;
      if (_textCtrl.text != widget.event.text) _textCtrl.text = widget.event.text;
      if (_notesCtrl.text != widget.event.notes) _notesCtrl.text = widget.event.notes;
    }
    if (widget.isEditing && !old.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _timeFocus.requestFocus();
      });
    }
  }

  void _onFocusChange() {
    if (!_timeFocus.hasFocus && !_textFocus.hasFocus) {
      _save();
    }
  }

  Future<void> _save() async {
    widget.event.time = _timeCtrl.text.trim();
    widget.event.text = _textCtrl.text;
    widget.event.notes = _notesCtrl.text;
    await updateEvent(widget.event);
    widget.onUpdated();
  }

  void _showNotesDialog(BuildContext context) {
    final parts = [
      if (widget.event.time.isNotEmpty) widget.event.time,
      if (widget.event.text.isNotEmpty) widget.event.text,
    ];
    final headerText = parts.isEmpty ? '–' : parts.join('  ');

    showDialog(
      context: context,
      builder: (ctx) {
        void saveAndClose() {
          _save();
          if (ctx.mounted) Navigator.pop(ctx);
        }

        return Dialog(
          backgroundColor: _notesBgColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headerText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _nearBlack,
                  ),
                ),
                const SizedBox(height: 8),
                KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter) {
                      saveAndClose();
                    }
                  },
                  child: TextField(
                    controller: _notesCtrl,
                    maxLines: null,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13, color: _nearBlack),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '',
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: saveAndClose,
                    icon: const Icon(Icons.check,
                        color: _nearBlack, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timeFocus.removeListener(_onFocusChange);
    _textFocus.removeListener(_onFocusChange);
    _timeCtrl.dispose();
    _textCtrl.dispose();
    _notesCtrl.dispose();
    _timeFocus.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
        constraints: const BoxConstraints(minHeight: 22),
        decoration: BoxDecoration(
          color: _barColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main row: time + label
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 3),
                  child: widget.isEditing
                      ? SizedBox(
                          width: 38,
                          child: TextField(
                            controller: _timeCtrl,
                            focusNode: _timeFocus,
                            style: _eventStyle,
                            maxLines: 1,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 1),
                              border: InputBorder.none,
                              hintText: '',
                            ),
                            onChanged: (val) {
                              if (val.endsWith(' ')) {
                                _timeCtrl.text = val.trimRight();
                                _timeCtrl.selection =
                                    TextSelection.fromPosition(TextPosition(
                                        offset: _timeCtrl.text.length));
                                _textFocus.requestFocus();
                              }
                            },
                            onSubmitted: (_) => _textFocus.requestFocus(),
                          ),
                        )
                      : Text(
                          widget.event.time.isNotEmpty
                              ? widget.event.time
                              : 'hh:mm',
                          style: _eventStyle.copyWith(
                            color: widget.event.time.isNotEmpty
                                ? _nearBlack
                                : Colors.grey,
                          ),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 4, top: 3, bottom: 3),
                    child: widget.isEditing
                        ? TextField(
                            controller: _textCtrl,
                            focusNode: _textFocus,
                            maxLines: 1,
                            style: _eventStyle,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              hintText: '',
                            ),
                            onSubmitted: (_) => _save(),
                          )
                        : Text(
                            widget.event.text,
                            style: _eventStyle,
                            softWrap: true,
                            maxLines: 3,
                          ),
                  ),
                ),
              ],
            ),
            // Hover row: O and X below the time, very faded
            if (_isHovered)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _showNotesDialog(context),
                      child: const Icon(
                        Icons.radio_button_unchecked,
                        size: 11,
                        color: _buttonColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () async {
                        await deleteEvent(widget.event.id);
                        widget.onDeleted();
                      },
                      child: const Icon(
                        Icons.close,
                        size: 11,
                        color: _buttonColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
