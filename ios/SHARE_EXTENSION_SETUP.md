# iOS Share Extension — setup checklist

The app can receive links, text, and files shared into it from other apps'
"Share" sheet. On **Android this works out of the box** (already wired in the
manifest). On **iOS** it needs a small one-time setup in Xcode that can only be
done on a Mac — the steps below.

Everything the extension *runs* is already in the repo:

- `ios/Share Extension/ShareViewController.swift` — the extension code.
- `ios/Share Extension/Info.plist` — declares what it accepts (text, 1 URL, up
  to 10 files/images).
- `ios/Share Extension/Share Extension.entitlements` — App Group membership.
- `ios/Runner/Runner.entitlements` — the same App Group for the main app.
- `ios/Runner/Info.plist` — already has the `ShareMedia-…` URL scheme.

You just need to wire these into the Xcode project (create the target, attach
the App Group). Nothing here can break the Android build.

## The App Group id used everywhere

```
group.com.eijao.speedReadingApp
```

(The app's bundle id is `com.eijao.speedReadingApp`.) If you ever change the
bundle id, update the group id in both `.entitlements` files too.

## Steps in Xcode

1. `open ios/Runner.xcworkspace` (run `flutter pub get` first so the pods exist).

2. **Create the extension target.** File → New → Target → **Share Extension**.
   - Product name: `Share Extension`
   - Language: Swift
   - When prompted "Activate scheme?", click **Cancel** (keep the Runner
     scheme active).

3. Xcode generated a `Share Extension/` group with its own `ShareViewController.swift`,
   `Info.plist`, and maybe a `MainInterface.storyboard`. **Replace** the
   generated `ShareViewController.swift` and `Info.plist` with the ones already
   in this repo at `ios/Share Extension/` (delete the storyboard — this repo's
   Info.plist uses a principal class instead of a storyboard). The easiest way:
   delete the files Xcode made, then drag the repo's versions into the target.

4. **App Group — main app.** Select the **Runner** target → Signing &
   Capabilities → **+ Capability → App Groups** → add `group.com.eijao.speedReadingApp`.
   Then set Runner's "Code Signing Entitlements" build setting to
   `Runner/Runner.entitlements` if Xcode didn't already point at it.

5. **App Group — extension.** Select the **Share Extension** target → do the
   same: App Groups capability → `group.com.eijao.speedReadingApp`, and point
   its entitlements at `Share Extension/Share Extension.entitlements`.

6. **Pods for the extension.** Open `ios/Podfile` and add a target block so the
   plugin's native pod is available to the extension:

   ```ruby
   target 'Share Extension' do
     use_frameworks!
     use_modular_headers!
     pod 'receive_sharing_intent', :path => '.symlinks/plugins/receive_sharing_intent/ios'
   end
   ```

   Then run `cd ios && pod install`.

7. **Deployment target.** Make sure the Share Extension target's minimum iOS
   version is **≥ 13.0** (match Runner).

## SceneDelegate note (important)

This project uses the newer `SceneDelegate` (see `ios/Runner/SceneDelegate.swift`),
not the classic `AppDelegate` URL handling. The extension re-opens the app via
the `ShareMedia-…` URL scheme, so that URL must be forwarded from the scene.
Add this to `SceneDelegate`:

```swift
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    // Let Flutter plugins (receive_sharing_intent) see the incoming URL.
    // No extra code needed if the Flutter engine's plugin registrant handles it;
    // if links don't arrive on a cold share, forward URLContexts here.
}
```

If shares don't reach the app after setup, this forwarding is the first place to
check.

## How to verify (on device/simulator)

1. Run the app once so it's installed.
2. From Safari, tap Share → **Speed Reader** on a web page → the app should open,
   fetch the page, and drop you straight into the reader.
3. From Files, share a PDF/EPUB → same thing.
4. Select some text anywhere → Share → **Speed Reader** → it becomes a book.

The Dart side (`lib/widgets/share_intent_listener.dart`) already routes each of
these: a link is fetched, a file is parsed by extension, plain text becomes a
book — then the reader opens automatically.
