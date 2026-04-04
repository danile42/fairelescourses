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
  String get emptyListsTitle => 'Noch keine Einkaufslisten';

  @override
  String get emptyListsBodyBefore =>
      'Erstelle eine Einkaufsliste und tippe auf';

  @override
  String get emptyListsBodyOr => 'oder';

  @override
  String get emptyListsBodyAfter => 'um deinen Markt zu navigieren.';

  @override
  String get emptyListsCreate => 'Liste erstellen';

  @override
  String get emptyShopsTitle => 'Noch keine Märkte';

  @override
  String get emptyShopsBody =>
      'Zeichne deinen Markt als Raster und weise den Feldern Waren zu.';

  @override
  String get emptyShopsCreate => 'Markt erstellen';

  @override
  String get emptyShopsFind => 'Markt suchen';

  @override
  String get tourNext => 'Weiter';

  @override
  String get tourSkip => 'Tour überspringen';

  @override
  String get tourStep1Title => 'Markt anlegen';

  @override
  String get tourStep1Body => 'Tippe auf + und wähle \'Neuer Markt\'.';

  @override
  String get tourShopSearchHint =>
      'Suche nach Standort, um nahegelegene Märkte zu finden – schneller als manuell anlegen.';

  @override
  String get tourShopEditorHint =>
      'Gib dem Markt einen Namen, tippe auf ein Feld und trage ein Produkt ein, dann tippe auf Speichern.';

  @override
  String get tourListEditorHint =>
      'Gib der Liste einen Namen und füge mindestens einen Artikel hinzu, dann tippe auf Speichern.';

  @override
  String get tourStep2Title => 'Einkaufsliste erstellen';

  @override
  String get tourStep2Body =>
      'Tippe auf + und wähle \'Neue Liste\'. Füge die gewünschten Artikel hinzu.';

  @override
  String get tourStep3Title => 'Navigation starten';

  @override
  String get tourStep3Body =>
      'Tippe auf den Play-Button neben deiner Liste, um deinen ersten Einkauf zu starten.';

  @override
  String get tourStep4Title => 'Märkte online suchen';

  @override
  String get tourStep4Body =>
      'Tippe auf + → Neuer Markt, um nahegelegene Märkte zu suchen. Importieren ist schneller als ein Layout von Hand zu zeichnen.';

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
  String get editCell => 'Feld bearbeiten';

  @override
  String get gridRows => 'Reihen';

  @override
  String get gridCols => 'Spalten';

  @override
  String get deleteRow => 'Reihe löschen?';

  @override
  String get deleteCol => 'Spalte löschen?';

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
  String get configTitle => 'Einstellungen';

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
  String get nearMe => 'Zuhause';

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
  String get navModeTitle => 'Navigationsmodus';

  @override
  String get navModeSingle => 'Einzeln';

  @override
  String get navModeSingleDesc => 'Alleine navigieren – keine Freigabe';

  @override
  String get navModeCollaborative => 'Gemeinsam';

  @override
  String get navModeCollaborativeDesc =>
      'Alle Haushaltsmitglieder sehen abgehakte Artikel in Echtzeit';

  @override
  String get navCollaborativeLabel => 'Gemeinsam';

  @override
  String get navCollaborativeActive => 'Gemeinsame Navigation aktiv';

  @override
  String get navJoin => 'Beitreten';

  @override
  String get mergeLists => 'Zusammenführen';

  @override
  String mergeListsSelected(int n) {
    return '$n ausgewählt';
  }

  @override
  String get mergeTargetTitle => 'In welche Liste zusammenführen?';

  @override
  String get mergeTargetSubtitle =>
      'Artikel aller anderen ausgewählten Listen werden hier hinzugefügt. Duplikate werden entfernt.';

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

  @override
  String get copyList => 'Kopieren';

  @override
  String get cancelTour => 'Tour abbrechen';

  @override
  String get catSupermarket => 'Supermarkt';

  @override
  String get catConvenience => 'Kiosk / Laden';

  @override
  String get catElectronics => 'Elektronik';

  @override
  String get catComputer => 'Computer';

  @override
  String get catDoItYourself => 'Baumarkt';

  @override
  String get catHardware => 'Eisenwaren';

  @override
  String get catBakery => 'Bäckerei';

  @override
  String get catButcher => 'Metzgerei';

  @override
  String get catPharmacy => 'Apotheke';

  @override
  String get catClothes => 'Kleidung';

  @override
  String get catDepartmentStore => 'Kaufhaus';

  @override
  String get catFurniture => 'Möbel';

  @override
  String get catBooks => 'Bücher';

  @override
  String get catSports => 'Sport';

  @override
  String get catGardenCentre => 'Gartencenter';

  @override
  String get catPet => 'Tierbedarf';

  @override
  String get catFlorist => 'Blumen';

  @override
  String get catShoes => 'Schuhe';

  @override
  String get collectLater => 'Später sammeln';

  @override
  String deferToShop(String shop) {
    return 'Bei $shop versuchen';
  }

  @override
  String get deferToNewList => 'Zur neuen Liste';

  @override
  String fromPreviousShop(String shop) {
    return 'Von $shop';
  }

  @override
  String get deferredToNextShop => 'Beim nächsten Markt versuchen';

  @override
  String get groundFloor => 'Erdgeschoss';

  @override
  String floorIndex(int n) {
    return 'Etage $n';
  }

  @override
  String get addFloor => 'Etage hinzufügen';

  @override
  String get removeFloor => 'Etage entfernen';

  @override
  String get floorName => 'Etagenname';

  @override
  String nFloors(int n) {
    return '$n Etagen';
  }

  @override
  String get moveToList => 'In Liste verschieben';

  @override
  String get copyToNewList => 'In neue Liste kopieren';

  @override
  String get moveToNewList => 'In neue Liste verschieben';

  @override
  String get rename => 'Umbenennen';

  @override
  String get startNavigation => 'Navigation starten';

  @override
  String get startShopping => 'Einkaufen starten:';

  @override
  String get viewGrid => 'Rasteransicht';

  @override
  String get viewList => 'Listenansicht';

  @override
  String get localOnlyMode => 'Nur lokaler Speicher';

  @override
  String get localOnlyModeDesc =>
      'Alle Daten bleiben auf diesem Gerät. Keine Synchronisierung, kein Haushalt.';

  @override
  String get localOnlyWarning =>
      'Nur-Lokal-Modus aktiv. Sync und Haushalt-Funktionen sind deaktiviert.';

  @override
  String get localOnlyConfirmEnable =>
      'Zum Nur-Lokal-Modus wechseln? Die Haushalt-Synchronisierung wird deaktiviert.';

  @override
  String get localOnlyConfirmDisable =>
      'Synchronisierung wieder aktivieren? Du kannst danach einem Haushalt beitreten.';

  @override
  String get helpTitle => 'So funktioniert Fairelescourses';

  @override
  String get helpClose => 'Los geht\'s';

  @override
  String get helpShopsTitle => 'Märkte';

  @override
  String get helpShopsBody =>
      'Lege einen Markt an und zeichne sein Layout als Raster. Weise Waren den Feldern zu, damit die App weiß, wo jedes Produkt zu finden ist.';

  @override
  String get helpListsTitle => 'Einkaufslisten';

  @override
  String get helpListsBody =>
      'Füge Artikel zu einer Einkaufsliste hinzu und wähle optional bevorzugte Märkte. Die App ordnet jeden Artikel einem Feld in deinen Märkten zu.';

  @override
  String get helpNavTitle => 'Navigation';

  @override
  String get helpNavBody =>
      'Tippe auf den Play-Button einer Liste, um die Navigation zu starten. Die App plant den kürzesten Weg durch alle passenden Felder und führt dich Schritt für Schritt.';

  @override
  String get helpSyncTitle => 'Sync & Haushalte';

  @override
  String get helpSyncBody =>
      'Tritt einem Haushalt mit anderen Personen bei, um Märkte und Listen zu teilen. Alle Haushaltsdaten werden mit deinem Haushaltscode verschlüsselt, bevor sie in der Cloud gespeichert werden. Einkaufslisten und Artikel sind für den Server nie lesbar.';

  @override
  String get helpDataTitle => 'Was wird wo gespeichert';

  @override
  String get helpDataLocal =>
      'Märkte und Listen werden immer lokal auf deinem Gerät gespeichert (auch ohne Sync).';

  @override
  String get helpDataCloud =>
      'Wenn du einem Haushalt beitrittst, werden Märkte und Listen auch mit Firebase synchronisiert – verschlüsselt mit deiner Haushalt-ID als Schlüssel.';

  @override
  String get helpDataLocalOnly =>
      'Im Nur-Lokal-Modus verlässt nichts dein Gerät.';

  @override
  String get shopEditorHelpTitle => 'So funktioniert der Markt-Editor';

  @override
  String get shopEditorHelpGridTitle => 'Das Raster';

  @override
  String get shopEditorHelpGridBody =>
      'Zeichne das Layout des Markts als Raster. Verwende die +-Schaltflächen, um Reihen und Spalten hinzuzufügen. Du kannst mit einem groben Raster beginnen und es später verfeinern, indem du einzelne Felder in zwei Hälften teilst.';

  @override
  String get shopEditorHelpGoodsTitle => 'Waren zuweisen';

  @override
  String get shopEditorHelpGoodsBody =>
      'Tippe auf ein Feld, um Waren zuzuweisen. Die App plant den kürzesten Weg durch alle passenden Felder.';

  @override
  String get shopEditorHelpEntranceTitle => 'Eingang & Ausgang';

  @override
  String get shopEditorHelpEntranceBody =>
      'Langes Tippen auf ein Feld setzt es als Eingang oder Ausgang. Die Navigation beginnt am Eingang und endet am Ausgang.';

  @override
  String get shopEditorHelpFloorsTitle => 'Mehrere Etagen';

  @override
  String get shopEditorHelpFloorsBody =>
      'Füge Etagen für Märkte mit mehreren Ebenen hinzu. Jede Etage hat ein eigenes Raster, Eingang und Ausgang.';

  @override
  String get shopEditorHelpSplitTitle => 'Felder teilen';

  @override
  String get shopEditorHelpSplitBody =>
      'Doppeltippen auf ein Feld teilt es in zwei Hälften – z. B. für Gänge mit linker und rechter Seite. Langes Tippen auf ein geteiltes Feld überträgt die Teilung auf die gesamte Reihe oder Spalte.';

  @override
  String get shopEditorHelpClose => 'Verstanden';

  @override
  String get firebaseHelpTitle => 'Eigene Firebase-Einrichtung';

  @override
  String get firebaseHelpProjectTitle => '1. Firebase-Projekt erstellen';

  @override
  String get firebaseHelpProjectBody =>
      'Gehe zu console.firebase.google.com, erstelle ein neues Projekt und registriere eine Android-App mit dem Paketnamen com.fairelescourses.fairelescourses.';

  @override
  String get firebaseHelpFirestoreTitle => '2. Firestore aktivieren';

  @override
  String get firebaseHelpFirestoreBody =>
      'Öffne Firestore Database in der Konsole und erstelle eine Datenbank im Produktionsmodus.';

  @override
  String get firebaseHelpAuthTitle => '3. Anonyme Authentifizierung';

  @override
  String get firebaseHelpAuthBody =>
      'Aktiviere unter Authentifizierung → Anmeldemethode den Anbieter \"Anonym\". Die App nutzt ihn für den Datenbankzugriff.';

  @override
  String get firebaseHelpRulesTitle => '4. Sicherheitsregeln';

  @override
  String get firebaseHelpRulesBody =>
      'Erlaube authentifizierten Lese-/Schreibzugriff für alle Dokumente. Alle Daten werden clientseitig mit der Haushalt-ID verschlüsselt – der Server sieht nie Klartext.';

  @override
  String get firebaseHelpCredsTitle => '5. Zugangsdaten';

  @override
  String get firebaseHelpCredsBody =>
      'Lade in Projekteinstellungen → Deine Apps die google-services.json herunter und füge sie hier ein, oder trage die Felder manuell ein.';

  @override
  String get firebaseAdvancedWarningBody =>
      'Die Konfiguration einer eigenen Firebase-Instanz ist ein fortgeschrittenes Feature. Du benötigst ein selbst verwaltetes Firebase-Projekt. Die eingebaute Instanz reicht für die meisten Nutzer aus.\n\nFortfahren?';

  @override
  String get firebaseAdvancedContinue => 'Fortfahren';

  @override
  String get firebaseHelpClose => 'Verstanden';

  @override
  String get localShopsSection => 'Deine Märkte';

  @override
  String get navViewModeTitle => 'Standard-Navigationsansicht';

  @override
  String get navViewModeDesc =>
      'Welche Ansicht beim Navigieren einer Liste standardmäßig geöffnet wird.';

  @override
  String get navViewModeGrid => 'Raster';

  @override
  String get navViewModeList => 'Liste';

  @override
  String get menuColorTitle => 'Menüfarbe';

  @override
  String get resetLocalDataTitle => 'Alle lokalen Daten zurücksetzen';

  @override
  String get resetLocalDataConfirm =>
      'Dadurch werden alle lokalen Märkte, Listen und Einstellungen gelöscht. Fortfahren?';

  @override
  String get resetLocalDataDone => 'Alle lokalen Daten wurden zurückgesetzt.';

  @override
  String get celebrationTitle => 'Alles bereit!';

  @override
  String get celebrationBody => 'Viel Spaß beim Einkaufen!';
}
