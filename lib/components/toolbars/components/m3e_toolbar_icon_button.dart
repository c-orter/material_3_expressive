import 'package:material_3_expressive/material_3_expressive.dart'
    show M3ETheme, M3EToolbar;
import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';

import '../../../foundations/foundations.dart';
import '../../icon_buttons/m3e_icon_buttons.dart';
import '../enums/m3e_toolbar_enums.dart';
import '../models/m3e_toolbar_item.dart';
import '../styles/m3e_toolbar_theme.dart';

/// Inline icon action for [M3EToolbar] — thin adapter over [M3EIconButton].
///
/// Label visibility follows the toolbar's [M3EToolbarLabelMode]:
/// - [M3EToolbarLabelMode.activeOnly]: the label lives inside the button pill
///   and springs in when the action becomes active (width springs between the
///   icon-button visual size and the natural icon+label width).
/// - [M3EToolbarLabelMode.always]: icon + label render statically.
/// - [M3EToolbarLabelMode.selectedIcon]: the label is always visible and the
///   icon springs in on the active action (navigation-bar-like).
class M3EToolbarIconButton extends StatefulWidget {
  /// M3EToolbarIconButton.
  const M3EToolbarIconButton({
    required this.action,
    required this.size,
    this.onPressed,
    this.variant,
    this.pillActiveSpring = true,
    this.labelMode = M3EToolbarLabelMode.activeOnly,
    super.key,
  });

  /// Gap between the icon and label inside an expanded action.
  static const double labelGap = 6;

  /// action.
  final M3EToolbarAction action;

  /// size.
  final M3EIconButtonSize size;

  /// Overrides [M3EToolbarAction.onPressed] when set (e.g. expand trigger).
  final VoidCallback? onPressed;

  /// Defaults to filled when [M3EToolbarAction.isExpandTrigger] or
  /// [M3EToolbarAction.active], else standard.
  final M3EIconButtonVariant? variant;

  /// Reserved for parent [M3EToolbar.pillActiveSpring]; labeled width always
  /// follows the morph spring so padding and animation stay correct.
  final bool pillActiveSpring;

  /// labelMode.
  final M3EToolbarLabelMode labelMode;

  @override
  State<M3EToolbarIconButton> createState() => _M3EToolbarIconButtonState();
}

