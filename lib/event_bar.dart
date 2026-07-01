import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'event.dart';
import 'event_store.dart';

const _nearBlack = Color(0xFF2b2b2b);
const _barColor = Color(0xFFe0c840);
const _notesBgColor = Color(0xFFfce17a);

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
  late TextEditingController _hourCtrl;
  late TextEditingController _minCtrl;
  late TextEditingController _textCtrl;
  late TextEditingController _notesCtrl;
  late FocusNode _hourFocus;
  late FocusNode _minFocus;
  late FocusNode _textFocus;

  List<String> _splitTime(String time) {
    if (time.contains(':')) {
      final parts = time.split(':');
      return [parts[0], parts.length > 1 ? parts[1] : ''];
    }
    return ['', ''];
  }

  String _combineTime() {
    final h = _hourCtrl.text;
    final m = _minCtrl.text;
    if (h.isEmpty && m.isEmpty) return '';
    return '$h:$m';
  }

  @override
  void initState() {
    super.initState();
    final parts = _splitTime(widget.event.time);
    _hourCtrl = TextEditingController(text: parts[0]);
    _minCtrl = TextEditingController(text: parts[1]);
    _textCtrl = TextEditingController(text: widget.event.text);
    _notesCtrl = TextEditingController(text: widget.event.notes);
    _hourFocus = FocusNode()..addListener(_onFocusChange);
    _minFocus = FocusNode()..addListener(_onFocusChange);
    _textFocus = FocusNode()..addListener(_onFocusChange);

    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _hourFocus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(EventBar old) {
    super.didUpdateWidget(old);
    if (!widget.isEditing) {
      final parts = _splitTime(widget.event.time);
      if (_hourCtrl.text != parts[0]) _hourCtrl.text = parts[0];
      if (_minCtrl.text != parts[1]) _minCtrl.text = parts[1];
      if (_textCtrl.text != widget.event.text) {
        _textCtrl.text = widget.event.text;
      }
      if (_notesCtrl.text != widget.event.notes) {
        _notesCtrl.text = widget.event.notes;
      }
    }
    if (widget.isEditing && !old.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _hourFocus.requestFocus();
      });
    }
  }

  void _onFocusChange() {
    if (!_hourFocus.hasFocus && !_minFocus.hasFocus && !_textFocus.hasFocus) {
      _save();
    }
  }

  Future<void> _save() async {
    widget.event.time = _combineTime();
    widget.event.text = _textCtrl.text;
    widget.event.notes = _notesCtrl.text;
    await updateEvent(widget.event);
    widget.onUpdated();
  }

  void _showNotesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _notesBgColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.event.time.isNotEmpty ? widget.event.time : '–',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _nearBlack,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                maxLines: null,
                autofocus: true,
                style: const TextStyle(fontSize: 13, color: _nearBlack),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Notizen...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _save();
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Speichern',
                    style: TextStyle(color: _nearBlack),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hourFocus.removeListener(_onFocusChange);
    _minFocus.removeListener(_onFocusChange);
    _textFocus.removeListener(_onFocusChange);
    _hourCtrl.dispose();
    _minCtrl.dispose();
    _textCtrl.dispose();
    _notesCtrl.dispose();
    _hourFocus.dispose();
    _minFocus.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  Widget _buildTimeDisplay() {
    return Text(
      widget.event.time.isNotEmpty ? widget.event.time : 'hh:mm',
      style: _eventStyle.copyWith(
        color: widget.event.time.isNotEmpty ? _nearBlack : Colors.grey,
      ),
    );
  }

  Widget _buildTimeEdit() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 22,
          child: TextField(
            controller: _hourCtrl,
            focusNode: _hourFocus,
            maxLength: 2,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: _eventStyle,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 1, vertical: 2),
              border: InputBorder.none,
              hintText: 'hh',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
              counterText: '',
            ),
            onChanged: (val) {
              if (val.length == 2) _minFocus.requestFocus();
            },
          ),
        ),
        const Text(':', style: _eventStyle),
        SizedBox(
          width: 22,
          child: TextField(
            controller: _minCtrl,
            focusNode: _minFocus,
            maxLength: 2,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: _eventStyle,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 1, vertical: 2),
              border: InputBorder.none,
              hintText: 'mm',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
              counterText: '',
            ),
            onSubmitted: (_) => _textFocus.requestFocus(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      constraints: const BoxConstraints(minHeight: 20),
      decoration: BoxDecoration(
        color: _barColor,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 2),
            child:
                widget.isEditing ? _buildTimeEdit() : _buildTimeDisplay(),
          ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 4, top: 2, bottom: 2),
              child: widget.isEditing
                  ? TextField(
                      controller: _textCtrl,
                      focusNode: _textFocus,
                      maxLines: null,
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
          if (widget.isSelected) ..[
            GestureDetector(
              onTap: () => _showNotesDialog(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                child: Icon(Icons.radio_button_unchecked,
                    size: 12, color: _nearBlack),
              ),
            ),
            GestureDetector(
              onTap: () async {
                await deleteEvent(widget.event.id);
                widget.onDeleted();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                child: Icon(Icons.close, size: 12, color: _nearBlack),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
