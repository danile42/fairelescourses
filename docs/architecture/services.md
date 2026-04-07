# Services

Services are thin clients for external systems. They are accessed via Riverpod providers and contain no UI logic.

## Service overview

```mermaid
flowchart LR
    subgraph Services["lib/services/"]
        FirestoreService
        NavigationPlanner
        NominatimService
        OverpassService
    end

    subgraph Firebase
        Auth["Firebase Auth"]
        Firestore["Cloud Firestore"]
    end

    subgraph OSM["OpenStreetMap"]
        Nominatim["Nominatim REST API\nnominatim.openstreetmap.org"]
        Overpass["Overpass REST API\noverpass-api.de"]
    end

    FirestoreService -->|"anonymous sign-in"| Auth
    FirestoreService -->|"CRUD + streams"| Firestore
    NominatimService -->|"geocode address"| Nominatim
    OverpassService -->|"nearby shop search"| Overpass
```

---

## FirestoreService (`lib/services/firestore_service.dart`)

Central gateway for all cloud sync operations.

### Authentication

Anonymous sign-in is performed once on service construction. The resulting UID is used as `ownerUid` on shops so that other household members cannot overwrite each other's layouts.

### Encryption

All shopping list data is encrypted client-side before being sent to Firestore:

- **Key derivation**: SHA-256 of the household ID → 32-byte AES key.
- **Path derivation**: SHA-256 of the household ID → hex string used as the Firestore path segment. This prevents the plain household code from appearing in the database.
- **Cipher**: AES-256-CBC with a random IV prepended to each ciphertext.
- **Encoding**: `base64` (IV + ciphertext stored as a single `d` field).

Shop layouts (grid structure and goods) are **not encrypted** — they are community-shareable data.

### Firestore collections

| Path | Encrypted | Description |
|---|---|---|
| `shops/{shopId}` | No | Shop layouts indexed by ownerUid + householdHash |
| `public_shops/{osmId}` | No | Latest community cell layout for an OSM shop (fast-path auto-import) |
| `public_shops/{osmId}/versions/{versionId}` | No | Community-contributed layout versions, ranked by import count |
| `h/{pathId}/l/{listId}` | Yes (`d` field) | Shopping lists per household |
| `h/{pathId}/nav/current` | No | Active collaborative nav session |

### Key methods

| Method | Description |
|---|---|
| `upsertShop(shop, householdId)` | Write/update a shop document |
| `deleteShop(id)` | Delete a shop document |
| `shopsStream(householdId)` | Real-time stream of household shops |
| `upsertList(list, householdId)` | Encrypt and write a shopping list |
| `deleteList(id, householdId)` | Delete an encrypted list document |
| `listsStream(householdId)` | Real-time stream of decrypted lists |
| `upsertNavSession(session, householdId)` | Create/update collaborative session |
| `deleteNavSession(householdId)` | End a collaborative session |
| `navSessionStream(householdId)` | Real-time stream of active session |
| `searchByName(query)` | Query `nameLower` field (prefix match) |
| `searchByItem(itemName)` | Query `goodsList` array-contains |
| `searchNearby(lat, lng, radius)` | Client-side haversine filter |
| `fetchPublicShop(osmId)` | Load the fast-path flat layout for an OSM shop |
| `upsertPublicCells(shop)` | Overwrite the flat `public_shops/{osmId}` document (called on publish) |
| `publishLayoutVersion(shop)` | Append a new version to `public_shops/{osmId}/versions/`; also updates the flat doc |
| `listLayoutVersions(osmId)` | Fetch up to 20 versions ordered by `importCount` desc |
| `incrementImportCount(osmId, versionId)` | Atomically increment `importCount` when a version is imported |

---

## NavigationPlanner (`lib/services/navigation_planner.dart`)

Pure Dart service — no I/O. Converts a `ShoppingList` + `List<Supermarket>` into an optimised `NavigationPlan`.

### Algorithm

```mermaid
flowchart TD
    A([Input: ShoppingList + List of Supermarkets]) --> B[Order stores: preferred first then rest]
    B --> C[For each item in list]
    C --> D["Three-pass cell search on item name:\n1. Exact tag match\n2. All words match\n3. Substring match"]
    D --> E{Found in a store?}
    E -->|yes| F[Assign item to first matching store]
    E -->|no| Cat{Item has\ncategory?}
    Cat -->|yes| D2["Three-pass cell search on category:\n1. Exact tag match\n2. All words match\n3. Substring match"]
    D2 --> E2{Found?}
    E2 -->|yes| F
    E2 -->|no| G[Add to globalUnmatched]
    Cat -->|no| G
    F --> H[For each store plan]
    G --> H
    H --> I[Group assigned items by cell]
    I --> J["For each floor (ground first, then upper)"]
    J --> K[Build NavigationStop list per cell]
    K --> L{stops ≤ 10?}
    L -->|yes| M["Exact TSP via bitmask DP\nO(n² × 2ⁿ)"]
    L -->|no| N["Nearest-neighbour heuristic\nO(n²)"]
    M --> O["Route: entrance → sorted stops → exit"]
    N --> O
    O --> P([Return NavigationPlan])
```

- **Manhattan distance** is used as the cost metric (grid movement).
- **Multi-floor**: stops on additional floors are grouped and routed independently; the planner produces a `floor` index on each `NavigationStop`.
- The planner is called synchronously (no async) and is suitable for typical store sizes (< 100 cells).

---

## NominatimService (`lib/services/nominatim_service.dart`)

Single-method geocoding client.

- **Endpoint**: `https://nominatim.openstreetmap.org/search`
- **Method**: `geocode(String query) → (double lat, double lng)?`
- Returns the first result or `null` on failure.
- 15-second HTTP timeout.
- `User-Agent: Fairelescourses/1.0` (required by Nominatim policy).

Used by:
- `StoreEditorScreen`: auto-geocodes the address field on save.
- `SyncScreen`: geocodes the user's home address.
- `ShopSearchScreen` (location mode): geocodes the search query before calling Overpass.

---

## OverpassService (`lib/services/overpass_service.dart`)

Searches OpenStreetMap for physical shops near a coordinate.

- **Endpoint**: Overpass API (interpreter endpoint)
- **Method**: `searchNearby(lat, lng, radius, categories) → List<OsmShop>`

### Supported OSM shop categories (17)

`supermarket`, `convenience`, `electronics`, `computer`, `doityourself`, `hardware`, `bakery`, `butcher`, `pharmacy`, `clothes`, `department_store`, `furniture`, `books`, `sports`, `garden_centre`, `pet`, `florist`, `shoes`

### OsmShop fields

| Field | Source |
|---|---|
| `osmId` | OSM node/way ID |
| `name` | `name` tag |
| `brand` | `brand` tag |
| `address` | Composed from `addr:*` tags |
| `lat`, `lng` | Node coords or way centroid |
| `category` | Matched `shop=*` value |

### Query strategy

- Builds a single Overpass QL query for all requested categories within `radius` metres.
- Handles both `node` and `way` elements (uses `center` lat/lng for ways).
- Results cross-referenced with Firestore in `ShopSearchScreen` to identify already-known shops.
