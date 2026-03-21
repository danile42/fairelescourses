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
  /// **'Shopping Lists'**
  String get homeTitle;

  /// No description provided for @newList.
  ///
  /// In en, this message translates to:
  /// **'New List'**
  String get newList;

  /// No description provided for @importText.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importText;

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

  /// No description provided for @shops.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get shops;

  /// No description provided for @newShop.
  ///
  /// In en, this message translates to:
  /// **'New Shop'**
  String get newShop;

  /// No description provided for @editShop.
  ///
  /// In en, this message translates to:
  /// **'Edit Shop'**
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

  /// No description provided for @generatePlan.
  ///
  /// In en, this message translates to:
  /// **'Generate Plan'**
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

  /// No description provided for @shareShop.
  ///
  /// In en, this message translates to:
  /// **'Share shop'**
  String get shareShop;

  /// No description provided for @shareList.
  ///
  /// In en, this message translates to:
  /// **'Share list'**
  String get shareList;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importTitle;

  /// No description provided for @importHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a shop definition or shopping list here…'**
  String get importHint;

  /// No description provided for @importAction.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importAction;

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Could not parse the text. Please check the format.'**
  String get importError;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported successfully.'**
  String get importSuccess;

  /// No description provided for @appendToExisting.
  ///
  /// In en, this message translates to:
  /// **'Append to existing list'**
  String get appendToExisting;

  /// No description provided for @importAsNew.
  ///
  /// In en, this message translates to:
  /// **'Import as new list'**
  String get importAsNew;

  /// No description provided for @selectList.
  ///
  /// In en, this message translates to:
  /// **'Select list'**
  String get selectList;

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
  /// **'Edit cell {cell}'**
  String editCell(String cell);

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

  /// No description provided for @editGrid.
  ///
  /// In en, this message translates to:
  /// **'Edit Grid'**
  String get editGrid;

  /// No description provided for @setEntrance.
  ///
  /// In en, this message translates to:
  /// **'Set as entrance'**
  String get setEntrance;

  /// No description provided for @setExit.
  ///
  /// In en, this message translates to:
  /// **'Set as exit'**
  String get setExit;

  /// No description provided for @exportFormat.
  ///
  /// In en, this message translates to:
  /// **'Text Format'**
  String get exportFormat;

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
  /// **'Edit List'**
  String get listEditor;

  /// No description provided for @shopEditor.
  ///
  /// In en, this message translates to:
  /// **'Edit Shop'**
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

  /// No description provided for @searchShopsHint.
  ///
  /// In en, this message translates to:
  /// **'Type a shop name…'**
  String get searchShopsHint;

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

  /// No description provided for @searchByName.
  ///
  /// In en, this message translates to:
  /// **'By name'**
  String get searchByName;

  /// No description provided for @searchByItem.
  ///
  /// In en, this message translates to:
  /// **'By item'**
  String get searchByItem;

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncTitle;

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
  /// **'Near me (25 km)'**
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
