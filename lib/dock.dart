import 'dart:ui';

import 'package:flutter/material.dart';

import 'animated_tooltip.dart';

/// Dock of the reorderable [items].
class Dock extends StatefulWidget {
  /// Initial [DockItem] items to put in this [Dock].
  final List<DockItem> items;

  /// Builder building the provided [DockItem] item.
  final Widget Function(DockItem) builder;

  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  @override
  State<Dock> createState() => DockState();
}

/// Dock item class containing an [icon] and a [title].
class DockItem {
  final IconData icon;
  final String title;

  DockItem(this.icon, this.title);
}

class DockState extends State<Dock> {
  /// [DockItem] items being manipulated.
  final List<DockItem> _items = [];

  /// Tracks the currently dragged item's index.
  int? draggedIndex;

  /// Tracks the currently hovered item's index.
  int? hoveredIndex;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Material(
          color: Colors.white.withOpacity(0.1),
          elevation: 5,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.all(
                Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(8),
                    ),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      _items.length,
                      (index) {
                        final DockItem dockItem = _items[index];

                        return DragTarget<int>(
                          onWillAcceptWithDetails: (oldIndex) =>
                              oldIndex.data != index,
                          hitTestBehavior: HitTestBehavior.opaque,
                          builder: (context, candidateData, rejectedData) {
                            return Draggable(
                              data: index,
                              childWhenDragging: const SizedBox(),
                              feedback: Material(
                                color: Colors.transparent,
                                child: Transform.scale(
                                  scale: 1.2,
                                  child: widget.builder(dockItem),
                                ),
                              ),
                              onDragStarted: () {
                                setState(() {
                                  draggedIndex = index;
                                });
                              },
                              onDragEnd: (details) {
                                setState(() {
                                  draggedIndex = null;
                                  hoveredIndex = null;
                                });
                              },
                              child: AnimatedTooltip(
                                showTip: draggedIndex == null,
                                content: Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Center(
                                    child: Text(
                                      dockItem.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                child: AnimatedContainer(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.primaries[dockItem.hashCode %
                                        Colors.primaries.length],
                                  ),
                                  duration: const Duration(milliseconds: 800),
                                  transform: Matrix4.identity()
                                    ..translate(
                                        0.0, getTranslationY(index), 0.0),
                                  height: getScaledSize(index),
                                  width: getScaledSize(index),
                                  alignment: AlignmentDirectional.center,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: widget.builder(dockItem),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant Dock oldWidget) {
    if (oldWidget.items != widget.items) {
      _items.clear();
      _items.addAll(widget.items);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _items.clear();
    super.dispose();
  }

  double getPropertyValue({
    required int index,
    required double baseValue,
    required double maxValue,
    required double nonHoveredMaxValue,
  }) {
    late final double propertyValue;

    if (hoveredIndex == null) {
      return baseValue;
    }

    final difference = (hoveredIndex! - index).abs();
    final itemsAffected = _items.length;

    if (difference == 0) {
      propertyValue = maxValue;
    } else if (difference <= itemsAffected) {
      final ratio = (itemsAffected - difference) / itemsAffected;
      propertyValue = lerpDouble(baseValue, nonHoveredMaxValue, ratio)!;
    } else {
      propertyValue = baseValue;
    }

    return propertyValue;
  }

  double getScaledSize(int index) {
    return getPropertyValue(
      index: index,
      baseValue: 48,
      maxValue: 70,
      nonHoveredMaxValue: 50,
    );
  }

  double getTranslationY(int index) {
    return getPropertyValue(
      index: index,
      baseValue: 0.0,
      maxValue: -22,
      nonHoveredMaxValue: -14,
    );
  }

  @override
  void initState() {
    _items.addAll(widget.items);
    super.initState();
  }
}
