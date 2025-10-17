// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:just_the_tooltip/just_the_tooltip.dart';
// import 'package:pancake_work_core/data/models/device_settings.dart';
// import 'package:pancake_work_ui/pancake_work_ui.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:workcake/generated/l10n.dart';
// import 'package:pancake_work_core/domain/providers/app_settings_provider.dart';
// import 'package:workcake/providers/providers.dart';

const Duration _kExpand = Duration(milliseconds: 200);

class ProgrammaticExpansionTile extends StatefulWidget {
  const ProgrammaticExpansionTile({
    required Key key,
    required this.listKey,
    this.leading,
    required this.title,
    this.subtitle,
    this.isThreeLine = false,
    this.backgroundColor,
    this.onExpansionChanged,
    this.children = const <Widget>[],
    this.trailing,
    required this.initiallyExpanded,
    this.disableTopAndBottomBorders = false,
    this.pinnedTrailing = false,
    // this.firstFunction,
    // this.titleFirstFunction,
    // this.titleSecondFunction,
    // this.secondFunction,
    // this.numberFunction = 0,
    // this.iconFirstFunction,
    // this.iconSecondFunction,
    this.conditionToShowItemSelected = false,
    this.itemSelectedInCollapse,
    this.widgetHovered,
    this.colorHovered,
  }) : super(key: key);

  final Key listKey;

  /// A widget to display before the title.
  ///
  /// Typically a [CircleAvatar] widget.
  final Widget? leading;

  /// The primary content of the list item.
  ///
  /// Typically a [Text] widget.
  final Widget? title;

  /// Additional content displayed below the title.
  ///
  /// Typically a [Text] widget.
  final Widget? subtitle;

  /// Additional content displayed below the title.
  ///
  /// Typically a [Text] widget.
  final bool isThreeLine;

  /// Called when the tile expands or collapses.
  ///
  /// When the tile starts expanding, this function is called with the value
  /// true. When the tile starts collapsing, this function is called with
  /// the value false.
  final ValueChanged<bool>? onExpansionChanged;

  /// The widgets that are displayed when the tile expands.
  ///
  /// Typically [ListTile] widgets.
  final List<Widget?> children;

  /// The color to display behind the sublist when expanded.
  final Color? backgroundColor;

  /// A widget to display instead of a rotating arrow icon.
  final Widget? trailing;

  /// Specifies if the list tile is initially expanded (true) or collapsed (false, the default).
  final bool initiallyExpanded;

  /// Disable to borders displayed at the top and bottom when expanded
  final bool disableTopAndBottomBorders;

  /// Pin trailing in any case (case hover and not hover)
  final bool pinnedTrailing;

  // this 2 variables help user show item they want when expansion tile contains item is collapse
  final itemSelectedInCollapse;
  final bool conditionToShowItemSelected;

  final Widget? widgetHovered;
  final Color? colorHovered;

  @override
  ProgrammaticExpansionTileState createState() =>
      ProgrammaticExpansionTileState();
}

