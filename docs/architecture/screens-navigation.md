# Screens & navigation

The app uses Flutter's standard `Navigator` (push/pop) — there is no named-route or go_router setup. All routes are pushed imperatively from within screen callbacks.

## Screen hierarchy

```mermaid
flowchart TD
    Home["HomeScreen\n(2 tabs: Lists / Shops)"]
    ListEditor["ListEditorScreen\n(create / edit list)"]
    StoreEditor["StoreEditorScreen\n(create / edit shop grid)"]
    Nav["NavigationScreen\n(active navigation)"]
    Search["ShopSearchScreen\n(search & import shops)"]
    Help["HelpScreen\n(4-page guide)"]
    Sync["SyncScreen\n(household + settings)"]

    Home -->|"FAB → New list / Edit list"| ListEditor
    Home -->|"FAB → New shop / Edit shop"| StoreEditor
    Home -->|"Play button on list"| Nav
    Home -->|"AppBar → Search icon"| Search
    Home -->|"AppBar → Help icon"| Help
    Home -->|"AppBar → Settings icon"| Sync
    ListEditor -->|"Generate plan button"| Nav
    Search -->|"Import shop"| StoreEditor
    Search -->|"tap OSM result"| CommunitySheet["CommunityLayoutsSheet\n(modal bottom sheet)"]
    CommunitySheet -->|"Use this layout"| StoreEditor
    CommunitySheet -->|"Create new layout (footer)"| StoreEditor
```

## Screen descriptions

### HomeScreen (`lib/screens/home_screen.dart`)

The app's root screen with a `TabController` for two tabs:

- **Lists tab** — scrollable list of `ShoppingList` cards. Each card has: play (navigate), edit, and delete actions.
- **Shops tab** — scrollable list of `Supermarket` cards. Each card has: edit and delete actions.

**AppBar actions:** Help (pushes HelpScreen), Search shops (pushes ShopSearchScreen), Settings (pushes SyncScreen).

**FAB** expands into two mini-buttons: New shop and New list. The New shop action opens `ShopSearchScreen` first (instead of jumping directly into the editor). The tour spotlight highlights the FAB and its children.

`HomeScreen` watches `firestoreSyncProvider` (a side-effect provider) to activate Firestore listeners as soon as the home screen is visible.

---

### ListEditorScreen (`lib/screens/list_editor_screen.dart`)

Create or edit a shopping list.

Key interactions:
- Add items via a `TextField` + add button (or keyboard submit). Any text left in the field when the user taps **Save** is automatically added to the list before persisting.
- Each item has an optional **category** field. The rename dialog exposes both name and category; the category is pre-filled from the `item_categories` Hive box if a previous value was saved for that item name. On confirm, the mapping is written back to the box.
- Remove items with a trailing delete icon.
- Multi-select preferred stores via a chip list (drives planner store ordering).
- **Generate plan** builds a `NavigationPlan` synchronously via `NavigationPlanner` and pushes `NavigationScreen`.
- Unsaved changes (including pending text in the add-item field) trigger a confirmation dialog on back-press. Choosing **Save** from that dialog also flushes the pending text.

A `TourHintBanner` is shown at the bottom during tour step 1.

---

### StoreEditorScreen (`lib/screens/store_editor_screen.dart`)

Create or edit a supermarket grid.

Key interactions:
- Set name, address (auto-geocoded via Nominatim on save), entrance, and exit cells.
- Adjust grid dimensions with add/remove row and column buttons.
- Tap a cell to edit its goods (comma-separated tags).
- Long-press a cell to set it as entrance or exit.
- Double-tap a cell to enter split-cell mode (divides the cell into sub-cells).
- Multi-floor: add/remove floors, rename floor labels.
- Pre-fill from a public OSM template when importing.
- For OSM-linked shops: **Browse community layouts** action opens `CommunityLayoutsSheet` and can apply a selected layout to the current editor state.
- Saving an OSM-linked shop triggers automatic community sync via `autoPublishVersion` (fast-path doc + per-user community version).

