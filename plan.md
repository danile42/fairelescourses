# Supermarket Navigator — Implementation Plan

## Overview

A cross-platform mobile app (Android-first, iOS optional) that helps users navigate supermarkets efficiently based on a defined store layout and shopping list.

---

## Tech Stack

| Layer | Choice | Rationale |
|---|---|---|
| Framework | Flutter (Dart) | Single codebase, Android-first, easy iOS port, strong grid/list UI widgets |
| State management | Riverpod | Scalable, testable, no boilerplate |
| Persistence | Hive (local NoSQL) | Lightweight, no server needed, works offline |
| Sharing | Flutter Share Plus plugin | Native share sheet on Android & iOS |

---

## Text Format (shareable via messenger/email)

All data is encoded as plain text blocks that can be copy-pasted or shared.

### Supermarket definition

```
SUPERMARKET: Edeka Nord
ROWS: A B C D E
COLS: 1 2 3 4 5
ENTRANCE: A1
EXIT: E5

A1: Bakery, Bread, Pastries
A2: Cereals, Muesli, Porridge
A3: Coffee, Tea, Cocoa
A4: Juices, Soft Drinks
A5: Water, Sparkling Water
B1: Dairy, Milk, Butter
B2: Cheese, Yogurt
B3: Eggs, Cream
B4: Chilled Desserts
B5: Chilled Drinks
C1: Meat, Poultry
C2: Fish, Seafood
C3: Deli, Cold Cuts
C4: Vegan Products
C5: Ready Meals
D1: Fruits, Apples, Bananas
D2: Vegetables, Carrots, Onions
D3: Herbs, Salad
D4: Frozen Food
D5: Ice Cream
E1: Cleaning Products
E2: Personal Care
E3: Pet Food
E4: Household
E5: Checkout
```

### Shopping list

```
LIST: Weekly Shop
STORES: Edeka Nord, Rewe City

Milk
Bread
Apples
Yogurt
Carrots
Coffee
Dishwasher Tabs
Cat Food
```

Format rules:
- `SUPERMARKET:` / `LIST:` lines mark the start of each block type
- Sections are separated by blank lines
- `ROWS:` and `COLS:` define the grid axes (letters × numbers)
- Each cell entry: `RowCol: item1, item2, ...` (case-insensitive matching)
- Items not matched in any store are flagged as "not found"
- Text blocks can be imported by pasting into the app or opening a `.txt` / `.superlist` file

---

## Data Model

```
Supermarket
  id: String
  name: String
  rows: List<String>       // e.g. ["A","B","C","D","E"]
  cols: List<String>       // e.g. ["1","2","3","4","5"]
  entrance: String         // e.g. "A1"
  exit: String             // e.g. "E5"
  cells: Map<String, List<String>>   // e.g. {"A1": ["Bakery","Bread"]}

ShoppingList
  id: String
  name: String
  storeNames: List<String>  // preferred stores
  items: List<ShoppingItem>

ShoppingItem
  name: String
  checked: Boolean
  assignedStore: String?
  assignedCell: String?

NavigationPlan
  storeId: String
  orderedStops: List<Stop>   // ordered list of cells to visit
  unmatched: List<String>    // items not found in this store

Stop
  cell: String
  items: List<String>
```

---

## Navigation Algorithm

1. **Item matching**: For each shopping list item, search all defined supermarkets for a cell whose tags contain the item (fuzzy/case-insensitive match).
2. **Store assignment**: Assign items to stores greedily — prefer the user's preferred store(s); flag unmatched items.
3. **Path optimization** (per store):
   - Model the grid as a graph; adjacent cells (N/S/E/W) have cost 1.
   - Start at `entrance`, end at `exit`.
   - Find the shortest route visiting all required cells using **nearest-neighbor heuristic** (sufficient for typical store sizes of < 100 cells).
   - For very small lists (≤ 10 stops), use exact TSP via bitmask DP.
4. **Multi-store plan**: Output one sub-plan per store, ordered by user preference or geographic proximity (manual ordering for MVP).

---

## Screens

```
1. Home
   - List of saved shopping lists
   - Button: New List, Import

2. Shopping List Editor
   - Add/remove items (free text)
   - Assign preferred stores
   - Button: Generate Plan

3. Supermarket Editor
   - Grid view (table): rows = A/B/C/D…, cols = 1/2/3/4…
   - Tap a cell → edit goods (comma-separated)
   - Set entrance / exit cell
   - Button: Save, Export as Text

4. Navigation View (active shopping)
   - Current store name + progress (3/12 items)
   - Ordered stop list: cell label + items to pick
   - Tap item → check off
   - Mini grid map: highlights current cell and remaining stops
   - Multi-store: swipe or tab between store sub-plans

5. Import / Share
   - Paste text → parse supermarket or shopping list
   - Share button → native share sheet (plain text)
```

---

## Project Structure

```
lib/
  main.dart
  models/
    supermarket.dart
    shopping_list.dart
    navigation_plan.dart
  providers/
    supermarket_provider.dart
    shopping_list_provider.dart
    navigation_provider.dart
  screens/
    home_screen.dart
    list_editor_screen.dart
    store_editor_screen.dart
    navigation_screen.dart
    import_screen.dart
  services/
    text_parser.dart        // parse/export text format
    navigation_planner.dart // path optimization
    store_matcher.dart      // item → cell matching
  widgets/
    store_grid.dart
    stop_card.dart
    mini_map.dart
```

---

## Milestones

| # | Milestone | Deliverable |
|---|---|---|
| 1 | Project scaffold | Flutter project, Riverpod setup, Hive persistence |
| 2 | Data models + text parser | Parse & export supermarket/list text format |
| 3 | Supermarket editor | Grid UI, cell editing, save/load |
| 4 | Shopping list editor | Item entry, store assignment |
| 5 | Navigation planner | Matching + path algorithm |
| 6 | Navigation screen | Active shopping UI, check-off, mini map |
| 7 | Import / share | Paste import, share sheet |
| 8 | Multi-store support | Split list across stores, sequential plans |
| 9 | Localization | English + German ARB files, `intl` setup |
| 10 | Polish + Android build | APK build, icons, basic theming |

---

## Decisions

| Decision | Choice |
|---|---|
| App name | **Fairelescourses** |
| Platform | **Android-only** (iOS deferred) |
| Shared file extension | **.txt** |
| Persistence / sync | **Offline-only** (no cloud) |
| UI language | **English + German**, architecture extensible to further locales via Flutter's `intl` / ARB files |

## Localization Notes

- All UI strings stored in ARB files: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`
- Flutter's `gen-l10n` tool generates type-safe `AppLocalizations` class
- Language follows system locale; fallback: English
- Adding a new language = adding one new ARB file, no code changes needed
