import 'package:flutter/material.dart';

class StoreGrid extends StatelessWidget {
  final List<String> rows;
  final List<String> cols;
  final Map<String, List<String>> cells;
  final Map<String, List<String>> subcells;
  final String entrance;
  final String exit;
  final void Function(String cellId) onCellTap;
  final void Function(String cellId)? onCellDoubleTap;
  final void Function(String cellId)? onCellLongPress;
  final void Function(String subcellKey)? onSubcellTap;
  final void Function(String cellId)? onSplitCellLongPress;
  final String? highlightCell;
  final Set<String>? dimmedCells;
  // Editor border controls — null in read-only (navigation) contexts.
  final void Function(int rowIndex)? onRowLongPress;
  final void Function(int colIndex)? onColLongPress;
  final VoidCallback? onAddRow;
  final VoidCallback? onAddCol;

  const StoreGrid({
    super.key,
    required this.rows,
    required this.cols,
    required this.cells,
    required this.entrance,
    required this.exit,
    required this.onCellTap,
    this.subcells = const {},
    this.onCellDoubleTap,
    this.onCellLongPress,
    this.onSubcellTap,
    this.onSplitCellLongPress,
    this.highlightCell,
    this.dimmedCells,
    this.onRowLongPress,
    this.onColLongPress,
    this.onAddRow,
    this.onAddCol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cellSize = _cellSize(cols.length);
    final labelW = cellSize * 0.6;
    final canRemoveRow = onRowLongPress != null && rows.length > 1;
    final canRemoveCol = onColLongPress != null && cols.length > 1;

    Widget colHeader(int colIdx) {
      return SizedBox(
        width: cellSize,
        child: Center(
          child: canRemoveCol
              ? GestureDetector(
                  onTap: () => onColLongPress!(colIdx),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Icon(Icons.remove_circle_outline,
                        size: 18, color: theme.colorScheme.error.withAlpha(180)),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      );
    }

    Widget rowHeader(int rowIdx) {
      return SizedBox(
        width: labelW,
        child: Center(
          child: canRemoveRow
              ? GestureDetector(
                  onTap: () => onRowLongPress!(rowIdx),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(Icons.remove_circle_outline,
                        size: 18, color: theme.colorScheme.error.withAlpha(180)),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column remove-icon headers
          Row(
            children: [
              SizedBox(width: labelW),
              ...cols.asMap().entries.map((e) => colHeader(e.key)),
            ],
          ),
          // Grid body + add-col button on the right, vertically centred
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...rows.asMap().entries.map((e) {
                    final rowIdx = e.key;
                    final row = e.value;
                    return Row(
                      children: [
                        rowHeader(rowIdx),
                        ...cols.map((col) {
                          final cellId = '$row$col';
                          final isSplit = subcells.keys
                              .any((k) => k.startsWith('$cellId:'));
                          if (isSplit) {
                            return _buildSplitCell(context, cellId, cellSize);
                          }
                          return _buildNormalCell(context, cellId, cellSize);
                        }),
                      ],
                    );
                  }),
                  // Add-row button
                  if (onAddRow != null)
                    Row(
                      children: [
                        SizedBox(width: labelW),
                        SizedBox(
                          width: cellSize * cols.length,
                          height: 24,
                          child: Center(
                            child: InkWell(
                              onTap: onAddRow,
                              borderRadius: BorderRadius.circular(10),
                              child: Icon(Icons.add_circle_outline,
                                  size: 16, color: theme.colorScheme.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              // Add-col button — centred vertically beside the grid rows
              if (onAddCol != null)
                SizedBox(
                  width: labelW,
                  child: Center(
                    child: InkWell(
                      onTap: onAddCol,
                      borderRadius: BorderRadius.circular(10),
                      child: Icon(Icons.add_circle_outline,
                          size: 16, color: theme.colorScheme.primary),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNormalCell(BuildContext context, String cellId, double cellSize) {
    final theme = Theme.of(context);
    final goods = cells[cellId] ?? [];
    final isEntrance = cellId == entrance;
    final isExit = cellId == exit;
    final isHighlight = cellId == highlightCell;
    final isDimmed = dimmedCells?.contains(cellId) ?? false;

    const visibleCount = 2;
    final overflow =
        goods.length > visibleCount ? goods.length - visibleCount : 0;

    return GestureDetector(
      onTap: () => onCellTap(cellId),
      onDoubleTap:
          onCellDoubleTap != null ? () => onCellDoubleTap!(cellId) : null,
      onLongPress: onCellLongPress != null
          ? () => onCellLongPress!(cellId)
          : goods.length > visibleCount
              ? () => _showAllGoods(context, cellId, goods)
              : null,
      child: Container(
        width: cellSize,
        height: cellSize,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isHighlight
              ? theme.colorScheme.primaryContainer
              : isEntrance
                  ? Colors.green.shade100
                  : isExit
                      ? Colors.red.shade100
                      : goods.isEmpty
                          ? Colors.grey.shade100
                          : Colors.blue.shade50,
          border: Border.all(
            color: isHighlight
                ? theme.colorScheme.primary
                : Colors.grey.shade300,
            width: isHighlight ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Opacity(
          opacity: isDimmed ? 0.35 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isEntrance)
                  const Icon(Icons.login, size: 12, color: Colors.green),
                if (isExit)
                  const Icon(Icons.logout, size: 12, color: Colors.red),
                if (!isEntrance && !isExit) ...[
                  for (final g in goods.take(visibleCount))
                    Text(
                      g,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 7),
                    ),
                  if (overflow > 0)
                    Text(
                      '+$overflow',
                      style: TextStyle(
                          fontSize: 7,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplitCell(
      BuildContext context, String cellId, double cellSize) {
    final theme = Theme.of(context);
    final isDimmed = dimmedCells?.contains(cellId) ?? false;
    final isHighlight = cellId == highlightCell;

    // Determine axis from the first subcell key for this cell.
    final axisKey =
        subcells.keys.firstWhere((k) => k.startsWith('$cellId:'));
    final axis = axisKey.split(':')[1]; // "row" or "col"

    final key0 = '$cellId:$axis:0';
    final key1 = '$cellId:$axis:1';
    final goods0 = subcells[key0] ?? [];
    final goods1 = subcells[key1] ?? [];

    Widget halfWidget(String key, List<String> goods, {bool isFirst = true}) {
      return Expanded(
        child: GestureDetector(
          onTap: onSubcellTap != null ? () => onSubcellTap!(key) : null,
          child: Container(
            decoration: BoxDecoration(
              color: goods.isEmpty ? Colors.grey.shade100 : Colors.blue.shade50,
              border: isFirst
                  ? null
                  : axis == 'col'
                      ? Border(
                          left: BorderSide(color: Colors.grey.shade400))
                      : Border(
                          top: BorderSide(color: Colors.grey.shade400)),
            ),
            padding: const EdgeInsets.all(2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: goods
                  .take(2)
                  .map((g) => Text(
                        g,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 6),
                      ))
                  .toList(),
            ),
          ),
        ),
      );
    }

    final halves = axis == 'col'
        ? Row(children: [
            halfWidget(key0, goods0, isFirst: true),
            halfWidget(key1, goods1, isFirst: false),
          ])
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              halfWidget(key0, goods0, isFirst: true),
              halfWidget(key1, goods1, isFirst: false),
            ]);

    return GestureDetector(
      onLongPress: onSplitCellLongPress != null
          ? () => onSplitCellLongPress!(cellId)
          : null,
      child: Opacity(
        opacity: isDimmed ? 0.35 : 1.0,
        child: Container(
          width: cellSize,
          height: cellSize,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            border: Border.all(
              color: isHighlight
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withAlpha(128),
              width: isHighlight ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: halves,
          ),
        ),
      ),
    );
  }

  double _cellSize(int colCount) {
    if (colCount <= 5) return 64;
    if (colCount <= 8) return 52;
    return 44;
  }

  void _showAllGoods(
      BuildContext context, String cellId, List<String> goods) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(cellId),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: goods
              .map((g) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      const Icon(Icons.circle, size: 6),
                      const SizedBox(width: 8),
                      Expanded(child: Text(g)),
                    ]),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onCellTap(cellId);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}
