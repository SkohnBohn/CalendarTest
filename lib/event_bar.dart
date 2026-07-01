import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'event.dart';
import 'event_store.dart';
import 'calendar_page.dart' show kBgColor, kNearBlack;

const _barColor = Color(0xFFf0d830);
const _notesBackground = Color(0xFFfbdf50); // slightly lighter than bg
const _lightGrey = Color(0xFFb0b0b0);

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
  late TextEditingController _hhCtrl;
  late TextEditingController _mmCtrl;
  late TextEditingController _textCtrl;
  late FocusNode _hhFocus;
  late FocusNode _mmFocus;
  late FocusNode _textFocus;
  bool _saving = false;

  String get _storedHh {
    final parts = widget.event.time.split(':');
    return parts.isNotEmpty ? parts[0] : '';
  }

  String get _storedMm {
    final parts = widget.event.time.split(':');
    return parts.length > 1 ? parts[1] : '';
  }

  @override
  void initState() {
    super.initState();
    _hhCtrl = TextEditingController(text: _storedHh);
    _mmCtrl = TextEditingController(text: _storedMm);
    _textCtrl = TextEditingController(text: widget.event.text);

    _hhFocus = FocusNode()..addListener(_onFocusChange);
    _mmFocus = FocusNode()..addListener(_onFocusChange);
    _textFocus = FocusNode()..addListener(_onFocusChange);

    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hhFocus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(EventBar old) {
    super.didUpdateWidget(old);
    if (!widget.isEditing && old.isEditing) {
      // sync display after editing ends
      final hh = _storedHh;
      final mm = _storedMm;
      if (_hhCtrl.text != hh) _hhCtrl.text = hh;
      if (_mmCtrl.text != mm) _mmCtrl.text = mm;
      if (_textCtrl.text != widget.event.text) {
        _textCtrl.text = widget.event.text;
      }
    }
    if (widget.isEditing && !old.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hhFocus.requestFocus();
      });
    }
  }

  void _onFocusChange() {
    if (!_hhFocus.hasFocus && !_mmFocus.hasFocus && !_textFocus.hasFocus) {
      _save();
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    _saving = true;
    final hh = _hhCtrl.text;
    final mm = _mmCtrl.text;
    widget.event.time =
        (hh.isEmpty && mm.isEmpty) ? '' : '${hh.padLeft(2, '0')}:${mm.padLeft(2, '0')}';
    widget.event.text = _textCtrl.text;
    await updateEvent(widget.event);
    widget.onUpdated();
    _saving = false;
  }

  void _openNotes(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => _NotesDialog(event: widget.event, onSaved: widget.onUpdated),
    );
  }

  @override
  void dispose() {
    _hhFocus.removeListener(_onFocusChange);
    _mmFocus.removeListener(_onFocusChange);
    _textFocus.removeListener(_onFocusChange);
    _hhCtrl.dispose();
    _mmCtrl.dispose();
    _textCtrl.dispose();
    _hhFocus.dispose();
    _mmFocus.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  Widget _buildTimeDisplay() {
    if (widget.isEditing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            child: TextField(
              controller: _hhCtrl,
              focusNode: _hhFocus,
              maxLength: 2,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                  fontSize: 11, color: kNearBlack, height: 1, letterSpacing: -0.5),
              decoration: const InputDecoration(
                isDense: true,
                counterText: '',
                contentPadding: EdgeInsets.symmetric(horizontal: 1, vertical: 2),
                border: InputBorder.none,
                hintText: 'hh',
                hintStyle: TextStyle(fontSize: 11, color: _lightGrey),
              ),
              onChanged: (v) {
                if (v.length == 2) _mmFocus.requestFocus();
              },
            ),
          ),
          const Text(':', style: TextStyle(fontSize: 11, color: kNearBlack, height: 1)),
          SizedBox(
            width: 20,
            child: TextField(
              controller: _mmCtrl,
              focusNode: _mmFocus,
              maxLength: 2,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                  fontSize: 11, color: kNearBlack, height: 1, letterSpacing: -0.5),
              decoration: const InputDecoration(
                isDense: true,
                counterText: '',
                contentPadding: EdgeInsets.symmetric(horizontal: 1, vertical: 2),
                border: InputBorder.none,
                hintText: 'mm',
                hintStyle: TextStyle(fontSize: 11, color: _lightGrey),
              ),
              onSubmitted: (_) => _textFocus.requestFocus(),
            ),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        widget.event.time,
        style: const TextStyle(
            fontSize: 11, color: kNearBlack, letterSpacing: -0.5),
      ),
    );
  }

  Widget _buildTextDisplay() {
    if (widget.isEditing) {
      return TextField(
        controller: _textCtrl,
        focusNode: _textFocus,
        maxLines: null,
        style: const TextStyle(
            fontSize: 11, color: kNearBlack, height: 1.2, letterSpacing: -0.5),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          border: InputBorder.none,
          hintText: '',
          hintStyle: TextStyle(fontSize: 11, color: _lightGrey),
        ),
        onSubmitted: (_) => _save(),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 1, bottom: 1),
      child: Text(
        widget.event.text,
        style: const TextStyle(
            fontSize: 11, color: kNearBlack, letterSpacing: -0.5),
        softWrap: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      constraints: const BoxConstraints(minHeight: 22),
      decoration: BoxDecoration(
        color: _barColor,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time (hh:mm)
          _buildTimeDisplay(),
          const SizedBox(width: 2),
          // Text label
          Expanded(child: _buildTextDisplay()),
          // Notes button (o) — only when selected
          if (widget.isSelected)
            GestureDetector(
              onTap: () => _openNotes(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
                child: Text('○',
                    style: TextStyle(fontSize: 13, color: kNearBlack)),
              ),
            ),
          // Delete button (x) — only when selected
          if (widget.isSelected)
            GestureDetector(
              onTap: () async {
                await deleteEvent(widget.event.id);
                widget.onDeleted();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
                child: Icon(Icons.close, size: 13, color: kNearBlack),
              ),
            ),
        ],
      ),
    );

    return LongPressDraggable<Event>(
      data: widget.event,
      delay: const Duration(milliseconds: 300),
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.85,
          child: Container(
            width: 120,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(
              color: _barColor,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Text(
              '${widget.event.time}  ${widget.event.text}',
              style: const TextStyle(
                  fontSize: 11, color: kNearBlack, letterSpacing: -0.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: bar),
      child: bar,
    );
  }
}

class _NotesDialog extends StatefulWidget {
  final Event event;
  final VoidCallback onSaved;

  const _NotesDialog({required this.event, required this.onSaved});

  @override
  State<_NotesDialog> createState() => _NotesDialogState();
}

class _NotesDialogState extends State<_NotesDialog> {
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.event.notes);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    widget.event.notes = _notesCtrl.text;
    await updateEvent(widget.event);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = widget.event.time.isEmpty ? '—' : widget.event.time;
    return Dialog(
      backgroundColor: const Color(0xFFfbdf50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bold time at top
            Text(
              timeLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kNearBlack,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            // Notes field
            TextField(
              controller: _notesCtrl,
              maxLines: 6,
              autofocus: true,
              style: const TextStyle(
                  fontSize: 12, color: kNearBlack, letterSpacing: -0.5),
              decoration: const InputDecoration(
                hintText: 'Notizen...',
                hintStyle: TextStyle(color: Color(0xFFb09000)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  await _save();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Schließen',
                    style: TextStyle(color: kNearBlack)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