A `TourHintBanner` is shown at the bottom during tour step 0.

---

### NavigationScreen (`lib/screens/navigation_screen.dart`)

Active in-store navigation. Accepts a `NavigationPlan` from the constructor.

Key features:
- Tab bar per store (if the plan covers multiple shops).
- **Grid view** (default): `MiniMap` widget showing the shop grid with highlighted cells.
- **List view**: Ordered stop cards, each expandable to show the items at that stop.
- Tap an item to check it off (updates `ShoppingList` via provider + Firestore if collaborative).
- Adjacent cell highlighting — once an item is checked, the adjacent cells to the last visited cell are highlighted on the map.
- **Deferral actions** per item: collect later (keep in current store plan), try at next shop, add to a new list.
- Progress indicator: `X/Y items` in the AppBar.
- **Collaborative mode**: if `navSessionProvider` returns an active session for this list, all check-offs sync via Firestore in real time.
- `CelebrationOverlay` fires when the last item is checked.

---

### ShopSearchScreen (`lib/screens/shop_search_screen.dart`)

Discover and import supermarkets.

Two search modes (segmented button):
1. **By location** (default) — geocodes the query via Nominatim, then queries Overpass API for nearby shops, then cross-references Firestore for known layouts.
2. **By item** — queries Firestore `shops` collection on the `goodsList` array field.

Results are shown as a list of cards (or on a `flutter_map` map). Proximity distance from the user's home location is shown when available.

Import action: opens `StoreEditorScreen` pre-filled with the result's data. Duplicate detection prevents importing a shop already within 0.2 km of an existing one.

Tapping any unimported OSM result opens `CommunityLayoutsSheet` directly — a draggable modal bottom sheet listing community-contributed cell layouts for that shop, ranked by import count. A **Create new layout** `OutlinedButton` is always visible in the sheet footer. Selecting a layout or tapping Create opens `StoreEditorScreen` pre-filled accordingly. Already-imported shops open the editor directly on tap.

---

### HelpScreen (`lib/screens/help_screen.dart`)

A 4-page `PageView` explaining: Shops, Lists, Navigation, and Sync. Slide indicators and Next/Done buttons.

---

### SyncScreen (`lib/screens/sync_screen.dart`)

Household management and app settings:

- **Household**: join (enter code), create (generate), share (clipboard), leave.
- **Home location**: address field + Nominatim geocode.
- **Local-only mode**: toggle disables Firebase entirely.
- **Firebase instance**: switch between the built-in project and a custom one (enter fields or paste `google-services.json`).
- **Theme colour**: colour picker → `seedColorProvider`.
- **Reset data**: wipes all Hive boxes with a confirmation dialog.

## Widget hierarchy (simplified)

```mermaid
flowchart TD
    subgraph HomeScreen
        HS1[Scaffold]
        HS2[TabBar]
        HS3[TabBarView]
        HS4["ShoppingListCard ×N"]
        HS5["SupermarketCard ×N"]
        HS6[SpeedDial FAB]
        HS7[TourSpotlight overlay]
        HS8[CelebrationOverlay overlay]
    end

    subgraph NavigationScreen
        NS1[Scaffold]
        NS2[TabBar per store]
        NS3[MiniMap - grid view]
        NS4[StopCard list - list view]
        NS5[CelebrationOverlay overlay]
    end

    subgraph StoreEditorScreen
        SE1[Scaffold]
        SE2[StoreGrid]
        SE3[TourHintBanner]
    end

    subgraph CommunityLayoutsSheet["CommunityLayoutsSheet (modal)"]
        CL1[DraggableScrollableSheet]
        CL2["_LayoutCard ×N\n(FutureBuilder)"]
        CL3["'Create new layout' OutlinedButton\n(persistent footer)"]
    end
```
