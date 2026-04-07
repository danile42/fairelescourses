# Data models

All persistent models live in `lib/models/`. Runtime-only models are also kept there for co-location.

## Class diagram

```mermaid
classDiagram
    class Supermarket {
        <<HiveType 0>>
        +id String
        +name String
        +rows List~String~
        +cols List~String~
        +entrance String
        +exit String
        +cells Map~String, List~String~~
        +subcells Map~String, List~String~~
        +address String
        +lat double
        +lng double
        +parentId String
        +osmId int
        +osmCategory String
        +osmCategories List~String~
        +floorsRaw List~dynamic~
        +groundFloorName String
        +ownerUid String
        +distance(a, b) int
        +findCell(item) String
        +findCellWithFloor(item) Record
        +floorAt(index) ShopFloor
        +isSplit(cellId) bool
        +copyWith() Supermarket
        +toMap() Map
        +fromMap(map) Supermarket
    }

    class ShopFloor {
        +name String
        +rows List~String~
        +cols List~String~
        +entrance String
        +exit String
        +cells Map~String, List~String~~
        +subcells Map~String, List~String~~
        +distance(a, b) int
        +isNeighbour(a, b) bool
        +findCell(item) String
        +toMap() Map
        +fromMap(map) ShopFloor
    }

    class ShoppingList {
        <<HiveType 2>>
        +id String
        +name String
        +preferredStoreIds List~String~
        +items List~ShoppingItem~
        +checkedCount int
        +copyWith() ShoppingList
        +toMap() Map
        +fromMap(map) ShoppingList
    }

    class ShoppingItem {
        <<HiveType 1>>
        +name String
        +checked bool
        +category String?
    }

    class NavigationPlan {
        <<runtime only>>
        +storePlans List~StorePlan~
        +globalUnmatched List~String~
    }

    class StorePlan {
        <<runtime only>>
        +storeId String
        +storeName String
        +stops List~NavigationStop~
        +unmatched List~String~
        +totalItems int
    }

    class NavigationStop {
        <<runtime only>>
        +cell String
        +items List~String~
        +floor int
    }

    class NavSession {
        <<Firestore only>>
        +listId String
        +startedBy String
    }

    class FirebaseCredentials {
        <<settings box>>
        +projectId String
        +apiKey String
        +appId String
        +messagingSenderId String
        +storageBucket String
        +fromJson(json) FirebaseCredentials
    }

    Supermarket "1" *-- "0..*" ShopFloor : floorAt(1+)
    ShoppingList "1" *-- "1..*" ShoppingItem
    NavigationPlan "1" *-- "1..*" StorePlan
    StorePlan "1" *-- "1..*" NavigationStop
```

> **Note — Supermarket floors:** Ground floor data is stored directly on the `Supermarket` object. Additional floors are serialised in `floorsRaw` and accessed via `floorAt(index)` as `ShopFloor` views. `floorAt(0)` returns a synthetic `ShopFloor` built from `Supermarket`'s own fields.

## Model details

### Supermarket

The central domain object. Represents a physical shop as a named 2D grid.

- **Grid cells** are identified by `"<row><col>"` strings, e.g. `"A1"`, `"C3"`.
- **`cells`** maps each cell ID to a list of product tags (goods). Tags are matched against shopping list items.
- **`subcells`** holds draft cell-split data (`"A1:h:0"` / `"A1:h:1"` etc.). A split can be promoted to a real row/column division.
- **`floorsRaw`** stores additional floors as serialised `Map<String, dynamic>` (ShopFloor toMap). Ground floor fields live directly on Supermarket.
- **Item matching** is a three-pass search:
  1. Exact match of any tag against the item name.
  2. All words in the item name appear in a tag.
  3. Any word in the item name is a substring of a tag.

### ShoppingList / ShoppingItem

A named list of grocery items. Each `ShoppingItem` has a `name`, a `checked` flag, and an optional `category` string (e.g. `"Dairy"`). `preferredStoreIds` drives which shops the planner tries first.

The category serves two purposes:
1. **Display**: shown as a subtitle on the item tile in the list editor.
2. **Matching fallback**: if the item name yields no cell match during route planning, the planner retries using the category as the search query (see [services.md](services.md) — NavigationPlanner).

Categories are remembered per item name in the `item_categories` Hive box so the field is pre-filled automatically on re-entry.

### NavigationPlan (runtime)

Produced by `NavigationPlanner.plan()`. Never stored on disk. Contains one `StorePlan` per shop that covers at least one item, plus a `globalUnmatched` list of items found in no shop.

### NavSession (Firestore only)

Minimal document stored in Firestore to signal an active collaborative navigation session. All participants watch the same Firestore path; item check-offs are persisted on the shopping list itself.

### FirebaseCredentials (settings box)

Persisted as JSON in the Hive `settings` box under the key `firebase_custom_credentials`. Allows users to point the app at their own Firebase project.
