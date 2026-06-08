import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// `TextField` wrapper with two distinct focus behaviours:
///
/// **Normal mode** (`leanback: false`, default):
///   Explicitly invokes the platform IME when the field gains focus. Required
///   on Fire TV where Flutter does not auto-summon the Amazon keyboard —
///   confirmed during Phase 0 bench-testing.
///
/// **Leanback mode** (`leanback: true`):
///   The field participates in D-pad focus traversal and shows a focused style
///   but does NOT open the keyboard on focus. The keyboard only appears when
///   the user presses the D-pad centre (SELECT). On submit / when focus moves
///   away, the field returns to read-only and the keyboard closes.
///
/// Pair with `android:windowSoftInputMode="stateVisible|adjustResize"` in
/// the activity manifest for normal mode. Both are required on Fire TV.
class LandfallTextField extends StatefulWidget {
  const LandfallTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.style,
    this.keyboardType,
    this.textInputAction,
    this.autofocus = false,
    this.enabled = true,
    this.obscureText = false,
    this.leanback = false,
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextStyle? style;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool enabled;
  final bool obscureText;

  /// When true, focus via D-pad shows a highlight but does not open the
  /// keyboard. The keyboard opens only when the user presses SELECT.
  final bool leanback;

  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  State<LandfallTextField> createState() => _LandfallTextFieldState();
}

class _LandfallTextFieldState extends State<LandfallTextField> {
  late final FocusNode _node;
  late final bool _ownsNode;

  /// True only in leanback mode while the keyboard is open.
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ownsNode = widget.focusNode == null;
    _node = widget.focusNode ?? FocusNode();
    _node.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _node.removeListener(_onFocusChanged);
    if (_ownsNode) _node.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!widget.leanback) {
      // Normal mode: summon keyboard whenever the field gains focus.
      if (_node.hasFocus) {
        SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      }
      return;
    }

    // Leanback mode: if focus moved away while editing, close the keyboard and
    // reset state so the next D-pad visit starts clean.
    if (!_node.hasFocus && _editing) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      if (mounted) setState(() => _editing = false);
    }
  }

  /// Opens the keyboard and switches the field to editable.
  void _enterEditMode() {
    setState(() => _editing = true);
    // Defer until after the readOnly: false rebuild so the IME binds to the
    // now-editable field rather than the read-only one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _node.requestFocus();
        SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      }
    });
  }

  /// Closes the keyboard and returns the field to highlight-only mode.
  void _exitEditMode(String value) {
    setState(() => _editing = false);
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    widget.onSubmitted?.call(value);
  }

  Widget _buildTextField() {
    return TextField(
      controller: widget.controller,
      focusNode: _node,
      decoration: widget.decoration,
      style: widget.style,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      obscureText: widget.obscureText,
      onChanged: widget.onChanged,
      // In leanback mode the field is read-only until the user presses SELECT.
      readOnly: widget.leanback && !_editing,
      onSubmitted: widget.leanback ? _exitEditMode : widget.onSubmitted,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.leanback) return _buildTextField();

    // Wrap in a Focus that intercepts the D-pad centre (SELECT) to open the
    // keyboard without triggering it on every focus-traversal pass.
    return Focus(
      onKeyEvent: (_, event) {
        if (_editing) return KeyEventResult.ignored;
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.select) {
          _enterEditMode();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: _buildTextField(),
    );
  }
}
