# Key User Flows

Sequence diagrams for the most important journeys through the app.

---

## 1. Create a Shop and Navigate a List

```plantuml
@startuml flow-navigate
skinparam backgroundColor #FAFAFA
actor User
participant HomeScreen
participant StoreEditorScreen
participant ListEditorScreen
participant NavigationPlanner
participant NavigationScreen
participant "SupermarketNotifier\n(Riverpod)" as SN
participant "ShoppingListNotifier\n(Riverpod)" as LN
database Hive
database Firestore

== Create shop ==
User -> HomeScreen: Tap FAB → New shop
HomeScreen -> StoreEditorScreen: push (empty Supermarket)
User -> StoreEditorScreen: Enter name, build grid, assign goods
User -> StoreEditorScreen: Tap Save
StoreEditorScreen -> SN: addSupermarket(supermarket)
SN -> Hive: put(supermarket)
SN -> Firestore: upsertShop(supermarket) [if household joined]
SN --> StoreEditorScreen: state updated
StoreEditorScreen -> HomeScreen: pop

== Create list ==
User -> HomeScreen: Tap FAB → New list
HomeScreen -> ListEditorScreen: push (empty ShoppingList)
User -> ListEditorScreen: Enter list name, add items
User -> ListEditorScreen: Tap Save
ListEditorScreen -> LN: addList(list)
LN -> Hive: put(list)
LN -> Firestore: upsertList(list) [if household joined]
LN --> ListEditorScreen: state updated
ListEditorScreen -> HomeScreen: pop

== Navigate ==
User -> HomeScreen: Tap play on list
HomeScreen -> NavigationPlanner: plan(list, supermarkets)
NavigationPlanner --> HomeScreen: NavigationPlan
HomeScreen -> NavigationScreen: push(plan)
User -> NavigationScreen: Check off items
NavigationScreen -> LN: toggleItem(listId, itemName)
LN -> Hive: update list
LN -> Firestore: upsertList(updated list) [if household joined]
User -> NavigationScreen: Last item checked
NavigationScreen -> NavigationScreen: CelebrationOverlay fires
@enduml
```

---

## 2. Collaborative Navigation

```plantuml
@startuml flow-collab
skinparam backgroundColor #FAFAFA
actor Host
actor Guest
participant "NavigationScreen\n(Host)" as NavHost
participant "NavigationScreen\n(Guest)" as NavGuest
participant "ShoppingListNotifier" as LN
participant FirestoreService
database Firestore

== Host starts session ==
Host -> NavHost: Opens NavigationScreen
NavHost -> FirestoreService: upsertNavSession(listId, uid)
FirestoreService -> Firestore: write h/{pathId}/nav/current

== Guest joins ==
Firestore -> NavGuest: navSessionStream emits session
NavGuest -> NavGuest: Shows "Join collaborative session" banner
Guest -> NavGuest: Tap Join
NavGuest -> NavGuest: Activates real-time list listener

== Synced check-off ==
Host -> NavHost: Check off "Milk"
NavHost -> LN: toggleItem("Milk")
LN -> Firestore: upsertList(updated)
Firestore -> NavGuest: listsStream emits updated list
NavGuest -> NavGuest: "Milk" shown as checked

== Session ends ==
Host -> NavHost: All items checked
NavHost -> FirestoreService: deleteNavSession()
FirestoreService -> Firestore: delete h/{pathId}/nav/current
Firestore -> NavGuest: navSessionStream emits null
NavGuest -> NavGuest: Collaborative banner disappears
@enduml
```

---

## 3. Search and Import a Shop

```plantuml
@startuml flow-import
skinparam backgroundColor #FAFAFA
actor User
participant ShopSearchScreen
participant NominatimService
participant OverpassService
participant FirestoreService
participant StoreEditorScreen
participant "SupermarketNotifier" as SN
database Hive
database Firestore

== Search by location ==
User -> ShopSearchScreen: Select "By location", enter address
User -> ShopSearchScreen: Tap Search
ShopSearchScreen -> NominatimService: geocode(address)
NominatimService --> ShopSearchScreen: (lat, lng)
ShopSearchScreen -> OverpassService: searchNearby(lat, lng, radius)
OverpassService --> ShopSearchScreen: List<OsmShop>
ShopSearchScreen -> FirestoreService: searchNearby(lat, lng, radius)
FirestoreService --> ShopSearchScreen: List<Supermarket> (known shops)
ShopSearchScreen -> ShopSearchScreen: Merge & deduplicate results

== Import ==
User -> ShopSearchScreen: Tap Import on a result
ShopSearchScreen -> FirestoreService: fetchPublicShop(osmId)
FirestoreService --> ShopSearchScreen: ShopFloor? (community template)
ShopSearchScreen -> StoreEditorScreen: push(prefilled Supermarket)
User -> StoreEditorScreen: Adjust grid if needed, Save
StoreEditorScreen -> SN: addSupermarket(supermarket)
SN -> Hive: put(supermarket)
SN -> Firestore: upsertShop(supermarket)
StoreEditorScreen -> FirestoreService: upsertPublicCells(osmId, floor)
FirestoreService -> Firestore: update public_shops/{osmId}
@enduml
```

---

## 4. Join a Household

```plantuml
@startuml flow-household
skinparam backgroundColor #FAFAFA
actor User
participant SyncScreen
participant "HouseholdNotifier" as HN
participant FirestoreService
database "Hive\nsettings" as Hive
database Firestore

User -> SyncScreen: Enter 6-char code, tap Join
SyncScreen -> HN: joinHousehold(code)
HN -> Hive: settings.put("householdId", code)
HN -> FirestoreService: upload all local shops
FirestoreService -> Firestore: upsertShop × N
HN -> FirestoreService: upload all local lists (encrypted)
FirestoreService -> Firestore: upsertList × N
HN -> HN: notify state change
HN --> SyncScreen: updated
SyncScreen -> SyncScreen: firestoreSyncProvider activated\n→ real-time streams start
Firestore -> SyncScreen: shopsStream emits household shops
Firestore -> SyncScreen: listsStream emits decrypted lists
SyncScreen -> SyncScreen: local state merged with remote
@enduml
```

---

## 5. Navigation Planning Algorithm

```plantuml
@startuml flow-planner
skinparam backgroundColor #FAFAFA

start
:Input: ShoppingList, List<Supermarket>|

:Sort stores:\n1. Preferred stores (by preferredStoreIds order)\n2. Remaining stores|

:For each unchecked item:|
  :Three-pass cell search across stores:\n  1. Exact tag match\n  2. All words match\n  3. Substring match|
  if (found in a store?) then (yes)
    :Assign item to first matching store|
  else (no)
    :Add to globalUnmatched|
  endif

:For each store with ≥1 item:|
  :Group items by cell ID|
  :Split into floors (ground + upper)|
  :For each floor:|
    if (stops ≤ 10?) then (yes)
      :Exact TSP (bitmask DP)\nO(n² × 2^n)|
    else (no)
      :Nearest-neighbour heuristic\nO(n²)|
    endif
    :Route from entrance → stops → exit\nusing Manhattan distance|
    :Create NavigationStop per cell|

:Assemble NavigationPlan|
stop
@enduml
```
