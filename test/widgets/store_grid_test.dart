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
}