class _M3EToolbarIconButtonState extends State<M3EToolbarIconButton>
    with SingleTickerProviderStateMixin {
  late final SingleMotionController _labelCtrl;

  SpringMotion _labelMotion(M3ESpring spring) =>
      const MaterialSpringMotion.expressiveSpatialFast().copyWith(
        stiffness: spring.stiffness,
        damping: spring.damping,
      );

  bool get _hasLabel {
    final String? label = widget.action.label;
    return label != null && label.isNotEmpty;
  }

  /// Whether the label is visible. [M3EToolbarLabelMode.selectedIcon] keeps
  /// the label always visible and toggles the icon instead.
  bool get _showLabeled => switch (widget.labelMode) {
    M3EToolbarLabelMode.activeOnly => _hasLabel && widget.action.active,
    M3EToolbarLabelMode.always || M3EToolbarLabelMode.selectedIcon => _hasLabel,
  };

  bool get _iconAnimated =>
      widget.labelMode == M3EToolbarLabelMode.selectedIcon && _hasLabel;

  @override
  void initState() {
    super.initState();
    _labelCtrl = SingleMotionController(
      motion: _labelMotion(M3EToolbarTheme.defaults.labelSpring),
      vsync: this,
      initialValue: _showLabeled ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant M3EToolbarIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool wasLabeled = switch (oldWidget.labelMode) {
      M3EToolbarLabelMode.activeOnly =>
        _hasLabelOf(oldWidget) && oldWidget.action.active,
      M3EToolbarLabelMode.always ||
      M3EToolbarLabelMode.selectedIcon => _hasLabelOf(oldWidget),
    };
    if (wasLabeled != _showLabeled) {
      final spring = M3ETheme.of(context).toolbarTheme.labelSpring;
      _labelCtrl
        ..motion = _labelMotion(spring)
        ..animateTo(_showLabeled ? 1 : 0);
    }
  }

  bool _hasLabelOf(M3EToolbarIconButton w) {
    final String? label = w.action.label;
    return label != null && label.isNotEmpty;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLabel) {
      return _buildIconButton(context, icon: Icon(widget.action.icon));
    }
    return AnimatedBuilder(
      animation: _labelCtrl,
      builder: (BuildContext context, Widget? child) {
        return _buildLabeled(context, progress: _labelCtrl.value);
      },
    );
  }

  M3EIconButtonVariant get _resolvedVariant =>
      widget.variant ??
      (widget.action.isExpandTrigger || widget.action.active
          ? M3EIconButtonVariant.filled
          : M3EIconButtonVariant.standard);

  VoidCallback? get _resolvedOnPressed => widget.action.enabled
      ? (widget.onPressed ?? widget.action.onPressed)
      : null;

  /// Per-action accent / destructive coloring.
  M3EIconButtonDecoration? _decorationFor(BuildContext context) {
    final Color? accent = widget.action.color;
    if (accent != null) {
      return M3EIconButtonDecoration(
        backgroundColor: widget.action.active
            ? WidgetStatePropertyAll<Color>(accent)
            : null,
        foregroundColor: WidgetStatePropertyAll<Color>(
          widget.action.active ? _onColorForAccent(context, accent) : accent,
        ),
      );
    }
    if (widget.action.isDestructive) {
      return M3EIconButtonDecoration(
        foregroundColor: WidgetStatePropertyAll<Color>(
          M3ETheme.of(context).colorScheme.error,
        ),
      );
    }
    return null;
  }

  Color _onColorForAccent(BuildContext context, Color accent) {
    final scheme = M3ETheme.of(context).colorScheme;
    if (accent == scheme.primary) {
      return scheme.onPrimary;
    }
    if (accent == scheme.secondary) {
      return scheme.onSecondary;
    }
    if (accent == scheme.tertiary) {
      return scheme.onTertiary;
    }
    if (accent == scheme.error) {
      return scheme.onError;
    }
    return ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  Widget _buildIconButton(
    BuildContext context, {
    required Widget icon,
    Size? visualSize,
  }) {
    return M3EIconButton(
      icon: icon,
      onPressed: _resolvedOnPressed,
      tooltip: widget.action.tooltip ?? widget.action.label,
      semanticLabel: widget.action.semanticLabel,
      size: widget.size,
      variant: _resolvedVariant,
      visualSize: visualSize,
      decoration: _decorationFor(context),
    );
  }

  Widget _buildLabeled(BuildContext context, {required double progress}) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EIconButtonTheme iconTheme = theme.iconButtonTheme;
    final Size visual = iconTheme.visual(
      widget.size,
      M3EIconButtonWidth.defaultWidth,
    );
    final double iconPx = iconTheme.iconSize(widget.size);
    final double t = progress.clamp(0.0, 1.0);
    final TextStyle labelStyle = theme.typeScale.labelLarge.copyWith(
      fontWeight: FontWeight.w600,
    );
    final double labelWidth = _measureLabelWidth(
      widget.action.label!,
      labelStyle,
      MediaQuery.textScalerOf(context),
    );
    final double expandedWidth =
        visual.width + M3EToolbarIconButton.labelGap + labelWidth;
    // selectedIcon starts from a label-only pill; other modes start from the
    // icon-only visual width.
    final double collapsedWidth =
        widget.labelMode == M3EToolbarLabelMode.selectedIcon
        ? labelWidth + 16
        : visual.width;
    final double sprungWidth =
        collapsedWidth + (expandedWidth - collapsedWidth) * t;

    return _buildIconButton(
      context,
      icon: _buildLabeledRow(
        context: context,
        iconPx: iconPx,
        labelStyle: labelStyle,
        progress: t,
      ),
      visualSize: Size(sprungWidth, visual.height),
    );
  }

  Widget _buildLabeledRow({
    required BuildContext context,
    required double iconPx,
    required TextStyle labelStyle,
    required double progress,
  }) {
    final Widget icon = Icon(widget.action.icon, size: iconPx);
    final Widget label = Text(
      widget.action.label!,
      style: labelStyle.copyWith(color: IconTheme.of(context).color),
      maxLines: 1,
      overflow: TextOverflow.clip,
      softWrap: false,
    );

    if (_iconAnimated) {
      // Label is always visible; the icon morphs in on activation.
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (progress > 0.01)
            ClipRect(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: progress,
                child: Opacity(opacity: progress, child: icon),
              ),
            ),
          if (progress > 0.01)
            SizedBox(width: M3EToolbarIconButton.labelGap * progress),
          label,
        ],
      );
    }

    // Icon is always visible; the label morphs in on activation.
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        icon,
        if (progress > 0.01)
          ClipRect(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: progress,
              child: Opacity(
                opacity: progress,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: M3EToolbarIconButton.labelGap,
                  ),
                  child: label,
                ),
              ),
            ),
          ),
      ],
    );
  }

  double _measureLabelWidth(
    String label,
    TextStyle style,
    TextScaler textScaler,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    return painter.width;
  }
}
