import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

/// A tooltip with text, action buttons, and an arrow pointing to the target.
class AnimatedTooltip extends StatefulWidget {
  final Widget content;
  final GlobalKey? targetGlobalKey;
  final Duration? delay;
  final ThemeData? theme;
  final Widget? child;
  final bool showTip;

  const AnimatedTooltip({
    super.key,
    required this.content,
    this.targetGlobalKey,
    this.theme,
    this.delay,
    this.child,
    this.showTip = true,
  }) : assert(child != null || targetGlobalKey != null);

  @override
  State<StatefulWidget> createState() => AnimatedTooltipState();
}

class AnimatedTooltipState extends State<AnimatedTooltip>
    with SingleTickerProviderStateMixin {
  late double? _tooltipTop;
  late double? _tooltipBottom;
  late Alignment _tooltipAlignment;
  late Alignment _transitionAlignment;
  late Alignment _arrowAlignment;
  bool _isInverted = false;
  Timer? _delayTimer;

  final _arrowSize = const Size(16.0, 16.0);
  final _tooltipMinimumHeight = 140;

  final _overlayController = OverlayPortalController();
  late final AnimationController _animationController = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );
  late final Animation<double> _scaleAnimation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeOutBack,
  );
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ??
        ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
        );

    return OverlayPortal.targetsRootOverlay(
      controller: _overlayController,
      child: widget.child != null
          ? MouseRegion(
              onEnter: (_) => _toggle(),
              onExit: (_) => _toggle(),
              cursor: SystemMouseCursors.click,
              child: widget.child,
            )
          : null,
      overlayChildBuilder: (context) {
        if (!widget.showTip) {
          return const SizedBox();
        } else {
          return Positioned(
            top: _tooltipTop,
            bottom: _tooltipBottom,
            // Provide a transition alignment to make the tooltip appear from the target.
            child: ScaleTransition(
              alignment: _transitionAlignment,
              scale: _scaleAnimation,
              // TapRegion allows the tooltip to be dismissed by tapping outside of it.
              child: Theme(
                data: theme,
                // Don't allow the tooltip to get wider than the screen.
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isInverted)
                        Align(
                          alignment: _arrowAlignment,
                          child: TooltipArrow(
                            size: _arrowSize,
                            isInverted: true,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      Align(
                        alignment: _tooltipAlignment,
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                          child: IntrinsicWidth(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                                padding: const EdgeInsets.all(2),
                                child: Center(child: widget.content),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!_isInverted)
                        Align(
                          alignment: _arrowAlignment,
                          child: TooltipArrow(
                            size: _arrowSize,
                            isInverted: false,
                            color: theme.canvasColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // If the tooltip is delayed, start a timer to show it.
      if (widget.delay != null) {
        _delayTimer = Timer(widget.delay!, _toggle);
      }
    });
  }

  void _toggle() {
    _delayTimer?.cancel();
    _animationController.stop();
    if (_overlayController.isShowing) {
      _animationController.reverse().then((_) {
        _overlayController.hide();
      });
    } else {
      _updatePosition();
      _overlayController.show();
      _animationController.forward();
    }
  }

  void _updatePosition() {
    final Size contextSize = MediaQuery.of(context).size;
    final BuildContext? targetContext = widget.targetGlobalKey != null
        ? widget.targetGlobalKey!.currentContext
        : context;
    final targetRenderBox = targetContext?.findRenderObject() as RenderBox;
    final targetOffset = targetRenderBox.localToGlobal(Offset.zero);
    final targetSize = targetRenderBox.size;
    // Try to position the tooltip above the target,
    // otherwise try to position it below or in the center of the target.
    final tooltipFitsAboveTarget = targetOffset.dy - _tooltipMinimumHeight >= 0;
    final tooltipFitsBelowTarget =
        targetOffset.dy + targetSize.height + _tooltipMinimumHeight <=
            contextSize.height;
    _tooltipTop = tooltipFitsAboveTarget
        ? null
        : tooltipFitsBelowTarget
            ? targetOffset.dy + targetSize.height
            : null;
    _tooltipBottom = tooltipFitsAboveTarget
        ? contextSize.height - targetOffset.dy
        : tooltipFitsBelowTarget
            ? null
            : targetOffset.dy + targetSize.height / 2;
    // If the tooltip is below the target, invert the arrow.
    _isInverted = _tooltipTop != null;
    // Align the tooltip horizontally relative to the target.
    _tooltipAlignment = Alignment(
      (targetOffset.dx) / (contextSize.width - targetSize.width) * 2 - 1.0,
      _isInverted ? 1.0 : -1.0,
    );
    // Make the tooltip appear from the target.
    _transitionAlignment = Alignment(
      (targetOffset.dx + targetSize.width / 2) / contextSize.width * 2 - 1.0,
      _isInverted ? -1.0 : 1.0,
    );
    // Center the arrow horizontally on the target.
    _arrowAlignment = Alignment(
      (targetOffset.dx + targetSize.width / 2) /
              (contextSize.width - _arrowSize.width) *
              2 -
          1.0,
      _isInverted ? 1.0 : -1.0,
    );
  }
}

class TooltipArrow extends StatelessWidget {
  final Size size;
  final Color color;
  final bool isInverted;

  const TooltipArrow({
    super.key,
    this.size = const Size(16.0, 16.0),
    this.color = Colors.white,
    this.isInverted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(-size.width / 2, 0.0),
      child: CustomPaint(
        size: size,
        painter: TooltipArrowPainter(
          size: size,
          color: color,
          isInverted: isInverted,
        ),
      ),
    );
  }
}

class TooltipArrowPainter extends CustomPainter {
  final Size size;
  final Color color;
  final bool isInverted;

  TooltipArrowPainter({
    required this.size,
    required this.color,
    required this.isInverted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();

    if (isInverted) {
      path.moveTo(0.0, size.height);
      path.lineTo(size.width / 2, 0.0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0.0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }

    path.close();

    canvas.drawShadow(path, Colors.black.withOpacity(0.1), 4.0, false);
    canvas.drawPath(path, paint);

    // Add a highlight to give a glass-like effect
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
