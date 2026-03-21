import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/navigation_plan.dart';
import '../providers/supermarket_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MiniMap extends ConsumerWidget {
  final StorePlan storePlan;
  final String? currentCell;
  final Set<String> checkedItems;

  const MiniMap({
    super.key,
    required this.storePlan,
    required this.currentCell,
    required this.checkedItems,
  });

  /// Returns the next stop cell that still has unchecked items after [currentCell].
  String? _nextCell() {
    bool foundCurrent = false;
    for (final stop in storePlan.stops) {
      if (foundCurrent && stop.items.any((i) => !checkedItems.contains(i))) {
        return stop.cell;
      }
      if (stop.cell == currentCell) foundCurrent = true;
    }
    return null;
  }

  /// Rotation angle (radians, clockwise from north/up) from [from] to [to]
  /// given the store's row/col lists.
  double? _angle(String from, String to, List<String> rows, List<String> cols) {
    int rowOf(String cell) {
      for (var i = 0; i < rows.length; i++) {
        for (var j = 0; j < cols.length; j++) {
          if ('${rows[i]}${cols[j]}' == cell) return i;
        }
      }
      return -1;
    }
    int colOf(String cell) {
      for (var i = 0; i < rows.length; i++) {
        for (var j = 0; j < cols.length; j++) {
          if ('${rows[i]}${cols[j]}' == cell) return j;
        }
      }
      return -1;
    }

    final dr = rowOf(to) - rowOf(from); // positive = south
    final dc = colOf(to) - colOf(from); // positive = east
    if (dr == 0 && dc == 0) return null;
    return math.atan2(dc.toDouble(), -dr.toDouble()); // clockwise from north
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref.watch(supermarketsProvider);
    final store = stores.where((s) => s.id == storePlan.storeId).firstOrNull;
    if (store == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    const cellSize = 28.0;

    final stopCells = {for (final s in storePlan.stops) s.cell};
    final doneCells = storePlan.stops
        .where((s) => s.items.every((i) => checkedItems.contains(i)))
        .map((s) => s.cell)
        .toSet();

    final nextCell = _nextCell() ?? store.exit;
    final arrowAngle = (currentCell != null && nextCell != currentCell)
        ? _angle(currentCell!, nextCell, store.rows, store.cols)
        : null;

    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: store.rows.map((row) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: store.cols.map((col) {
                final cellId = '$row$col';
                final isStop = stopCells.contains(cellId);
                final isDone = doneCells.contains(cellId);
                final isCurrent = cellId == currentCell;
                final isEntrance = cellId == store.entrance;
                final isExit = cellId == store.exit;

                Color bg = Colors.grey.shade200;
                if (isEntrance) bg = Colors.green.shade200;
                if (isExit) bg = Colors.red.shade200;
                if (isStop) bg = isDone ? Colors.green.shade100 : Colors.blue.shade200;
                if (isCurrent) bg = theme.colorScheme.primary;

                Widget? child;
                if (isCurrent) {
                  final icon = const Icon(Icons.navigation, size: 14, color: Colors.white);
                  child = arrowAngle != null
                      ? Transform.rotate(angle: arrowAngle, child: icon)
                      : icon;
                } else if (isDone) {
                  child = const Icon(Icons.check, size: 12, color: Colors.green);
                } else if (isStop) {
                  child = const Icon(Icons.circle, size: 8, color: Colors.white);
                }

                return Container(
                  width: cellSize,
                  height: cellSize,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(3),
                    border: isCurrent
                        ? Border.all(color: theme.colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: Center(child: child),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
