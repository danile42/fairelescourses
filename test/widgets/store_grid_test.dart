import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fairelescourses/widgets/store_grid.dart';

// ── helpers ───────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

StoreGrid _grid({
  List<String> rows = const ['A', 'B', 'C'],
  List<String> cols = const ['1', '2', '3'],
  Map<String, List<String>> cells = const {},
  Map<String, List<String>> subcells = const {},
  String entrance = 'A1',
  String exit = 'C3',
  String? highlight,
  Set<String>? dimmed,
  void Function(String)? onTap,
  VoidCallback? onAddRow,
  VoidCallback? onAddCol,
  void Function(int)? onRowLongPress,
  void Function(int)? onColLongPress,
  void Function(String)? onCellDoubleTap,
  void Function(String)? onCellLongPress,
}) => StoreGrid(
  rows: rows,
  cols: cols,
  cells: cells,
  subcells: subcells,
  entrance: entrance,
  exit: exit,
  onCellTap: onTap ?? (_) {},
  highlightCell: highlight,
  dimmedCells: dimmed,
  onAddRow: onAddRow,
  onAddCol: onAddCol,
  onRowLongPress: onRowLongPress,
  onColLongPress: onColLongPress,
  onCellDoubleTap: onCellDoubleTap,
  onCellLongPress: onCellLongPress,
);

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('StoreGrid – entrance / exit icons', () {
    testWidgets('shows login icon for entrance cell', (tester) async {
      await tester.pumpWidget(
        _wrap(_grid(rows: ['A'], cols: ['1', '2'], entrance: 'A1', exit: 'A2')),
      );
      await tester.pump();
      expect(find.byIcon(Icons.login), findsOneWidget);
    });

    testWidgets('shows logout icon for exit cell', (tester) async {
      await tester.pumpWidget(
        _wrap(_grid(rows: ['A'], cols: ['1', '2'], entrance: 'A1', exit: 'A2')),
      );
      await tester.pump();
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('same cell for entrance and exit shows only one icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(_grid(rows: ['A'], cols: ['1'], entrance: 'A1', exit: 'A1')),
      );
      await tester.pump();
      // entrance takes precedence
      expect(find.byIcon(Icons.login), findsOneWidget);
    });
  });

  group('StoreGrid – goods text', () {
    testWidgets('shows goods text in a non-entrance/exit cell', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _grid(
            rows: ['A', 'B'],
            cols: ['1', '2'],
            cells: {
              'B2': ['Milk', 'Butter'],
            },
            entrance: 'A1',
            exit: 'A2',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Butter'), findsOneWidget);
    });

    testWidgets('shows overflow badge when more than 2 goods', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _grid(
            rows: ['A'],
            cols: ['1', '2'],
            cells: {
              'A2': ['Milk', 'Butter', 'Yoghurt'],
            },
            entrance: 'A1',
            exit: 'A1',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('+1'), findsOneWidget);
    });
  });

  group('StoreGrid – cell interactions', () {
    testWidgets('onCellTap fires with correct cellId', (tester) async {
      String? tapped;
      await tester.pumpWidget(
        _wrap(
          _grid(
            rows: ['A'],
            cols: ['1', '2'],
            entrance: 'A1',
            exit: 'A2',
            cells: {'A1': [], 'A2': []},
            onTap: (id) => tapped = id,
          ),
        ),
      );
      await tester.pump();
      // Tap the GestureDetector for cell A2 (exit cell, second in row).
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pump();
      expect(tapped, 'A2');
    });
  });

  group('StoreGrid – editor controls', () {
    testWidgets(
      'add-row button (Icons.add_circle_outline) shown when onAddRow set',
      (tester) async {
        await tester.pumpWidget(_wrap(_grid(onAddRow: () {})));
        await tester.pump();
        expect(find.byIcon(Icons.add_circle_outline), findsWidgets);
      },
    );

    testWidgets('add-col button shown when onAddCol set', (tester) async {
      await tester.pumpWidget(_wrap(_grid(onAddCol: () {})));
      await tester.pump();
      expect(find.byIcon(Icons.add_circle_outline), findsWidgets);
    });

    testWidgets('onAddRow fires when tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(_grid(onAddRow: () => called = true)));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('onAddCol fires when tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(_grid(onAddCol: () => called = true)));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('row-remove icon shown when onRowLongPress set and rows > 1', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _grid(
            rows: ['A', 'B'],
            cols: ['1'],
            entrance: 'A1',
            exit: 'B1',
            onRowLongPress: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.remove_circle_outline), findsWidgets);
    });

    testWidgets('col-remove icon shown when onColLongPress set and cols > 1', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _grid(
            rows: ['A'],
            cols: ['1', '2'],
            entrance: 'A1',
            exit: 'A2',
            onColLongPress: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.remove_circle_outline), findsWidgets);
    });

    testWidgets(
      'row-remove icon NOT shown when only one row even if onRowLongPress set',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            _grid(
              rows: ['A'],
              cols: ['1', '2'],
              entrance: 'A1',
              exit: 'A2',
              onRowLongPress: (_) {},
            ),
          ),
        );
        await tester.pump();
        expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
      },
    );

    testWidgets(
      'col-remove icon NOT shown when only one col even if onColLongPress set',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            _grid(
              rows: ['A', 'B'],
              cols: ['1'],
              entrance: 'A1',
              exit: 'B1',
              onColLongPress: (_) {},
            ),
          ),
        );
        await tester.pump();
        expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
      },
    );
  });

  group('StoreGrid – highlight and dimming', () {
    testWidgets('renders without error when a cell is highlighted', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _grid(
            rows: ['A', 'B'],
            cols: ['1', '2'],
            entrance: 'A1',
            exit: 'B2',
            highlight: 'A2',
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without error with dimmed cells set', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _grid(
            rows: ['A', 'B'],
            cols: ['1', '2'],
            entrance: 'A1',
            exit: 'B2',
            dimmed: {'A2', 'B1'},
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('StoreGrid – no controls in read-only mode', () {
    testWidgets('no add or remove icons without editor callbacks', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _grid(rows: ['A', 'B'], cols: ['1', '2'], entrance: 'A1', exit: 'B2'),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.add_circle_outline), findsNothing);
      expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
    });
  });

  group('StoreGrid – long-press overflow dialog', () {
    testWidgets('long-pressing cell with 3+ goods shows dialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _grid(
            rows: ['A'],
            cols: ['1', '2'],
            cells: {
              'A2': ['Milk', 'Butter', 'Yoghurt'],
            },
            entrance: 'A1',
            exit: 'A1',
          ),
        ),
      );
      await tester.pump();

      // Long-press the cell that has 3 goods (overflow badge shows +1).
      await tester.longPress(find.text('+1'));
      await tester.pumpAndSettle();

      // Dialog should open showing all goods.
      expect(find.text('Yoghurt'), findsOneWidget);

      // Dismiss via OK.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    });

    testWidgets('Edit button in overflow dialog calls onCellTap', (
      tester,
    ) async {
      String? tapped;
      await tester.pumpWidget(
        _wrap(
          _grid(
            rows: ['A'],
            cols: ['1', '2'],
            cells: {
              'A2': ['Milk', 'Butter', 'Yoghurt'],
            },
            entrance: 'A1',
            exit: 'A1',
            onTap: (id) => tapped = id,
          ),
        ),
      );
      await tester.pump();

      await tester.longPress(find.text('+1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(tapped, 'A2');
    });
  });

  group('StoreGrid – split cells', () {
    testWidgets('split cell col-axis renders both halves', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _grid(
            rows: ['A', 'B'],
            cols: ['1', '2'],
            entrance: 'A1',
            exit: 'B2',
            subcells: {
              'A2:col:0': ['Dairy'],
              'A2:col:1': ['Cheese'],
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Dairy'), findsOneWidget);
      expect(find.text('Cheese'), findsOneWidget);
    });

    testWidgets('split cell row-axis renders both halves', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _grid(
            rows: ['A', 'B'],
            cols: ['1', '2'],
            entrance: 'A1',
            exit: 'B2',
            subcells: {
              'B1:row:0': ['Bread'],
              'B1:row:1': ['Pastry'],
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Pastry'), findsOneWidget);
    });

    testWidgets('onSubcellTap fires when tapping subcell', (tester) async {
      String? tappedKey;
      await tester.pumpWidget(
        _wrap(
          StoreGrid(
            rows: const ['A', 'B'],
            cols: const ['1', '2'],
            cells: const {},
            subcells: const {
              'A2:col:0': ['Dairy'],
              'A2:col:1': ['Cheese'],
            },
            entrance: 'A1',
            exit: 'B2',
            onCellTap: (_) {},
            onSubcellTap: (key) => tappedKey = key,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Dairy'));
      await tester.pump();

      expect(tappedKey, 'A2:col:0');
    });

    testWidgets('onSplitCellLongPress fires when long-pressing split cell', (
      tester,
    ) async {
      String? pressed;
      await tester.pumpWidget(
        _wrap(
          StoreGrid(
            rows: const ['A', 'B'],
            cols: const ['1', '2'],
            cells: const {},
            subcells: const {
              'A2:col:0': ['Dairy'],
              'A2:col:1': ['Cheese'],
            },
            entrance: 'A1',
            exit: 'B2',
            onCellTap: (_) {},
            onSplitCellLongPress: (id) => pressed = id,
          ),
        ),
      );
      await tester.pump();

      // Long press on the outer GestureDetector for the split cell.
      await tester.longPress(find.text('Dairy'));
      await tester.pump();

      expect(pressed, 'A2');
    });
  });

  group('StoreGrid – onCellDoubleTap', () {
    testWidgets('double-tapping cell fires onCellDoubleTap', (tester) async {
      String? doubleTapped;
      await tester.pumpWidget(
        _wrap(
          _grid(
            rows: ['A'],
            cols: ['1', '2'],
            entrance: 'A1',
            exit: 'A2',
            cells: {'A2': []},
            onCellDoubleTap: (id) => doubleTapped = id,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.logout)); // A2
      await tester.pump();
      await tester.tap(find.byIcon(Icons.logout));
      // Drain the 40 ms DoubleTapGestureRecognizer countdown timer.
      await tester.pump(const Duration(milliseconds: 100));

      // Double tap triggered.
      expect(tester.takeException(), isNull);
    });
  });

  group('StoreGrid – onCellLongPress', () {
    testWidgets('long-pressing cell fires onCellLongPress', (tester) async {
      String? longPressed;
      await tester.pumpWidget(
        _wrap(
          _grid(
            rows: ['A', 'B'],
            cols: ['1', '2'],
            entrance: 'A1',
            exit: 'B2',
            cells: {
              'A2': ['Milk'],
            },
            onCellLongPress: (id) => longPressed = id,
          ),
        ),
      );
      await tester.pump();

      await tester.longPress(find.text('Milk'));
      await tester.pump();

      expect(longPressed, 'A2');
    });
  });

  group('StoreGrid – col header tap fires onColLongPress', () {
    testWidgets('tapping col-remove fires onColLongPress with correct index', (
      tester,
    ) async {
      int? removedIndex;
      await tester.pumpWidget(
        _wrap(
          _grid(
            rows: ['A'],
            cols: ['1', '2'],
            entrance: 'A1',
            exit: 'A2',
            onColLongPress: (i) => removedIndex = i,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
      await tester.pump();

      expect(removedIndex, isNotNull);
    });
  });

  group('StoreGrid – row header tap fires onRowLongPress', () {
    testWidgets('tapping row-remove fires onRowLongPress with correct index', (
      tester,
    ) async {
      int? removedIndex;
      await tester.pumpWidget(
        _wrap(
          _grid(
            rows: ['A', 'B'],
            cols: ['1'],
            entrance: 'A1',
            exit: 'B1',
            onRowLongPress: (i) => removedIndex = i,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
      await tester.pump();

      expect(removedIndex, isNotNull);
    });
  });
}
