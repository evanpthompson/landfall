import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// `TextField` wrapper that explicitly invokes the platform IME on focus.
///
/// Fire TV does not auto-summon the Amazon keyboard when a Flutter
/// `TextField` gains focus — confirmed during Phase 0 bench-testing. This
/// wrapper calls `SystemChannels.textInput.invokeMethod('TextInput.show')`
/// whenever the field becomes focused, which forces the IME to appear on
/// Fire OS and is a no-op on platforms where the IME is already visible.
///
/// Pair with `android:windowSoftInputMode="stateVisible|adjustResize"` in
/// the activity manifest. Both are required: the manifest flag tells the
/// system the activity wants the IME, the explicit invocation guarantees
/// it actually shows.
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
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextStyle? style;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  @override
  State<LandfallTextField> createState() => _LandfallTextFieldState();
}

class _LandfallTextFieldState extends State<LandfallTextField> {
  late final FocusNode _node;
  late final bool _ownsNode;

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
    if (_node.hasFocus) {
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _node,
      decoration: widget.decoration,
      style: widget.style,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      onSubmitted: widget.onSubmitted,
    );
  }
}
