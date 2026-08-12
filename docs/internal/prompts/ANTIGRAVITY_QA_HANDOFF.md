<!-- Historical QA handoff. Sensitive values should be represented as
<Hidden value placed here, for security purposes> rather than real credentials. -->

# Antigravity QA Handoff — Timer Be Perfect

Updated: 2026-07-28

## Ownership

- Antigravity implements and repairs the application.
- Codex independently analyzes, builds, tests, and verifies it.
- Do not claim a milestone passes unless the commands are rerun against the
  current dependency lockfile and current source.

## Requested product changes

1. Set the installed Android application name and Flutter application title to
   **Timer Be Perfect**.
2. Retain **Be Perfect** as the event/project identity where natural.
3. Add a visible temporary logo placeholder reading **Insert Be Perfect logo
   here**. Do not manufacture a final logo; artwork will be supplied later.
4. Remove verbose role suffixes and jargon from user-facing copy:
   - `Create Room (controller)` becomes `Create Room`.
   - `Join Room (Participant)` becomes `Join Room`.
   - `controller Dashboard` becomes `Controller`.
   - `Participant View` becomes `Timer` or the participant's chosen display name.
   - Use `Controller` and `Participant` only where a role must be explained.
5. Internal class names and Firebase schema fields may remain unchanged to avoid
   a risky cosmetic refactor.
6. The supplied alarm source is:
   `Here is the alarm.mp3`
   Convert/copy it into an Android-supported resource with a lowercase
   underscore-only filename under `android/app/src/main/res/raw/`, then verify
   the notification channel uses it. Android notification channels are
   immutable after creation, so use a new channel ID when changing its sound.

## Current hard failures found by independent QA

The milestone report claiming clean analysis, tests, and release builds does not
match the current workspace.

Run from the repository root:

```powershell
flutter pub get
flutter analyze
flutter test
npm --prefix functions run build
flutter build apk --debug
```

Current results:

- `flutter analyze`: **fails with 27 compilation errors** plus warnings/hints.
- Timer engine: six unit tests pass.
- Widget test: cannot compile.
- Functions TypeScript build: passes.

Primary breakages:

1. The current Riverpod dependency no longer exposes `StateProvider` through
   the import/API used by `firebase_providers.dart`.
2. The current `flutter_local_notifications` dependency uses named parameters
   and a newer scheduling API, while `notification_service.dart` and
   `settings_page.dart` still use the older positional API.
3. Do not blindly upgrade dependencies. Either:
   - pin the last compatible dependency versions intentionally, or
   - migrate all affected code to the current APIs.
   Choose one coherent approach and regenerate the lockfile.

Acceptance gate:

- zero analyzer errors;
- all tests pass;
- fresh debug and ABI-split release builds succeed;
- install and cold-launch on the connected Android 10 phone;
- no fatal exceptions in logcat.

## Firebase correction required

The current Firebase behavior is not valid yet:

- There is no `google-services.json`.
- There is no generated `firebase_options.dart`.
- `Firebase.initializeApp()` errors are caught and ignored, allowing the UI to
  open while room actions remain unusable.
- Debug builds always use `10.0.2.2`, which reaches the host only from an
  Android emulator. It does not work from a physical Android phone without
  `adb reverse`.

Implement an explicit environment switch:

- Live/default build: initialize the selected Firebase project and never attach
  to local emulators.
- Emulator build: attach to Firebase emulators only when enabled by a Dart
  define such as `--dart-define=USE_FIREBASE_EMULATORS=true`.
- Android emulator host: `10.0.2.2`.
- Physical USB phone host: use `127.0.0.1` together with:

```powershell
adb reverse tcp:9099 tcp:9099
adb reverse tcp:8080 tcp:8080
adb reverse tcp:9000 tcp:9000
adb reverse tcp:5001 tcp:5001
```

Do not silently continue after Firebase initialization fails. Show a clear setup
or connection error and disable room operations.

## Device-test strategy

- Physical device available: Huawei VOG-L29, Android 10/API 29.
- This PC currently reports firmware virtualization disabled. Do not download a
  large x86 emulator image until virtualization is enabled in BIOS/UEFI and a
  Windows hypervisor backend is available.
- After virtualization is enabled, create an Android 8/API 26 emulator. It can
  act as the second client and simultaneously verify the declared minimum SDK.
- Until then, validate multi-client Firebase behavior with automated
  repository/emulator tests; do not claim real two-device notification or
  synchronization verification.

## API 26 status

`minSdk = 26` compiles conceptually with the selected architecture, but current
source does not compile. Passing a build alone is insufficient evidence of
Android 8 runtime compatibility. Verify on an API 26 emulator after the current
dependency/API failures are repaired.

Android 10 remains the primary physical-device baseline.
