import 'package:flutter/rendering.dart' show SliverLayoutDimensions;
import 'package:material_ui/material_ui.dart';

import '../../../foundations/foundations.dart';
import '../models/m3e_date_picker_models.dart';
import '../res/m3e_date_picker_constants.dart';
import '../styles/m3e_date_picker_theme.dart';
import '../utils/m3e_date_picker_utils.dart';
import 'm3e_day_picker.dart';

/// Calendar for selecting a date range.
class M3ECalendarDateRangePicker extends StatefulWidget {
  /// M3ECalendarDateRangePicker.
  const M3ECalendarDateRangePicker({
    required this.firstDate,
    required this.lastDate,
    required this.onStartDateChanged,
    this.initialStartDate,
    this.initialEndDate,
    this.currentDate,
    this.onEndDateChanged,
    this.selectableDayPredicate,
    super.key,
  });

  /// firstDate.

  final DateTime firstDate;

  /// lastDate.
  final DateTime lastDate;

  /// initialStartDate.
  final DateTime? initialStartDate;

  /// initialEndDate.
  final DateTime? initialEndDate;

  /// currentDate.
  final DateTime? currentDate;

  /// onStartDateChanged.
  final ValueChanged<DateTime> onStartDateChanged;

  /// onEndDateChanged.
  final ValueChanged<DateTime>? onEndDateChanged;

  /// selectableDayPredicate.
  final M3ESelectableDayForRangePredicate? selectableDayPredicate;

  @override
  State<M3ECalendarDateRangePicker> createState() =>
      _M3ECalendarDateRangePickerState();
}

