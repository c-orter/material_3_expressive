import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'm3e_text_fields.dart';

/// A no-op default builder so the [M3ETextFormField] renders only through its
/// own [FormField] state wiring.
Widget _noopBuilder(FormFieldState<String> field) => const SizedBox.shrink();

/// Form-interoperable wrapper around [M3ETextField]: mirrors the classic
/// TextFormField behavior — validator, initialValue, autovalidateMode and
/// autofillHints — on M3E chrome.
///
/// The optional [controller] participates in a two-way mutex with the form
/// field: external controller changes update the form value, and form changes
/// (validation resets, form-field value changes) write back to the
/// controller. Write-backs are guarded by a text-differs check — the
/// TextEditingController text setter resets the selection even for same-text
/// writes, which would clobber the cursor mid-typing.
class M3ETextFormField extends FormField<String> {
  /// M3ETextFormField.
  const M3ETextFormField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.supportingText,
    this.leading,
    this.trailing,
    this.variant = M3ETextFieldVariant.filled,
    this.obscureText = false,
    super.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.onTapOutside,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.content,
    this.alwaysFloating,
    super.initialValue,
    super.validator,
    super.autovalidateMode = AutovalidateMode.disabled,
    super.builder = _noopBuilder,
  }) : assert(
         controller == null || initialValue == null,
         'controller and initialValue are mutually exclusive',
       );

  /// label.
  final String label;

  /// controller.
  final TextEditingController? controller;

  /// focusNode.
  final FocusNode? focusNode;

  /// supportingText.
  final String? supportingText;

  /// leading.
  final Widget? leading;

  /// trailing.
  final Widget? trailing;

  /// variant.
  final M3ETextFieldVariant variant;

  /// obscureText.
  final bool obscureText;

  /// keyboardType.
  final TextInputType? keyboardType;

  /// textInputAction.
  final TextInputAction? textInputAction;

  /// inputFormatters.
  final List<TextInputFormatter>? inputFormatters;

  /// autofillHints.
  final List<String>? autofillHints;

  /// onChanged.
  final ValueChanged<String>? onChanged;

  /// onSubmitted.
  final ValueChanged<String>? onSubmitted;

  /// onTapOutside.
  final TapRegionCallback? onTapOutside;

  /// maxLines.
  final int maxLines;

  /// readOnly.
  final bool readOnly;

  /// onTap.
  final VoidCallback? onTap;

  /// content.
  final Widget? content;

  /// alwaysFloating.
  final bool? alwaysFloating;

  @override
  FormFieldState<String> createState() => M3ETextFormFieldState();
}

/// State for [M3ETextFormField].
class M3ETextFormFieldState extends FormFieldState<String> {
  @override
  M3ETextFormField get widget => super.widget as M3ETextFormField;

  TextEditingController? _controller;

  TextEditingController get _effectiveController =>
      widget.controller ?? (_controller ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    final TextEditingController? c = widget.controller;
    if (c != null) {
      c.addListener(_handleControllerChanged);
    }
  }

  @override
  void didUpdateWidget(M3ETextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      widget.controller?.addListener(_handleControllerChanged);
      final TextEditingController? c = widget.controller;
      if (c != null) {
        c.text = value ?? '';
        c.selection = TextSelection.collapsed(offset: c.text.length);
      }
    }
    if (widget.controller == null && oldWidget.controller != null) {
      _controller?.text = value ?? '';
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChanged);
    if (_controller != null && widget.controller == null) {
      _controller?.dispose();
    }
    super.dispose();
  }

  void _handleControllerChanged() {
    if (value != widget.controller?.text) {
      didChange(widget.controller?.text ?? '');
    }
  }

  @override
  void reset() {
    super.reset();
    final TextEditingController? c = widget.controller;
    if (c != null) {
      c.text = value ?? '';
      c.selection = TextSelection.collapsed(offset: c.text.length);
    } else {
      _controller?.text = value ?? '';
    }
  }

  @override
  void didChange(String? value) {
    super.didChange(value);
    final String newText = value ?? '';
    final TextEditingController? c = widget.controller;
    if (c != null) {
      // Only write back when the text actually differs:
      // TextEditingController's `text` setter resets the selection
      // (collapsed(-1)) and composing region even for same-text writes,
      // which clobbers the cursor mid-typing and makes the next character
      // insert at position 0 (reversed input).
      if (c.text != newText) {
        c.text = newText;
      }
    } else {
      if (_controller?.text != newText) {
        _controller?.text = newText;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return M3ETextField(
      controller: _effectiveController,
      focusNode: widget.focusNode,
      label: widget.label,
      supportingText: widget.supportingText,
      errorText: errorText,
      leading: widget.leading,
      trailing: widget.trailing,
      variant: widget.variant,
      obscureText: widget.obscureText,
      enabled: super.widget.enabled,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autofillHints,
      onChanged: (text) {
        didChange(text);
        widget.onChanged?.call(text);
      },
      onSubmitted: (text) {
        widget.onSubmitted?.call(text);
      },
      onTapOutside: widget.onTapOutside,
      maxLines: widget.maxLines,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      content: widget.content,
      alwaysFloating: widget.alwaysFloating ?? false,
    );
  }
}
