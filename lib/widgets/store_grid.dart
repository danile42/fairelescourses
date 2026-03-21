import 'package:flutter/material.dart';

class StoreGrid extends StatelessWidget {
  final List<String> rows;
  final List<String> cols;
  final Map<String, List<String>> cells;
  final String entrance;
  final String exit;
  final void Function(String cellId) onCellTap;
  final String? highlightCell;
  final Set<String>? dimmedCells;

  const StoreGrid({
    super.key,
    required this.rows,
    required this.cols,
    required this.cells,
    required this.entrance,
    required this.exit,
    required this.onCellTap,
    this.highlightCell,
    this.dimmedCells,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cellSize = _cellSize(cols.length);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column headers
          Row(
            children: [
              SizedBox(width: cellSize * 0.6), // row label space
              ...cols.map((c) => SizedBox(
                    width: cellSize,
                    child: Center(
                      child: Text(c,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: theme.colorScheme.primary)),
                    ),
                  )),
            ],
          ),
          ...rows.map((row) {
            return Row(
              children: [
                SizedBox(
                  width: cellSize * 0.6,
                  child: Center(
                    child: Text(row,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: theme.colorScheme.primary)),
                  ),
                ),
                ...cols.map((col) {
                  final cellId = '$row$col';
                  final goods = cells[cellId] ?? [];
                  final isEntrance = cellId == entrance;
                  final isExit = cellId == exit;
                  final isHighlight = cellId == highlightCell;
                  final isDimmed = dimmedCells?.contains(cellId) ?? false;

                  const visibleCount = 2;
                  final overflow = goods.length > visibleCount ? goods.length - visibleCount : 0;

                  return GestureDetector(
                    onTap: () => onCellTap(cellId),
                    onLongPress: goods.length > visibleCount
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
                          width: isHighlight ? 2 : 1,
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
                              if (isEntrance) const Icon(Icons.login, size: 12, color: Colors.green),
                              if (isExit) const Icon(Icons.logout, size: 12, color: Colors.red),
                              if (!isEntrance && !isExit) ...[
                                for (final g in goods.take(visibleCount))
                                  Text(g,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 7),
                                  ),
                                if (overflow > 0)
                                  Text('+$overflow',
                                    style: TextStyle(fontSize: 7, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  double _cellSize(int colCount) {
    if (colCount <= 5) return 64;
    if (colCount <= 8) return 52;
    return 44;
  }

  void _showAllGoods(BuildContext context, String cellId, List<String> goods) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(cellId),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: goods.map((g) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              const Icon(Icons.circle, size: 6),
              const SizedBox(width: 8),
              Expanded(child: Text(g)),
            ]),
          )).toList(),
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