class ProgrammaticExpansionTileState extends State<ProgrammaticExpansionTile>
    with SingleTickerProviderStateMixin {
  static final Animatable<double> _easeOutTween =
      CurveTween(curve: Curves.easeOut);
  static final Animatable<double> _easeInTween =
      CurveTween(curve: Curves.easeIn);
  // static final Animatable<double> _halfTween =
  //     Tween<double>(begin: 0.0, end: 0.5);
  static final Animatable<double> _quarterTween =
      Tween<double>(begin: 0.0, end: 0.25);

  final ColorTween _borderColorTween = ColorTween();
  final ColorTween _headerColorTween = ColorTween();
  final ColorTween _iconColorTween = ColorTween();
  final ColorTween _backgroundColorTween = ColorTween();

  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;
  late Animation<Color?> _borderColor;
  late Animation<Color?> _headerColor;
  late Animation<Color?> _iconColor;
  late Animation<Color?> _backgroundColor;

  bool _isExpanded = false;
  bool _isHover = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: _kExpand, vsync: this);
    _heightFactor = _controller.drive(_easeInTween);
    _iconTurns = _controller.drive(_quarterTween.chain(_easeInTween));
    _borderColor = _controller.drive(_borderColorTween.chain(_easeOutTween));
    _headerColor = _controller.drive(_headerColorTween.chain(_easeInTween));
    _iconColor = _controller.drive(_iconColorTween.chain(_easeInTween));
    _backgroundColor =
        _controller.drive(_backgroundColorTween.chain(_easeOutTween));

    // _isExpanded = PageStorage.maybeOf(context)?.readState(context, identifier: widget.listKey) as bool? ?? widget.initiallyExpanded;
    _isExpanded = PageStorage.maybeOf(context)
            ?.readState(context, identifier: widget.listKey) as bool? ??
        widget.initiallyExpanded;
    if (_isExpanded) _controller.value = 1.0;

    // Schedule the notification that widget has changed for after init
    // to ensure that the parent widget maintains the correct state
    SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
      if (widget.onExpansionChanged != null &&
          _isExpanded != widget.initiallyExpanded) {
        widget.onExpansionChanged!(_isExpanded);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void expand() {
    _setExpanded(true);
  }

  void collapse() {
    _setExpanded(false);
  }

  void toggle() {
    _setExpanded(!_isExpanded);
  }

  void _setExpanded(bool expanded) {
    if (_isExpanded != expanded) {
      setState(() {
        _isExpanded = expanded;
        if (_isExpanded) {
          _controller.forward();
        } else {
          _controller.reverse().then<void>((void value) {
            if (!mounted) return;
            setState(() {
              // Rebuild without widget.children.
            });
          });
        }
        PageStorage.of(context)
            .writeState(context, _isExpanded, identifier: widget.listKey);
      });
      if (widget.onExpansionChanged != null) {
        widget.onExpansionChanged!(_isExpanded);
      }
    }
  }

  Widget _buildChildren(BuildContext context, Widget? child) {
    final Color borderSideColor = _borderColor.value ?? Colors.transparent;
    bool setBorder = !widget.disableTopAndBottomBorders;

    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor.value ?? Colors.transparent,
        border: setBorder
            ? Border(
                top: BorderSide(color: borderSideColor),
                bottom: BorderSide(color: borderSideColor))
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTileTheme.merge(
            iconColor: _iconColor.value,
            textColor: _headerColor.value,
            child: MouseRegion(
              onEnter: (event) {
                setState(() {
                  _isHover = true;
                });
              },
              onExit: (event) {
                setState(() {
                  _isHover = false;
                });
              },
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: _isHover
                      ? widget.colorHovered ?? Colors.transparent
                      : null,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ListTile(
                  dense: true,
                  onTap: toggle,
                  leading: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: RotationTransition(
                      turns: _iconTurns,
                      child: widget.leading ??
                          const Icon(Icons.expand_more,
                              color: Color(0xffa9acb6), size: 16),
                    ),
                  ),
                  horizontalTitleGap: 10,
                  minLeadingWidth: 4,
                  title: Container(
                    padding: const EdgeInsets.only(bottom: 6),
                    alignment: Alignment.centerLeft,
                    height: double.infinity,
                    child: Row(
                      children: [
                        widget.title ?? Container(),
                        if (_isHover) const SizedBox(width: 8),
                        if (_isHover) widget.widgetHovered ?? Container(),
                      ],
                    ),
                  ),
                  subtitle: widget.subtitle,
                  isThreeLine: widget.isThreeLine,
                  trailing: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: widget.pinnedTrailing
                        ? widget.trailing
                        : _isHover
                            ? widget.trailing ??
                                RotationTransition(
                                    turns: _iconTurns,
                                    child: const Icon(Icons.expand_more))
                            : const SizedBox(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          ClipRect(
              child: Align(heightFactor: _heightFactor.value, child: child)),
          if (!_isExpanded &&
              widget.conditionToShowItemSelected &&
              widget.itemSelectedInCollapse != null)
            widget.itemSelectedInCollapse,
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    final ThemeData theme = Theme.of(context);
    _borderColorTween.end = theme.dividerColor;
    _headerColorTween
      ..begin = theme.textTheme.titleMedium!.color
      ..end = theme.colorScheme.secondary;
    _iconColorTween
      ..begin = theme.unselectedWidgetColor
      ..end = theme.colorScheme.secondary;
    _backgroundColorTween.end = widget.backgroundColor;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final bool closed = !_isExpanded && _controller.isDismissed;
    return AnimatedBuilder(
      animation: _controller.view,
      builder: _buildChildren,
      child: closed ? null : Column(children: widget.children as List<Widget>),
    );
  }
}
