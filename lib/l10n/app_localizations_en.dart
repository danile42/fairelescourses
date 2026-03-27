// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fairelescourses';

  @override
  String get homeTitle => 'Shopping Lists';

  @override
  String get newList => 'New List';

  @override
  String get noLists => 'No shopping lists yet.\nTap + to create one.';

  @override
  String get noShops => 'No shops defined yet.';

  @override
  String get shops => 'Shops';

  @override
  String get newShop => 'New Shop';

  @override
  String get editShop => 'Edit Shop';

  @override
  String get shopName => 'Shop name';

  @override
  String get rows => 'Rows (e.g. A B C D E)';

  @override
  String get cols => 'Columns (e.g. 1 2 3 4 5)';

  @override
  String get entrance => 'Entrance cell (e.g. A1)';

  @override
  String get exit => 'Exit cell (e.g. E5)';

  @override
  String get cellGoods => 'Goods (comma-separated)';

  @override
  String cellGoodsAll(String cell) {
    return 'All goods in $cell';
  }

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String deleteConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get listName => 'List name';

  @override
  String get addItem => 'Add item';

  @override
  String get itemHint => 'e.g. Milk';

  @override
  String get generatePlan => 'Generate Plan';

  @override
  String get navigationTitle => 'Navigation';

  @override
  String get shop => 'Shop';

  @override
  String progress(int done, int total) {
    return '$done/$total items';
  }

  @override
  String get unmatched => 'Not found in any shop';

  @override
  String get done => 'Done';

  @override
  String get finish => 'Finish';

  @override
  String stopItems(String items) {
    return 'Pick: $items';
  }

  @override
  String get preferredShops => 'Preferred shops (optional)';

  @override
  String get noItemsInList => 'No items yet. Tap + to add.';

  @override
  String get planReady => 'Plan ready';

  @override
  String editCell(String cell) {
    return 'Edit cell $cell';
  }

  @override
  String get gridRows => 'Rows';

  @override
  String get gridCols => 'Columns';

  @override
  String get editGrid => 'Edit Grid';

  @override
  String get setEntrance => 'Set as entrance';

  @override
  String get setExit => 'Set as exit';

  @override
  String get allItemsChecked => 'All items collected!';

  @override
  String get nextShop => 'Next shop';

  @override
  String get listEditor => 'Edit List';

  @override
  String get shopEditor => 'Edit Shop';

  @override
  String moreGoods(int n) {
    return '+$n more';
  }

  @override
  String get ok => 'OK';

  @override
  String get searchShops => 'Search shops';

  @override
  String get searchShopsHint => 'Type a shop name…';

  @override
  String get searchItemHint => 'Type an item name…';

  @override
  String get searchShopsMinChars => 'Type at least 2 characters to search.';

  @override
  String get noShopsFound => 'No shops found.';

  @override
  String get shopAlreadyKnown => 'In your list';

  @override
  String get shopImported => 'Shop imported.';

  @override
  String get importShop => 'Import';

  @override
  String get searchByName => 'By name';

  @override
  String get searchByItem => 'By item';

  @override
  String get syncTitle => 'Sync';

  @override
  String get yourHouseholdId => 'Your household ID';

  @override
  String get createHousehold => 'Create new household';

  @override
  String get joinHousehold => 'Join household';

  @override
  String get joinHouseholdHint => 'Enter 6-character code';

  @override
  String get joinHouseholdInvalid =>
      'Code must be exactly 6 characters (A–Z, 0–9).';

  @override
  String get leaveHousehold => 'Leave household';

  @override
  String get leaveHouseholdConfirm => 'Stop syncing and leave this household?';

  @override
  String get shareHouseholdId => 'Share ID';

  @override
  String get copiedToClipboard => 'Copied!';

  @override
  String get unsavedChanges => 'You have unsaved changes. Discard them?';

  @override
  String get discardChanges => 'Discard';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get searchByLocation => 'By location';

  @override
  String get homeLocation => 'Home location';

  @override
  String get setHomeLocation => 'Set';

  @override
  String get homeLocationHint => 'City or address…';

  @override
  String get homeLocationSaved => 'Home location saved.';

  @override
  String get homeLocationCleared => 'Home location cleared.';

  @override
  String get geocodeFailed => 'Location not found. Try a different address.';

  @override
  String get nearMe => 'Near me';

  @override
  String distanceKm(String distance) {
    return '$distance km';
  }

  @override
  String get shopAddress => 'Address (optional)';

  @override
  String get locationSearchHint => 'Enter a location to search…';

  @override
  String get noLocationSet => 'No home location set. Go to Sync to set one.';

  @override
  String get geocoding => 'Finding location…';

  @override
  String get findNearby => 'Find nearby';

  @override
  String get osmShopsTitle => 'Nearby shops (OpenStreetMap)';

  @override
  String get createShop => 'Create';

  @override
  String get alreadyDefined => 'Already defined';

  @override
  String get noOsmShopsFound => 'No supermarkets found nearby.';

  @override
  String get osmSearching => 'Searching nearby supermarkets…';

  @override
  String get setLocationFirst => 'Set a home location in Sync first.';

  @override
  String get osmAttribution => 'Shop data © OpenStreetMap contributors (ODbL)';

  @override
  String get osmLoadFailed => 'OpenStreetMap results could not be loaded.';

  @override
  String get retry => 'Retry';

  @override
  String get mapView => 'Map';

  @override
  String get listView => 'List';

  @override
  String get brandFilter => 'Brand';

  @override
  String get noShopsMatchFilter => 'No shops match the selected brands.';

  @override
  String splitCell(String cell) {
    return 'Split cell $cell';
  }

  @override
  String get splitAxisLabel => 'How to split?';

  @override
  String get splitAxisRow => 'Add row';

  @override
  String get splitAxisCol => 'Add column';

  @override
  String get splitLeft => 'Left';

  @override
  String get splitRight => 'Right';

  @override
  String get splitTop => 'Top';

  @override
  String get splitBottom => 'Bottom';

  @override
  String get promoteSplit => 'Promote split';

  @override
  String get promoteSplitDesc => 'Makes this a real grid division';

  @override
  String get revertSplit => 'Revert split';

  @override
  String get revertSplitDesc => 'Merge halves back into one cell';

  @override
  String get nowInShops => 'Now found in shops — navigate to collect:';

  @override
  String get assignToShop => 'Assign to shop';

  @override
  String whichShopForItem(String item) {
    return 'Which shop has \"$item\"?';
  }

  @override
  String get navModeTitle => 'Navigation mode';

  @override
  String get navModeSingle => 'Single';

  @override
  String get navModeSingleDesc => 'Navigate on your own — no sharing';

  @override
  String get navModeCollaborative => 'Collaborative';

  @override
  String get navModeCollaborativeDesc =>
      'All household members see checked items in real time';

  @override
  String get navCollaborativeLabel => 'Collaborative';

  @override
  String get navCollaborativeActive => 'Collaborative navigation active';

  @override
  String get navJoin => 'Join';

  @override
  String get mergeLists => 'Merge';

  @override
  String mergeListsSelected(int n) {
    return '$n selected';
  }

  @override
  String get mergeTargetTitle => 'Merge into which list?';

  @override
  String get mergeTargetSubtitle =>
      'Items from all other selected lists will be added here. Duplicates are removed.';

  @override
  String get firebaseInstanceTitle => 'Firebase instance';

  @override
  String get firebaseInstanceDefault => 'Default (built-in)';

  @override
  String firebaseInstanceCustom(String projectId) {
    return 'Custom: $projectId';
  }

  @override
  String get firebaseInstanceChange => 'Change';

  @override
  String get firebaseInstanceSave => 'Apply';

  @override
  String get firebaseInstanceReset => 'Reset to default';

  @override
  String get firebaseInstanceResetConfirm =>
      'Reset to the built-in Firebase instance? You will need to rejoin your household.';

  @override
  String get firebaseInstanceSaved =>
      'Firebase instance updated. Rejoin your household to sync.';

  @override
  String get firebaseInstanceProjectId => 'Project ID';

  @override
  String get firebaseInstanceApiKey => 'API Key';

  @override
  String get firebaseInstanceAppId => 'App ID';

  @override
  String get firebaseInstanceSenderId => 'Sender ID';

  @override
  String get firebaseInstanceBucket => 'Storage Bucket';

  @override
  String get firebaseInstancePasteJson => 'Paste google-services.json instead';

  @override
  String get firebaseInstanceJsonInvalid =>
      'Could not parse google-services.json.';

  @override
  String get firebaseInstanceFieldsRequired => 'All fields are required.';

  @override
  String get copyList => 'Copy';

  @override
  String get cancelTour => 'Cancel tour';

  @override
  String get catSupermarket => 'Supermarket';

  @override
  String get catConvenience => 'Convenience';

  @override
  String get catElectronics => 'Electronics';

  @override
  String get catComputer => 'Computers';

  @override
  String get catDoItYourself => 'DIY';

  @override
  String get catHardware => 'Hardware';

  @override
  String get catBakery => 'Bakery';

  @override
  String get catButcher => 'Butcher';

  @override
  String get catPharmacy => 'Pharmacy';

  @override
  String get catClothes => 'Clothing';

  @override
  String get catDepartmentStore => 'Department store';

  @override
  String get catFurniture => 'Furniture';

  @override
  String get catBooks => 'Books';

  @override
  String get catSports => 'Sports';

  @override
  String get catGardenCentre => 'Garden centre';

  @override
  String get catPet => 'Pet supplies';

  @override
  String get catFlorist => 'Florist';

  @override
  String get catShoes => 'Shoes';

  @override
  String get collectLater => 'Collect later';

  @override
  String deferToShop(String shop) {
    return 'Try at $shop';
  }

  @override
  String get deferToNewList => 'Add to new list';

  @override
  String fromPreviousShop(String shop) {
    return 'From $shop';
  }

  @override
  String get deferredToNextShop => 'Will try at next shop';

  @override
  String get groundFloor => 'Ground floor';

  @override
  String floorIndex(int n) {
    return 'Floor $n';
  }

  @override
  String get addFloor => 'Add floor';

  @override
  String get removeFloor => 'Remove floor';

  @override
  String get floorName => 'Floor name';

  @override
  String nFloors(int n) {
    return '$n floors';
  }
}
