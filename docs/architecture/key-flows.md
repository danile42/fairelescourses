# Key user flows

Sequence diagrams for the most important journeys through the app.

---

## 1. Create a shop and navigate a list

```mermaid
sequenceDiagram
    actor User
    participant HomeScreen
    participant StoreEditorScreen
    participant ListEditorScreen
    participant NavigationPlanner
    participant NavigationScreen
    participant SN as SupermarketNotifier
    participant LN as ShoppingListNotifier
    participant Hive
    participant Firestore

    Note over User,Firestore: Create shop
    User->>HomeScreen: Tap FAB → New shop
    HomeScreen->>StoreEditorScreen: push (empty Supermarket)
    User->>StoreEditorScreen: Enter name, build grid, assign goods
    User->>StoreEditorScreen: Tap Save
    StoreEditorScreen->>SN: addSupermarket(supermarket)
    SN->>Hive: put(supermarket)
    SN->>Firestore: upsertShop(supermarket) [if household joined]
    SN-->>StoreEditorScreen: state updated
    StoreEditorScreen-->>HomeScreen: pop

    Note over User,Firestore: Create list
    User->>HomeScreen: Tap FAB → New list
    HomeScreen->>ListEditorScreen: push (empty ShoppingList)
    User->>ListEditorScreen: Enter list name, add items
    User->>ListEditorScreen: Tap Save
    ListEditorScreen->>LN: addList(list)
    LN->>Hive: put(list)
    LN->>Firestore: upsertList(list) [if household joined]
    LN-->>ListEditorScreen: state updated
    ListEditorScreen-->>HomeScreen: pop

    Note over User,Firestore: Navigate
    User->>HomeScreen: Tap play on list
    HomeScreen->>NavigationPlanner: plan(list, supermarkets)
    NavigationPlanner-->>HomeScreen: NavigationPlan
    HomeScreen->>NavigationScreen: push(plan)
    User->>NavigationScreen: Check off items
    NavigationScreen->>LN: toggleItem(listId, itemName)
    LN->>Hive: update list
    LN->>Firestore: upsertList(updated list) [if household joined]
    User->>NavigationScreen: Last item checked
    NavigationScreen->>NavigationScreen: CelebrationOverlay fires
```

---

## 2. Collaborative navigation

```mermaid
sequenceDiagram
    actor Host
    actor Guest
    participant NavHost as NavigationScreen (Host)
    participant NavGuest as NavigationScreen (Guest)
    participant LN as ShoppingListNotifier
    participant FirestoreService
    participant Firestore

    Note over Host,Firestore: Host starts session
    Host->>NavHost: Opens NavigationScreen
    NavHost->>FirestoreService: upsertNavSession(listId, uid)
    FirestoreService->>Firestore: write h/{pathId}/nav/current

    Note over Host,Firestore: Guest joins
    Firestore-->>NavGuest: navSessionStream emits session
    NavGuest->>NavGuest: Shows "Join collaborative session" banner
    Guest->>NavGuest: Tap Join
    NavGuest->>NavGuest: Activates real-time list listener

    Note over Host,Firestore: Synced check-off
    Host->>NavHost: Check off "Milk"
    NavHost->>LN: toggleItem("Milk")
    LN->>Firestore: upsertList(updated)
    Firestore-->>NavGuest: listsStream emits updated list
    NavGuest->>NavGuest: "Milk" shown as checked

    Note over Host,Firestore: Session ends
    Host->>NavHost: All items checked
    NavHost->>FirestoreService: deleteNavSession()
    FirestoreService->>Firestore: delete h/{pathId}/nav/current
    Firestore-->>NavGuest: navSessionStream emits null
    NavGuest->>NavGuest: Collaborative banner disappears
```

---

## 3. Search and import a shop

```mermaid
sequenceDiagram
    actor User
    participant ShopSearchScreen
    participant NominatimService
    participant OverpassService
    participant FirestoreService
    participant StoreEditorScreen
    participant SN as SupermarketNotifier
    participant Hive
    participant Firestore

    Note over User,Firestore: Search by location
    User->>ShopSearchScreen: Select "By location", enter address
    User->>ShopSearchScreen: Tap Search
    ShopSearchScreen->>NominatimService: geocode(address)
    NominatimService-->>ShopSearchScreen: (lat, lng)
    ShopSearchScreen->>OverpassService: searchNearby(lat, lng, radius)
    OverpassService-->>ShopSearchScreen: List of OsmShop
    ShopSearchScreen->>FirestoreService: searchNearby(lat, lng, radius)
    FirestoreService-->>ShopSearchScreen: List of known Supermarkets
    ShopSearchScreen->>ShopSearchScreen: Merge and deduplicate results

    Note over User,Firestore: Import
    User->>ShopSearchScreen: Tap Import on a result
    ShopSearchScreen->>FirestoreService: fetchPublicShop(osmId)
    FirestoreService-->>ShopSearchScreen: ShopFloor (community template, if any)
    ShopSearchScreen->>StoreEditorScreen: push(prefilled Supermarket)
    User->>StoreEditorScreen: Adjust grid if needed, Save
    StoreEditorScreen->>SN: addSupermarket(supermarket)
    SN->>Hive: put(supermarket)
    SN->>Firestore: upsertShop(supermarket)
    StoreEditorScreen->>FirestoreService: upsertPublicCells(osmId, floor)
    FirestoreService->>Firestore: update public_shops/{osmId}
```

---

## 4. Join a household

```mermaid
sequenceDiagram
    actor User
    participant SyncScreen
    participant HN as HouseholdNotifier
    participant FirestoreService
    participant Hive
    participant Firestore

    User->>SyncScreen: Enter 6-char code, tap Join
    SyncScreen->>HN: joinHousehold(code)
    HN->>Hive: settings.put("householdId", code)
    HN->>FirestoreService: upload all local shops
    FirestoreService->>Firestore: upsertShop × N
    HN->>FirestoreService: upload all local lists (encrypted)
    FirestoreService->>Firestore: upsertList × N
    HN-->>SyncScreen: state updated
    SyncScreen->>SyncScreen: firestoreSyncProvider activated
    Firestore-->>SyncScreen: shopsStream emits household shops
    Firestore-->>SyncScreen: listsStream emits decrypted lists
    SyncScreen->>SyncScreen: local state merged with remote
```

---

## 5. Navigation planning algorithm

```mermaid
flowchart TD
    A([Input: ShoppingList + List of Supermarkets]) --> B["Sort stores:\n1. Preferred stores\n2. Remaining stores"]
    B --> C[For each unchecked item]
    C --> D["Three-pass cell search:\n1. Exact tag match\n2. All words match\n3. Substring match"]
    D --> E{Found in a store?}
    E -->|yes| F[Assign to first matching store]
    E -->|no| G[Add to globalUnmatched]
    F --> H[For each store with items]
    G --> H
    H --> I[Group items by cell ID]
    I --> J["Split into floors\n(ground + upper)"]
    J --> K[For each floor]
    K --> L{stops ≤ 10?}
    L -->|yes| M["Exact TSP\n(bitmask DP, O(n² × 2ⁿ))"]
    L -->|no| N["Nearest-neighbour\nheuristic O(n²)"]
    M --> O["Route: entrance → stops → exit\n(Manhattan distance)"]
    N --> O
    O --> P[Create NavigationStop per cell]
    P --> Q([Assemble and return NavigationPlan])
```
