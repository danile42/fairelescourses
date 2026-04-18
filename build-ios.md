# iOS Build – Fairelescourses

This document describes the steps to create an iOS release build (IPA) for the **Fairelescourses** app and deploy it to App Store Connect / TestFlight.

---

## Prerequisites

| Tool | Minimum version | Note |
|---|---|---|
| macOS | 14 (Sonoma) | Required for Xcode |
| Xcode | 16.x | Install from the Mac App Store |
| Flutter SDK | ≥ 3.41.5 | Check with `flutter --version` |
| CocoaPods | ≥ 1.15 | Check with `pod --version` |
| Apple Developer Account | – | Active membership required |
| Firebase CLI | current | Required for `flutterfire configure` |

---

## 1. Install project dependencies

```bash
flutter pub get
```

This step generates `ios/Flutter/Generated.xcconfig`, which is required by CocoaPods.

---

## 2. Install CocoaPods dependencies

```bash
cd ios
pod install
cd ..
```

> **Note:** If the pods are outdated or errors occur, clean first:
> ```bash
> cd ios
> pod deinstall --all
> pod install
> cd ..
> ```

---

## 3. Verify Firebase configuration

The file `ios/Runner/GoogleService-Info.plist` must exist and be up to date.
It is associated with the Firebase project **fairelescourses-app** (App ID `1:1089873679581:ios:13977102a70caf61133734`).

To regenerate the file:

```bash
flutterfire configure
```

Alternatively, it can be downloaded manually from the [Firebase Console](https://console.firebase.google.com) and copied to `ios/Runner/GoogleService-Info.plist`.

---

## 4. Configure code signing in Xcode

1. Open the workspace (not the `.xcodeproj`!):
   ```bash
   open ios/Runner.xcworkspace
   ```
2. In the Xcode project navigator, select **Runner** → **Signing & Capabilities**.
3. For the **Runner** and **RunnerTests** targets:
   - Set **Team** to your own Apple Developer team.
   - **Bundle Identifier**: `com.fairelescourses.app` (or as configured in Xcode).
   - Enable **Automatically manage signing** (recommended).

---

## 5. Update version and build number (optional)

The version is managed centrally in `pubspec.yaml`:

```yaml
version: 1.0.6+53
#        ^^^^^  ^-- Build number (CFBundleVersion)
#        |-------- Version number (CFBundleShortVersionString)
```

Adjust the value and then run `flutter pub get` again.

---

## 6. Build the release IPA

```bash
flutter build ipa --release
```

Optional flags:

| Flag | Description |
|---|---|
| `--obfuscate --split-debug-info=<path>` | Obfuscate Dart code (recommended for releases) |
| `--export-options-plist=<path>` | Use a custom `ExportOptions.plist` |
| `--build-name=<x.y.z>` | Override the version number |
| `--build-number=<n>` | Override the build number |

The finished IPA will be located at:

```
build/ios/ipa/fairelescourses.ipa
```

---

## 7. Upload IPA to App Store Connect

### Option A – Xcode Organizer (GUI)

```bash
open build/ios/archive/Runner.xcarchive
```

In the Organizer, follow **Distribute App** → **App Store Connect** → **Upload**.

### Option B – `xcrun altool` (CLI)

```bash
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/fairelescourses.ipa \
  --apiKey <API_KEY_ID> \
  --apiIssuer <ISSUER_ID>
```

### Option C – `flutter build ipa` + `xcrun notarytool` / Transporter

The `.ipa` file can also be uploaded via the macOS app **Transporter**.

---

## 8. TestFlight distribution (optional)

After uploading to App Store Connect:

1. In [App Store Connect](https://appstoreconnect.apple.com), activate the new build under **TestFlight**.
2. Invite testers or configure an external test group.

---

## Common errors

| Error | Solution |
|---|---|
| `Generated.xcconfig` missing | Run `flutter pub get` again |
| CocoaPods version conflicts | Run `pod repo update && pod install` |
| Signing errors | Check team and Bundle ID in Xcode |
| `GoogleService-Info.plist` missing | Download the file from the Firebase Console |
| `flutter build ipa` fails | Run `flutter doctor` and fix all issues |

---

## Useful commands

```bash
# Check Flutter environment
flutter doctor -v

# Delete all build artifacts
flutter clean && flutter pub get

# Build for simulator only (not a release)
flutter build ios --simulator

# Open Xcode workspace directly
open ios/Runner.xcworkspace
```