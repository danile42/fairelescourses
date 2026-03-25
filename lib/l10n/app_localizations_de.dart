// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Fairelescourses';

  @override
  String get homeTitle => 'Einkaufslisten';

  @override
  String get newList => 'Neue Liste';

  @override
  String get noLists =>
      'Noch keine Einkaufslisten.\nTippe auf +, um eine zu erstellen.';

  @override
  String get noShops => 'Noch keine Märkte definiert.';

  @override
  String get shops => 'Märkte';

  @override
  String get newShop => 'Neuer Markt';

  @override
  String get editShop => 'Markt bearbeiten';

  @override
  String get shopName => 'Name des Markts';

  @override
  String get rows => 'Reihen (z. B. A B C D E)';

  @override
  String get cols => 'Spalten (z. B. 1 2 3 4 5)';

  @override
  String get entrance => 'Eingangsfeld (z. B. A1)';

  @override
  String get exit => 'Ausgangsfeld (z. B. E5)';

  @override
  String get cellGoods => 'Waren (kommagetrennt)';

  @override
  String cellGoodsAll(String cell) {
    return 'Alle Waren in $cell';
  }

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String deleteConfirm(String name) {
    return '\"$name\" löschen?';
  }

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get listName => 'Listenname';

  @override
  String get addItem => 'Artikel hinzufügen';

  @override
  String get itemHint => 'z. B. Milch';

  @override
  String get generatePlan => 'Plan erstellen';

  @override
  String get navigationTitle => 'Navigation';

  @override
  String get shop => 'Markt';

  @override
  String progress(int done, int total) {
    return '$done/$total Artikel';
  }

  @override
  String get unmatched => 'In keinem Markt gefunden';

  @override
  String get done => 'Fertig';

  @override
  String get finish => 'Abschließen';

  @override
  String stopItems(String items) {
    return 'Holen: $items';
  }

  @override
  String get preferredShops => 'Bevorzugte Märkte (optional)';

  @override
  String get noItemsInList => 'Noch keine Artikel. Tippe auf +.';

  @override
  String get planReady => 'Plan bereit';

  @override
  String editCell(String cell) {
    return 'Feld $cell bearbeiten';
  }

  @override
  String get gridRows => 'Reihen';

  @override
  String get gridCols => 'Spalten';

  @override
  String get editGrid => 'Raster bearbeiten';

  @override
  String get setEntrance => 'Als Eingang setzen';

  @override
  String get setExit => 'Als Ausgang setzen';

  @override
  String get allItemsChecked => 'Alle Artikel eingesammelt!';

  @override
  String get nextShop => 'Nächster Markt';

  @override
  String get listEditor => 'Liste bearbeiten';

  @override
  String get shopEditor => 'Markt bearbeiten';

  @override
  String moreGoods(int n) {
    return '+$n weitere';
  }

  @override
  String get ok => 'OK';

  @override
  String get searchShops => 'Märkte suchen';

  @override
  String get searchShopsHint => 'Marktname eingeben…';

  @override
  String get searchItemHint => 'Artikelname eingeben…';

  @override
  String get searchShopsMinChars => 'Mindestens 2 Zeichen eingeben.';

  @override
  String get noShopsFound => 'Keine Märkte gefunden.';

  @override
  String get shopAlreadyKnown => 'Bereits bekannt';

  @override
  String get shopImported => 'Markt importiert.';

  @override
  String get importShop => 'Importieren';

  @override
  String get searchByName => 'Nach Name';

  @override
  String get searchByItem => 'Nach Artikel';

  @override
  String get syncTitle => 'Synchronisierung';

  @override
  String get yourHouseholdId => 'Deine Haushalt-ID';

  @override
  String get createHousehold => 'Neuen Haushalt erstellen';

  @override
  String get joinHousehold => 'Haushalt beitreten';

  @override
  String get joinHouseholdHint => '6-stelligen Code eingeben';

  @override
  String get joinHouseholdInvalid =>
      'Code muss genau 6 Zeichen haben (A–Z, 0–9).';

  @override
  String get leaveHousehold => 'Haushalt verlassen';

  @override
  String get leaveHouseholdConfirm =>
      'Synchronisierung beenden und Haushalt verlassen?';

  @override
  String get shareHouseholdId => 'ID teilen';

  @override
  String get copiedToClipboard => 'Kopiert!';

  @override
  String get unsavedChanges => 'Du hast ungespeicherte Änderungen. Verwerfen?';

  @override
  String get discardChanges => 'Verwerfen';

  @override
  String get keepEditing => 'Weiter bearbeiten';

  @override
  String get searchByLocation => 'Nach Ort';

  @override
  String get homeLocation => 'Heimatort';

  @override
  String get setHomeLocation => 'Setzen';

  @override
  String get homeLocationHint => 'Stadt oder Adresse…';

  @override
  String get homeLocationSaved => 'Heimatort gespeichert.';

  @override
  String get homeLocationCleared => 'Heimatort gelöscht.';

  @override
  String get geocodeFailed =>
      'Ort nicht gefunden. Bitte anderen Begriff eingeben.';

  @override
  String get nearMe => 'In der Nähe (25 km)';

  @override
  String distanceKm(String distance) {
    return '$distance km';
  }

  @override
  String get shopAddress => 'Adresse (optional)';

  @override
  String get locationSearchHint => 'Ort eingeben…';

  @override
  String get noLocationSet =>
      'Kein Heimatort gesetzt. Gehe zu Synchronisierung.';

  @override
  String get geocoding => 'Suche Ort…';

  @override
  String get findNearby => 'In der Nähe suchen';

  @override
  String get osmShopsTitle => 'Nahegelegene Märkte (OpenStreetMap)';

  @override
  String get createShop => 'Erstellen';

  @override
  String get alreadyDefined => 'Bereits vorhanden';

  @override
  String get noOsmShopsFound => 'Keine Supermärkte in der Nähe gefunden.';

  @override
  String get osmSearching => 'Suche nahegelegene Supermärkte…';

  @override
  String get setLocationFirst =>
      'Lege zuerst einen Heimatort in Synchronisierung fest.';

  @override
  String get osmAttribution => 'Marktdaten © OpenStreetMap-Mitwirkende (ODbL)';

  @override
  String get osmLoadFailed =>
      'OpenStreetMap-Ergebnisse konnten nicht geladen werden.';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get mapView => 'Karte';

  @override
  String get listView => 'Liste';

  @override
  String get brandFilter => 'Marke';

  @override
  String get noShopsMatchFilter =>
      'Keine Märkte entsprechen dem ausgewählten Filter.';

  @override
  String splitCell(String cell) {
    return 'Feld $cell teilen';
  }

  @override
  String get splitAxisLabel => 'Wie teilen?';

  @override
  String get splitAxisRow => 'Reihe hinzufügen';

  @override
  String get splitAxisCol => 'Spalte hinzufügen';

  @override
  String get splitLeft => 'Links';

  @override
  String get splitRight => 'Rechts';

  @override
  String get splitTop => 'Oben';

  @override
  String get splitBottom => 'Unten';

  @override
  String get promoteSplit => 'Teilung übernehmen';

  @override
  String get promoteSplitDesc => 'Fügt eine echte Gitteraufteilung ein';

  @override
  String get revertSplit => 'Teilung rückgängig';

  @override
  String get revertSplitDesc => 'Hälften wieder zusammenführen';

  @override
  String get nowInShops =>
      'Jetzt in Märkten verfügbar – zum Abholen navigieren:';

  @override
  String get assignToShop => 'Markt zuordnen';

  @override
  String whichShopForItem(String item) {
    return 'In welchem Markt gibt es \"$item\"?';
  }

  @override
  String get firebaseInstanceTitle => 'Firebase-Instanz';

  @override
  String get firebaseInstanceDefault => 'Standard (eingebaut)';

  @override
  String firebaseInstanceCustom(String projectId) {
    return 'Benutzerdefiniert: $projectId';
  }

  @override
  String get firebaseInstanceChange => 'Ändern';

  @override
  String get firebaseInstanceSave => 'Übernehmen';

  @override
  String get firebaseInstanceReset => 'Auf Standard zurücksetzen';

  @override
  String get firebaseInstanceResetConfirm =>
      'Zur eingebauten Firebase-Instanz zurücksetzen? Du musst deinem Haushalt erneut beitreten.';

  @override
  String get firebaseInstanceSaved =>
      'Firebase-Instanz aktualisiert. Tritt deinem Haushalt erneut bei, um zu synchronisieren.';

  @override
  String get firebaseInstanceProjectId => 'Projekt-ID';

  @override
  String get firebaseInstanceApiKey => 'API-Schlüssel';

  @override
  String get firebaseInstanceAppId => 'App-ID';

  @override
  String get firebaseInstanceSenderId => 'Sender-ID';

  @override
  String get firebaseInstanceBucket => 'Storage Bucket';

  @override
  String get firebaseInstancePasteJson =>
      'Stattdessen google-services.json einfügen';

  @override
  String get firebaseInstanceJsonInvalid =>
      'google-services.json konnte nicht gelesen werden.';

  @override
  String get firebaseInstanceFieldsRequired => 'Alle Felder sind erforderlich.';
}
