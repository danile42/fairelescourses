import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Fairelescourses'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping lists'**
  String get homeTitle;

  /// No description provided for @newList.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get newList;

  /// No description provided for @noLists.
  ///
  /// In en, this message translates to:
  /// **'No shopping lists yet.\nTap + to create one.'**
  String get noLists;

  /// No description provided for @noShops.
  ///
  /// In en, this message translates to:
  /// **'No shops defined yet.'**
  String get noShops;

  /// No description provided for @emptyListsTitle.
  ///
  /// In en, this message translates to:
  /// **'No shopping lists yet'**
  String get emptyListsTitle;

  /// No description provided for @emptyListsBodyBefore.
  ///
  /// In en, this message translates to:
  /// **'Create a shopping list, then tap'**
  String get emptyListsBodyBefore;

  /// No description provided for @emptyListsBodyOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get emptyListsBodyOr;

  /// No description provided for @emptyListsBodyAfter.
  ///
  /// In en, this message translates to:
  /// **'to navigate your shop.'**
  String get emptyListsBodyAfter;

  /// No description provided for @emptyListsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create a list'**
  String get emptyListsCreate;

  /// No description provided for @emptyShopsTitle.
  ///
  /// In en, this message translates to:
  /// **'No shops yet'**
  String get emptyShopsTitle;

  /// No description provided for @emptyShopsBody.
  ///
  /// In en, this message translates to:
  /// **'Draw your shop as a grid and assign goods to cells.'**
  String get emptyShopsBody;

  /// No description provided for @emptyShopsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create a shop'**
  String get emptyShopsCreate;

  /// No description provided for @emptyShopsFind.
  ///
  /// In en, this message translates to:
  /// **'Find a shop'**
  String get emptyShopsFind;

  /// No description provided for @tourNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tourNext;

  /// No description provided for @tourSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip tour'**
  String get tourSkip;

  /// No description provided for @tourStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Create a shop'**
  String get tourStep1Title;

  /// No description provided for @tourStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Tap + and choose \'New shop\'.'**
  String get tourStep1Body;

  /// No description provided for @tourShopSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by location to find nearby shops. Tap a result to browse community layouts or create a new one from scratch.'**
  String get tourShopSearchHint;

  /// No description provided for @tourShopEditorHint.
  ///
  /// In en, this message translates to:
  /// **'Give your shop a name, optionally assign goods to cells, and tap Save.'**
  String get tourShopEditorHint;

  /// No description provided for @tourListEditorHint.
  ///
  /// In en, this message translates to:
  /// **'Give your list a name and add at least one item, then tap Save.'**
  String get tourListEditorHint;

  /// No description provided for @tourStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Create a shopping list'**
  String get tourStep2Title;

  /// No description provided for @tourStep2Body.
  ///
  /// In en, this message translates to:
  /// **'Tap + and choose \'New list\'. Add the items you want to buy.'**
  String get tourStep2Body;

  /// No description provided for @tourStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Start navigation'**
  String get tourStep3Title;

  /// No description provided for @tourStep3Body.
  ///
  /// In en, this message translates to:
  /// **'Tap the play button next to your list to start your first shopping trip.'**
  String get tourStep3Body;

  /// No description provided for @shops.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get shops;

  /// No description provided for @newShop.
  ///
  /// In en, this message translates to:
  /// **'New shop'**
  String get newShop;

  /// No description provided for @editShop.
  ///
  /// In en, this message translates to:
  /// **'Edit shop'**
  String get editShop;

  /// No description provided for @shopName.
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get shopName;

  /// No description provided for @rows.
  ///
  /// In en, this message translates to:
  /// **'Rows (e.g. A B C D E)'**
  String get rows;

  /// No description provided for @cols.
  ///
  /// In en, this message translates to:
  /// **'Columns (e.g. 1 2 3 4 5)'**
  String get cols;

  /// No description provided for @entrance.
  ///
  /// In en, this message translates to:
  /// **'Entrance cell (e.g. A1)'**
  String get entrance;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit cell (e.g. E5)'**
  String get exit;

  /// No description provided for @cellGoods.
  ///
  /// In en, this message translates to:
  /// **'Goods (comma-separated)'**
  String get cellGoods;

  /// No description provided for @cellGoodsAll.
  ///
  /// In en, this message translates to:
  /// **'All goods in {cell}'**
  String cellGoodsAll(String cell);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteConfirm(String name);

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @listName.
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get listName;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @itemHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Milk'**
  String get itemHint;

  /// No description provided for @itemCategory.
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get itemCategory;

  /// No description provided for @itemCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Dairy'**
  String get itemCategoryHint;

  /// No description provided for @generatePlan.
  ///
  /// In en, this message translates to:
  /// **'Generate plan'**
  String get generatePlan;

  /// No description provided for @navigationTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navigationTitle;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} items'**
  String progress(int done, int total);

  /// No description provided for @unmatched.
  ///
  /// In en, this message translates to:
  /// **'Not found in any shop'**
  String get unmatched;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @stopItems.
  ///
  /// In en, this message translates to:
  /// **'Pick: {items}'**
  String stopItems(String items);

  /// No description provided for @preferredShops.
  ///
  /// In en, this message translates to:
  /// **'Preferred shops (optional)'**
  String get preferredShops;

  /// No description provided for @noItemsInList.
  ///
  /// In en, this message translates to:
  /// **'No items yet. Tap + to add.'**
  String get noItemsInList;

  /// No description provided for @planReady.
  ///
  /// In en, this message translates to:
  /// **'Plan ready'**
  String get planReady;

  /// No description provided for @editCell.
  ///
  /// In en, this message translates to:
  /// **'Edit cell'**
  String get editCell;

  /// No description provided for @gridRows.
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get gridRows;

  /// No description provided for @gridCols.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get gridCols;

  /// No description provided for @deleteRow.
  ///
  /// In en, this message translates to:
  /// **'Delete row?'**
  String get deleteRow;

  /// No description provided for @deleteCol.
  ///
  /// In en, this message translates to:
  /// **'Delete column?'**
  String get deleteCol;

  /// No description provided for @editGrid.
  ///
  /// In en, this message translates to:
  /// **'Edit grid'**
  String get editGrid;

  /// No description provided for @setEntrance.
  ///
  /// In en, this message translates to:
  /// **'Set entrance'**
  String get setEntrance;

  /// No description provided for @setExit.
  ///
  /// In en, this message translates to:
  /// **'Set exit'**
  String get setExit;

  /// No description provided for @allItemsChecked.
  ///
  /// In en, this message translates to:
  /// **'All items collected!'**
  String get allItemsChecked;

  /// No description provided for @nextShop.
  ///
  /// In en, this message translates to:
  /// **'Next shop'**
  String get nextShop;

  /// No description provided for @listEditor.
  ///
  /// In en, this message translates to:
  /// **'Edit list'**
  String get listEditor;

  /// No description provided for @shopEditor.
  ///
  /// In en, this message translates to:
  /// **'Edit shop'**
  String get shopEditor;

  /// No description provided for @moreGoods.
  ///
  /// In en, this message translates to:
  /// **'+{n} more'**
  String moreGoods(int n);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @searchShops.
  ///
  /// In en, this message translates to:
  /// **'Search shops'**
  String get searchShops;

  /// No description provided for @searchItemHint.
  ///
  /// In en, this message translates to:
  /// **'Type an item name…'**
  String get searchItemHint;

  /// No description provided for @searchShopsMinChars.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 characters to search.'**
  String get searchShopsMinChars;

  /// No description provided for @noShopsFound.
  ///
  /// In en, this message translates to:
  /// **'No shops found.'**
  String get noShopsFound;

  /// No description provided for @shopAlreadyKnown.
  ///
  /// In en, this message translates to:
  /// **'In your list'**
  String get shopAlreadyKnown;

  /// No description provided for @shopImported.
  ///
  /// In en, this message translates to:
  /// **'Shop imported.'**
  String get shopImported;

  /// No description provided for @importShop.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importShop;

  /// No description provided for @searchByItem.
  ///
  /// In en, this message translates to:
  /// **'By item'**
  String get searchByItem;

  /// No description provided for @searchByItemNoResults.
  ///
  /// In en, this message translates to:
  /// **'No shops found. Try searching by location to find shops near you.'**
  String get searchByItemNoResults;

  /// No description provided for @configTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get configTitle;

  /// No description provided for @yourHouseholdId.
  ///
  /// In en, this message translates to:
  /// **'Your household ID'**
  String get yourHouseholdId;

  /// No description provided for @createHousehold.
  ///
  /// In en, this message translates to:
  /// **'Create new household'**
  String get createHousehold;

  /// No description provided for @joinHousehold.
  ///
  /// In en, this message translates to:
  /// **'Join household'**
  String get joinHousehold;

  /// No description provided for @joinHouseholdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-character code'**
  String get joinHouseholdHint;

  /// No description provided for @joinHouseholdInvalid.
  ///
  /// In en, this message translates to:
  /// **'Code must be exactly 6 characters (A–Z, 0–9).'**
  String get joinHouseholdInvalid;

  /// No description provided for @leaveHousehold.
  ///
  /// In en, this message translates to:
  /// **'Leave household'**
  String get leaveHousehold;

  /// No description provided for @leaveHouseholdConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop syncing and leave this household?'**
  String get leaveHouseholdConfirm;

  /// No description provided for @shareHouseholdId.
  ///
  /// In en, this message translates to:
  /// **'Share ID'**
  String get shareHouseholdId;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copiedToClipboard;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Discard them?'**
  String get unsavedChanges;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardChanges;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @searchByLocation.
  ///
  /// In en, this message translates to:
  /// **'By location'**
  String get searchByLocation;

  /// No description provided for @homeLocation.
  ///
  /// In en, this message translates to:
  /// **'Home location'**
  String get homeLocation;

  /// No description provided for @setHomeLocation.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setHomeLocation;

  /// No description provided for @homeLocationHint.
  ///
  /// In en, this message translates to:
  /// **'City or address…'**
  String get homeLocationHint;

  /// No description provided for @homeLocationSaved.
  ///
  /// In en, this message translates to:
  /// **'Home location saved.'**
  String get homeLocationSaved;

  /// No description provided for @homeLocationCleared.
  ///
  /// In en, this message translates to:
  /// **'Home location cleared.'**
  String get homeLocationCleared;

  /// No description provided for @geocodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Location not found. Try a different address.'**
  String get geocodeFailed;

  /// No description provided for @nearMe.
  ///
  /// In en, this message translates to:
  /// **'Near home'**
  String get nearMe;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String distanceKm(String distance);

  /// No description provided for @shopAddress.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get shopAddress;

  /// No description provided for @locationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a location to search…'**
  String get locationSearchHint;

  /// No description provided for @noLocationSet.
  ///
  /// In en, this message translates to:
  /// **'No home location set. Go to Sync to set one.'**
  String get noLocationSet;

  /// No description provided for @geocoding.
  ///
  /// In en, this message translates to:
  /// **'Finding location…'**
  String get geocoding;

  /// No description provided for @findNearby.
  ///
  /// In en, this message translates to:
  /// **'Find nearby'**
  String get findNearby;

  /// No description provided for @osmShopsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby shops (OpenStreetMap)'**
  String get osmShopsTitle;

  /// No description provided for @createShop.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createShop;

  /// No description provided for @createNewLayout.
  ///
  /// In en, this message translates to:
  /// **'Create new layout'**
  String get createNewLayout;

  /// No description provided for @alreadyDefined.
  ///
  /// In en, this message translates to:
  /// **'Already defined'**
  String get alreadyDefined;

  /// No description provided for @noOsmShopsFound.
  ///
  /// In en, this message translates to:
  /// **'No supermarkets found nearby.'**
  String get noOsmShopsFound;

  /// No description provided for @osmSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching nearby supermarkets…'**
  String get osmSearching;

  /// No description provided for @setLocationFirst.
  ///
  /// In en, this message translates to:
  /// **'Set a home location in Sync first.'**
  String get setLocationFirst;

  /// No description provided for @osmAttribution.
  ///
  /// In en, this message translates to:
  /// **'Shop data © OpenStreetMap contributors (ODbL)'**
  String get osmAttribution;

  /// No description provided for @osmLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'OpenStreetMap results could not be loaded.'**
  String get osmLoadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @mapView.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapView;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listView;

  /// No description provided for @brandFilter.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brandFilter;

  /// No description provided for @noShopsMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No shops match the selected brands.'**
  String get noShopsMatchFilter;

  /// No description provided for @splitCell.
  ///
  /// In en, this message translates to:
  /// **'Split cell {cell}'**
  String splitCell(String cell);

  /// No description provided for @splitAxisLabel.
  ///
  /// In en, this message translates to:
  /// **'How to split?'**
  String get splitAxisLabel;

  /// No description provided for @splitAxisRow.
  ///
  /// In en, this message translates to:
  /// **'Add row'**
  String get splitAxisRow;

  /// No description provided for @splitAxisCol.
  ///
  /// In en, this message translates to:
  /// **'Add column'**
  String get splitAxisCol;

  /// No description provided for @splitLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get splitLeft;

  /// No description provided for @splitRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get splitRight;

  /// No description provided for @splitTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get splitTop;

  /// No description provided for @splitBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get splitBottom;

  /// No description provided for @promoteSplit.
  ///
  /// In en, this message translates to:
  /// **'Promote split'**
  String get promoteSplit;

  /// No description provided for @promoteSplitDesc.
  ///
  /// In en, this message translates to:
  /// **'Makes this a real grid division'**
  String get promoteSplitDesc;

  /// No description provided for @revertSplit.
  ///
  /// In en, this message translates to:
  /// **'Revert split'**
  String get revertSplit;

  /// No description provided for @revertSplitDesc.
  ///
  /// In en, this message translates to:
  /// **'Merge halves back into one cell'**
  String get revertSplitDesc;

  /// No description provided for @nowInShops.
  ///
  /// In en, this message translates to:
  /// **'Now found in shops — navigate to collect:'**
  String get nowInShops;

  /// No description provided for @assignToShop.
  ///
  /// In en, this message translates to:
  /// **'Assign to shop'**
  String get assignToShop;

  /// No description provided for @whichShopForItem.
  ///
  /// In en, this message translates to:
  /// **'Which shop has \"{item}\"?'**
  String whichShopForItem(String item);

  /// No description provided for @navModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigation mode'**
  String get navModeTitle;

  /// No description provided for @navModeSingle.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get navModeSingle;

  /// No description provided for @navModeSingleDesc.
  ///
  /// In en, this message translates to:
  /// **'Navigate on your own — no sharing'**
  String get navModeSingleDesc;

  /// No description provided for @navModeCollaborative.
  ///
  /// In en, this message translates to:
  /// **'Collaborative'**
  String get navModeCollaborative;

  /// No description provided for @navModeCollaborativeDesc.
  ///
  /// In en, this message translates to:
  /// **'All household members see checked items in real time'**
  String get navModeCollaborativeDesc;

  /// No description provided for @navCollaborativeLabel.
  ///
  /// In en, this message translates to:
  /// **'Collaborative'**
  String get navCollaborativeLabel;

  /// No description provided for @navCollaborativeActive.
  ///
  /// In en, this message translates to:
  /// **'Collaborative navigation active'**
  String get navCollaborativeActive;

  /// No description provided for @navJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get navJoin;

  /// No description provided for @mergeLists.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get mergeLists;

  /// No description provided for @mergeListsSelected.
  ///
  /// In en, this message translates to:
  /// **'{n} selected'**
  String mergeListsSelected(int n);

  /// No description provided for @mergeTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge into which list?'**
  String get mergeTargetTitle;

  /// No description provided for @mergeTargetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Items from all other selected lists will be added here. Duplicates are removed.'**
  String get mergeTargetSubtitle;

  /// No description provided for @firebaseInstanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Firebase instance'**
  String get firebaseInstanceTitle;

  /// No description provided for @firebaseInstanceDefault.
  ///
  /// In en, this message translates to:
  /// **'Default (built-in)'**
  String get firebaseInstanceDefault;

  /// No description provided for @firebaseInstanceCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom: {projectId}'**
  String firebaseInstanceCustom(String projectId);

  /// No description provided for @firebaseInstanceChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get firebaseInstanceChange;

  /// No description provided for @firebaseInstanceSave.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get firebaseInstanceSave;

  /// No description provided for @firebaseInstanceReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get firebaseInstanceReset;

  /// No description provided for @firebaseInstanceResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset to the built-in Firebase instance? You will need to rejoin your household.'**
  String get firebaseInstanceResetConfirm;

  /// No description provided for @firebaseInstanceSaved.
  ///
  /// In en, this message translates to:
  /// **'Firebase instance updated. Rejoin your household to sync.'**
  String get firebaseInstanceSaved;

  /// No description provided for @firebaseInstanceProjectId.
  ///
  /// In en, this message translates to:
  /// **'Project ID'**
  String get firebaseInstanceProjectId;

  /// No description provided for @firebaseInstanceApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get firebaseInstanceApiKey;

  /// No description provided for @firebaseInstanceAppId.
  ///
  /// In en, this message translates to:
  /// **'App ID'**
  String get firebaseInstanceAppId;

  /// No description provided for @firebaseInstanceSenderId.
  ///
  /// In en, this message translates to:
  /// **'Sender ID'**
  String get firebaseInstanceSenderId;

  /// No description provided for @firebaseInstanceBucket.
  ///
  /// In en, this message translates to:
  /// **'Storage bucket'**
  String get firebaseInstanceBucket;

  /// No description provided for @firebaseInstancePasteJson.
  ///
  /// In en, this message translates to:
  /// **'Paste google-services.json instead'**
  String get firebaseInstancePasteJson;

  /// No description provided for @firebaseInstanceJsonInvalid.
  ///
  /// In en, this message translates to:
  /// **'Could not parse google-services.json.'**
  String get firebaseInstanceJsonInvalid;

  /// No description provided for @firebaseInstanceFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'All fields are required.'**
  String get firebaseInstanceFieldsRequired;

  /// No description provided for @copyList.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyList;

  /// No description provided for @cancelTour.
  ///
  /// In en, this message translates to:
  /// **'Cancel tour'**
  String get cancelTour;

  /// No description provided for @catSupermarket.
  ///
  /// In en, this message translates to:
  /// **'Supermarket'**
  String get catSupermarket;

  /// No description provided for @catConvenience.
  ///
  /// In en, this message translates to:
  /// **'Convenience'**
  String get catConvenience;

  /// No description provided for @catElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get catElectronics;

  /// No description provided for @catComputer.
  ///
  /// In en, this message translates to:
  /// **'Computers'**
  String get catComputer;

  /// No description provided for @catDoItYourself.
  ///
  /// In en, this message translates to:
  /// **'DIY'**
  String get catDoItYourself;

  /// No description provided for @catHardware.
  ///
  /// In en, this message translates to:
  /// **'Hardware'**
  String get catHardware;

  /// No description provided for @catBakery.
  ///
  /// In en, this message translates to:
  /// **'Bakery'**
  String get catBakery;

  /// No description provided for @catButcher.
  ///
  /// In en, this message translates to:
  /// **'Butcher'**
  String get catButcher;

  /// No description provided for @catPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get catPharmacy;

  /// No description provided for @catClothes.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get catClothes;

  /// No description provided for @catDepartmentStore.
  ///
  /// In en, this message translates to:
  /// **'Department store'**
  String get catDepartmentStore;

  /// No description provided for @catFurniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get catFurniture;

  /// No description provided for @catBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get catBooks;

  /// No description provided for @catSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get catSports;

  /// No description provided for @catGardenCentre.
  ///
  /// In en, this message translates to:
  /// **'Garden centre'**
  String get catGardenCentre;

  /// No description provided for @catPet.
  ///
  /// In en, this message translates to:
  /// **'Pet supplies'**
  String get catPet;

  /// No description provided for @catFlorist.
  ///
  /// In en, this message translates to:
  /// **'Florist'**
  String get catFlorist;

  /// No description provided for @catShoes.
  ///
  /// In en, this message translates to:
  /// **'Shoes'**
  String get catShoes;

  /// No description provided for @collectLater.
  ///
  /// In en, this message translates to:
  /// **'Collect later'**
  String get collectLater;

  /// No description provided for @deferToShop.
  ///
  /// In en, this message translates to:
  /// **'Try at {shop}'**
  String deferToShop(String shop);

  /// No description provided for @deferToNewList.
  ///
  /// In en, this message translates to:
  /// **'Add to new list'**
  String get deferToNewList;

  /// No description provided for @fromPreviousShop.
  ///
  /// In en, this message translates to:
  /// **'From {shop}'**
  String fromPreviousShop(String shop);

  /// No description provided for @deferredToNextShop.
  ///
  /// In en, this message translates to:
  /// **'Will try at next shop'**
  String get deferredToNextShop;

  /// No description provided for @groundFloor.
  ///
  /// In en, this message translates to:
  /// **'Ground floor'**
  String get groundFloor;

  /// No description provided for @floorIndex.
  ///
  /// In en, this message translates to:
  /// **'Floor {n}'**
  String floorIndex(int n);

  /// No description provided for @addFloor.
  ///
  /// In en, this message translates to:
  /// **'Add floor'**
  String get addFloor;

  /// No description provided for @removeFloor.
  ///
  /// In en, this message translates to:
  /// **'Remove floor'**
  String get removeFloor;

  /// No description provided for @floorName.
  ///
  /// In en, this message translates to:
  /// **'Floor name'**
  String get floorName;

  /// No description provided for @nFloors.
  ///
  /// In en, this message translates to:
  /// **'{n} floors'**
  String nFloors(int n);

  /// No description provided for @moveToList.
  ///
  /// In en, this message translates to:
  /// **'Move to list'**
  String get moveToList;

  /// No description provided for @copyToNewList.
  ///
  /// In en, this message translates to:
  /// **'Copy to new list'**
  String get copyToNewList;

  /// No description provided for @moveToNewList.
  ///
  /// In en, this message translates to:
  /// **'Move to new list'**
  String get moveToNewList;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @startNavigation.
  ///
  /// In en, this message translates to:
  /// **'Start navigation'**
  String get startNavigation;

  /// No description provided for @startShopping.
  ///
  /// In en, this message translates to:
  /// **'Start shopping:'**
  String get startShopping;

  /// No description provided for @viewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get viewGrid;

  /// No description provided for @viewList.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get viewList;

  /// No description provided for @localOnlyMode.
  ///
  /// In en, this message translates to:
  /// **'Local storage only'**
  String get localOnlyMode;

  /// No description provided for @localOnlyModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep all data on this device. No sync, no household.'**
  String get localOnlyModeDesc;

  /// No description provided for @localOnlyWarning.
  ///
  /// In en, this message translates to:
  /// **'Local-only mode is active. Sync and household features are disabled.'**
  String get localOnlyWarning;

  /// No description provided for @localOnlyConfirmEnable.
  ///
  /// In en, this message translates to:
  /// **'Switch to local-only mode? Household sync will be disabled.'**
  String get localOnlyConfirmEnable;

  /// No description provided for @localOnlyConfirmDisable.
  ///
  /// In en, this message translates to:
  /// **'Re-enable sync? You can rejoin a household afterwards.'**
  String get localOnlyConfirmDisable;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'How Fairelescourses works'**
  String get helpTitle;

  /// No description provided for @helpClose.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get helpClose;

  /// No description provided for @helpShopsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get helpShopsTitle;

  /// No description provided for @helpShopsBody.
  ///
  /// In en, this message translates to:
  /// **'Create a shop and map its layout as a grid. Tap cells to assign goods — or browse community layouts to get started quickly with a ready-made grid.'**
  String get helpShopsBody;

  /// No description provided for @helpListsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping lists'**
  String get helpListsTitle;

  /// No description provided for @helpListsBody.
  ///
  /// In en, this message translates to:
  /// **'Add items to a shopping list and optionally choose preferred shops. The app matches each item to a cell in your shops.'**
  String get helpListsBody;

  /// No description provided for @helpNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get helpNavTitle;

  /// No description provided for @helpNavBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the play button on a list to start navigation. The app plans the shortest route through all matching cells and guides you step by step.'**
  String get helpNavBody;

  /// No description provided for @helpSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync & households'**
  String get helpSyncTitle;

  /// No description provided for @helpSyncBody.
  ///
  /// In en, this message translates to:
  /// **'Join a household with other people to share shops and lists. All household data is encrypted with your household code before being stored in the cloud. Shopping lists and items are never readable by the server.'**
  String get helpSyncBody;

  /// No description provided for @helpDataTitle.
  ///
  /// In en, this message translates to:
  /// **'What is stored where'**
  String get helpDataTitle;

  /// No description provided for @helpDataLocal.
  ///
  /// In en, this message translates to:
  /// **'Shops and lists are always saved locally on your device (even without sync).'**
  String get helpDataLocal;

  /// No description provided for @helpDataCloud.
  ///
  /// In en, this message translates to:
  /// **'When you join a household, shops and lists are also synced to Firebase — encrypted with your household ID as the key.'**
  String get helpDataCloud;

  /// No description provided for @helpDataLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'In local-only mode, nothing leaves your device.'**
  String get helpDataLocalOnly;

  /// No description provided for @shopEditorHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'How the shop editor works'**
  String get shopEditorHelpTitle;

  /// No description provided for @shopEditorHelpGridTitle.
  ///
  /// In en, this message translates to:
  /// **'The grid'**
  String get shopEditorHelpGridTitle;

  /// No description provided for @shopEditorHelpGridBody.
  ///
  /// In en, this message translates to:
  /// **'Draw the shop layout as a grid of cells. Use the + buttons to add rows and columns. You can start with a coarse grid and refine it later by splitting individual cells into halves.'**
  String get shopEditorHelpGridBody;

  /// No description provided for @shopEditorHelpGoodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Assigning goods'**
  String get shopEditorHelpGoodsTitle;

  /// No description provided for @shopEditorHelpGoodsBody.
  ///
  /// In en, this message translates to:
  /// **'Tap a cell to assign which goods are found there. The app uses this to plan the shortest route through your list.'**
  String get shopEditorHelpGoodsBody;

  /// No description provided for @shopEditorHelpEntranceTitle.
  ///
  /// In en, this message translates to:
  /// **'Entrance & exit'**
  String get shopEditorHelpEntranceTitle;

  /// No description provided for @shopEditorHelpEntranceBody.
  ///
  /// In en, this message translates to:
  /// **'Long-press a cell to set it as the entrance or exit. Navigation starts at the entrance and ends at the exit.'**
  String get shopEditorHelpEntranceBody;

  /// No description provided for @shopEditorHelpFloorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Multiple floors'**
  String get shopEditorHelpFloorsTitle;

  /// No description provided for @shopEditorHelpFloorsBody.
  ///
  /// In en, this message translates to:
  /// **'Add floors for shops with multiple levels. Each floor has its own grid, entrance, and exit.'**
  String get shopEditorHelpFloorsBody;

  /// No description provided for @shopEditorHelpSplitTitle.
  ///
  /// In en, this message translates to:
  /// **'Splitting cells'**
  String get shopEditorHelpSplitTitle;

  /// No description provided for @shopEditorHelpSplitBody.
  ///
  /// In en, this message translates to:
  /// **'Double-tap a cell to split it into two halves — useful for aisles with a left and right side. Long-press a split cell to promote the division across the whole row or column.'**
  String get shopEditorHelpSplitBody;

  /// No description provided for @shopEditorHelpClose.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get shopEditorHelpClose;

  /// No description provided for @firebaseHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Firebase setup'**
  String get firebaseHelpTitle;

  /// No description provided for @firebaseHelpProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Create a Firebase project'**
  String get firebaseHelpProjectTitle;

  /// No description provided for @firebaseHelpProjectBody.
  ///
  /// In en, this message translates to:
  /// **'Go to console.firebase.google.com, create a new project, and register an Android app with the package name com.fairelescourses.fairelescourses.'**
  String get firebaseHelpProjectBody;

  /// No description provided for @firebaseHelpFirestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Enable Firestore'**
  String get firebaseHelpFirestoreTitle;

  /// No description provided for @firebaseHelpFirestoreBody.
  ///
  /// In en, this message translates to:
  /// **'In the Firebase console, open Firestore Database and create a database in production mode.'**
  String get firebaseHelpFirestoreBody;

  /// No description provided for @firebaseHelpAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Enable Anonymous Auth'**
  String get firebaseHelpAuthTitle;

  /// No description provided for @firebaseHelpAuthBody.
  ///
  /// In en, this message translates to:
  /// **'Under Authentication → Sign-in method, enable the Anonymous provider. The app signs in anonymously to read and write data.'**
  String get firebaseHelpAuthBody;

  /// No description provided for @firebaseHelpRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Security rules'**
  String get firebaseHelpRulesTitle;

  /// No description provided for @firebaseHelpRulesBody.
  ///
  /// In en, this message translates to:
  /// **'Allow authenticated read/write for all documents. All data is encrypted client-side with the household ID — the server never sees plaintext.'**
  String get firebaseHelpRulesBody;

  /// No description provided for @firebaseHelpCredsTitle.
  ///
  /// In en, this message translates to:
  /// **'5. Your credentials'**
  String get firebaseHelpCredsTitle;

  /// No description provided for @firebaseHelpCredsBody.
  ///
  /// In en, this message translates to:
  /// **'In Project settings → Your apps, download google-services.json and paste it here, or enter the values manually.'**
  String get firebaseHelpCredsBody;

  /// No description provided for @firebaseAdvancedWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Configuring a custom Firebase instance requires creating and managing your own Firebase project. The built-in instance works for most users.\n\nContinue?'**
  String get firebaseAdvancedWarningBody;

  /// No description provided for @firebaseAdvancedContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get firebaseAdvancedContinue;

  /// No description provided for @firebaseHelpClose.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get firebaseHelpClose;

  /// No description provided for @localShopsSection.
  ///
  /// In en, this message translates to:
  /// **'Your shops'**
  String get localShopsSection;

  /// No description provided for @navViewModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Default navigation view'**
  String get navViewModeTitle;

  /// No description provided for @navViewModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Which view opens by default when navigating a list.'**
  String get navViewModeDesc;

  /// No description provided for @navViewModeGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get navViewModeGrid;

  /// No description provided for @navViewModeList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get navViewModeList;

  /// No description provided for @menuColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu color'**
  String get menuColorTitle;

  /// No description provided for @resetLocalDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset all local data'**
  String get resetLocalDataTitle;

  /// No description provided for @resetLocalDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will delete all local shops, lists, and settings. Continue?'**
  String get resetLocalDataConfirm;

  /// No description provided for @resetLocalDataDone.
  ///
  /// In en, this message translates to:
  /// **'All local data has been reset.'**
  String get resetLocalDataDone;

  /// No description provided for @celebrationTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get celebrationTitle;

  /// No description provided for @celebrationBody.
  ///
  /// In en, this message translates to:
  /// **'Happy shopping!'**
  String get celebrationBody;

  /// No description provided for @navListUpdated.
  ///
  /// In en, this message translates to:
  /// **'{n} new item(s) added to the list.'**
  String navListUpdated(int n);

  /// No description provided for @navUpdateRoute.
  ///
  /// In en, this message translates to:
  /// **'Update route'**
  String get navUpdateRoute;

  /// No description provided for @joiningStepUploadingShops.
  ///
  /// In en, this message translates to:
  /// **'Uploading shops…'**
  String get joiningStepUploadingShops;

  /// No description provided for @joiningStepUploadingLists.
  ///
  /// In en, this message translates to:
  /// **'Uploading lists…'**
  String get joiningStepUploadingLists;

  /// No description provided for @joiningStepJoining.
  ///
  /// In en, this message translates to:
  /// **'Joining household…'**
  String get joiningStepJoining;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Sync failed — changes saved locally and will retry automatically.'**
  String get syncError;

  /// No description provided for @sessionEndFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t end collaborative session. It will expire in 24 hours.'**
  String get sessionEndFailed;

  /// No description provided for @offlineIndicator.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get offlineIndicator;

  /// No description provided for @publishLayout.
  ///
  /// In en, this message translates to:
  /// **'Publish layout'**
  String get publishLayout;

  /// No description provided for @publishLayoutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share this cell layout with the community'**
  String get publishLayoutTooltip;

  /// No description provided for @publishLayoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Publish your current cell layout for this shop? Anyone can import it.'**
  String get publishLayoutConfirm;

  /// No description provided for @publishLayoutSaveFirst.
  ///
  /// In en, this message translates to:
  /// **'Save the shop before publishing.'**
  String get publishLayoutSaveFirst;

  /// No description provided for @publishLayoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Layout published.'**
  String get publishLayoutSuccess;

  /// No description provided for @publishLayoutError.
  ///
  /// In en, this message translates to:
  /// **'Could not publish layout. Check your connection.'**
  String get publishLayoutError;

  /// No description provided for @communityLayouts.
  ///
  /// In en, this message translates to:
  /// **'Community layouts'**
  String get communityLayouts;

  /// No description provided for @communityLayoutsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No community layouts shared yet for this shop.'**
  String get communityLayoutsEmpty;

  /// No description provided for @communityLayoutsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load community layouts.'**
  String get communityLayoutsError;

  /// No description provided for @communityLayoutsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get communityLayoutsRetry;

  /// No description provided for @communityLayoutUse.
  ///
  /// In en, this message translates to:
  /// **'Use this layout'**
  String get communityLayoutUse;

  /// No description provided for @communityLayoutImports.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 import} other{{n} imports}}'**
  String communityLayoutImports(int n);

  /// No description provided for @communityLayoutAge.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{today} =1{yesterday} other{{n} days ago}}'**
  String communityLayoutAge(int n);

  /// No description provided for @communityLayoutGrid.
  ///
  /// In en, this message translates to:
  /// **'{rows} × {cols}'**
  String communityLayoutGrid(int rows, int cols);

  /// No description provided for @browseLayouts.
  ///
  /// In en, this message translates to:
  /// **'Community layouts'**
  String get browseLayouts;

  /// No description provided for @browseLayoutsApplyWarning.
  ///
  /// In en, this message translates to:
  /// **'Applying a community layout will replace your current cell assignments.'**
  String get browseLayoutsApplyWarning;

  /// No description provided for @communityLayoutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Community layouts'**
  String get communityLayoutsTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