class _M3ECalendarDateRangePickerState
    extends State<M3ECalendarDateRangePicker> {
  late ScrollController _controller;
  bool _scrollInitialized = false;
  late DateTime _firstDate;
  late DateTime _lastDate;
  late DateTime _currentDate;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _firstDate = M3EDatePickerUtils.dateOnly(widget.firstDate);
    _lastDate = M3EDatePickerUtils.dateOnly(widget.lastDate);
    _currentDate = M3EDatePickerUtils.dateOnly(
      widget.currentDate ?? DateTime.now(),
    );
    _startDate = widget.initialStartDate == null
        ? null
        : M3EDatePickerUtils.dateOnly(widget.initialStartDate!);
    _endDate = widget.initialEndDate == null
        ? null
        : M3EDatePickerUtils.dateOnly(widget.initialEndDate!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scrollInitialized) {
      return;
    }
    _scrollInitialized = true;
    // Anchor the month list on the selected start date, falling back to the
    // current date — the list itself starts at [firstDate], which can be
    // years away from anything the user cares about.
    final DateTime anchor = M3EDatePickerUtils.dateOnly(
      _startDate ?? _currentDate,
    );
    final DateTime clamped = anchor.isBefore(_firstDate)
        ? _firstDate
        : (anchor.isAfter(_lastDate) ? _lastDate : anchor);
    final int index = M3EDatePickerUtils.monthDelta(_firstDate, clamped);
    _controller = ScrollController(
      initialScrollOffset: _offsetForMonthIndex(
        index.clamp(0, _monthCount - 1),
        M3ETheme.of(context),
        MaterialLocalizations.of(context),
        MediaQuery.textScalerOf(context),
      ),
    );
  }

  /// Exact scroll offset of the month at [index]: every month item is
  ///
  /// title padding (16) + title text + title padding (8)
  /// + weekday header text + grid top padding + rows x row height + 8,
  ///
  /// so the offsets can be summed deterministically.
  double _offsetForMonthIndex(
    int index,
    M3EThemeData theme,
    MaterialLocalizations localizations,
    TextScaler textScaler,
  ) {
    if (index <= 0) {
      return 0;
    }
    final M3EDatePickerTheme dateTheme = theme.datePickerTheme;
    final double titleHeight = _textHeight(
      localizations.formatMonthYear(_monthForIndex(0)),
      theme.typeScale.titleSmall,
      textScaler,
    );
    final double weekdayHeight = _textHeight(
      localizations.narrowWeekdays[localizations.firstDayOfWeekIndex % 7],
      dateTheme.weekdayStyle(theme.typeScale, theme.colorScheme),
      textScaler,
    );
    var offset = 0.0;
    final int firstDayOfWeekIndex = localizations.firstDayOfWeekIndex;
    for (var i = 0; i < index; i++) {
      offset += _monthExtent(
        i,
        dateTheme,
        firstDayOfWeekIndex,
        titleHeight,
        weekdayHeight,
      );
    }
    return offset;
  }

  /// Height of the month item at [index], matching the item structure:
  /// title padding (16) + title text + title padding (8) + weekday header
  /// text + grid top padding + rows x row height + trailing gap (8).
  ///
  /// Fed to [ListView.builder]'s `itemExtentBuilder` so scroll-offset
  /// resolution (including the initial anchor jump) never has to lay out
  /// intermediate months — a wide [M3ECalendarDateRangePicker.firstDate] to
  /// anchor span costs O(1) on the first frame instead of O(months).
  double _monthExtent(
    int index,
    M3EDatePickerTheme dateTheme,
    int firstDayOfWeekIndex,
    double titleHeight,
    double weekdayHeight,
  ) {
    final DateTime month = _monthForIndex(index);
    final daysInMonth = M3EDatePickerUtils.daysInMonth(month.year, month.month);
    final int firstDayOffset =
        (DateTime(month.year, month.month).weekday - firstDayOfWeekIndex) % 7;
    final rows = ((daysInMonth + firstDayOffset) / dateTheme.daysPerWeek)
        .ceil();
    return 16 +
        titleHeight +
        8 +
        weekdayHeight +
        dateTheme.gridPadding.top +
        rows * M3EDatePickerConstants.dayPickerRowHeight +
        8;
  }

  double _textHeight(String text, TextStyle style, TextScaler textScaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    return painter.height;
  }

  @override
  void didUpdateWidget(covariant M3ECalendarDateRangePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStartDate != oldWidget.initialStartDate) {
      _startDate = widget.initialStartDate;
    }
    if (widget.initialEndDate != oldWidget.initialEndDate) {
      _endDate = widget.initialEndDate;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _monthCount =>
      M3EDatePickerUtils.monthDelta(_firstDate, _lastDate) + 1;

  DateTime _monthForIndex(int index) {
    return M3EDatePickerUtils.addMonthsToMonthDate(_firstDate, index);
  }

  void _updateSelection(DateTime date) {
    M3EHaptics.selection();
    setState(() {
      if (_startDate != null &&
          _endDate == null &&
          !date.isBefore(_startDate!)) {
        _endDate = date;
        widget.onEndDateChanged?.call(_endDate!);
      } else {
        _startDate = date;
        _endDate = null;
        widget.onStartDateChanged(_startDate!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );
    final M3EDatePickerTheme dateTheme = theme.datePickerTheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final double titleHeight = _textHeight(
      localizations.formatMonthYear(_monthForIndex(0)),
      theme.typeScale.titleSmall,
      textScaler,
    );
    final double weekdayHeight = _textHeight(
      localizations.narrowWeekdays[localizations.firstDayOfWeekIndex % 7],
      dateTheme.weekdayStyle(theme.typeScale, theme.colorScheme),
      textScaler,
    );

    return ListView.builder(
      controller: _controller,
      itemCount: _monthCount,
      // Deterministic per-month extents: scroll-offset resolution (the
      // initial anchor jump in particular) never lays out intermediate
      // months, so a wide firstDate-to-anchor span is O(1) on first frame.
      itemExtentBuilder: (int index, SliverLayoutDimensions dimensions) {
        return _monthExtent(
          index,
          dateTheme,
          localizations.firstDayOfWeekIndex,
          titleHeight,
          weekdayHeight,
        );
      },
      itemBuilder: (BuildContext context, int index) {
        final DateTime month = _monthForIndex(index);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
              child: Text(
                localizations.formatMonthYear(month),
                style: theme.typeScale.titleSmall.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            M3EDayPicker(
              displayedMonth: month,
              selectedDate: _startDate,
              currentDate: _currentDate,
              firstDate: _firstDate,
              lastDate: _lastDate,
              onChanged: _updateSelection,
              selectableDayPredicate: widget.selectableDayPredicate,
              rangeStart: _startDate,
              rangeEnd: _endDate,
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
