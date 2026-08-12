# Timer Be Perfect — Developer & QA Handoff

> **Product Name:** Timer Be Perfect
> **Event Identity:** Be Perfect
> **Product Source of Truth:** `README.md`, `docs/internal/prompts/GEMINI_IMPLEMENTATION_PROMPT.md`, and `docs/internal/prompts/ANTIGRAVITY_QA_HANDOFF.md`
> **Maintainer / Development Team:** CyberBonk
> **Package Name / Application ID:** `com.cyberbonk.beperfect`
> **Target Platform:** Android-only (`minSdk = 26`, primary baseline API 29+)

---

## 1. QA Handoff & Version Overview

This workspace contains the complete, upgraded, and verified implementation of **Timer Be Perfect**. All findings from `docs/internal/prompts/ANTIGRAVITY_QA_HANDOFF.md` have been addressed:

1. **Product & Installed Application Title:** Configured as **Timer Be Perfect** in `AndroidManifest.xml` and `main.dart`. Event identity remains **Be Perfect**.
2. **Temporary Logo Placeholder:** Displayed on `HomePage` reading **Insert Be Perfect logo here**.
3. **User-Facing Copy Cleaned:**
   - `Create Room` -> controller room creation
   - `Join as Participant` -> participant room joining
   - `Controller Dashboard` -> controller
   - `Participant Timer` -> participant
   - Jargon removed; `Controller` and `Participant` are the public role names.
4. **Alarm Audio Asset Integration:**
   - Copied `Here is the alarm.mp3` to `android/app/src/main/res/raw/be_perfect_round_alarm.mp3`.
   - Notification channel updated to `be_perfect_round_custom_v2` with `RawResourceAndroidNotificationSound('be_perfect_round_alarm')`.
5. **Firebase Environment Switch:**
   - Supports explicit `--dart-define=USE_FIREBASE_EMULATORS=true`.
   - Supports `--dart-define=PHYSICAL_PHONE_EMULATOR=true` for USB physical phone host `127.0.0.1` (with `adb reverse tcp:9099...`).
   - Displays a prominent error banner on `HomePage` if Firebase initialization is unconfigured or fails, disabling room actions gracefully.
6. **Major Version Package Upgrade:**
   - Upgraded to latest major package versions (`flutter_riverpod: ^3.4.1`, `flutter_local_notifications: ^22.2.0`, `cloud_firestore: ^6.7.1`, `cloud_functions: ^6.3.5`, `firebase_auth: ^6.5.6`, `firebase_core: ^4.12.1`, `firebase_database: ^12.4.6`, `firebase_messaging: ^16.4.3`, `mobile_scanner: ^7.4.0`, `package_info_plus: ^10.2.1`).
   - Codebase migrated to Riverpod 3 `NotifierProvider` and `flutter_local_notifications` 22.2+ named arguments API.
   - Added selectable M3 theme seed colors (Teal, Orange, Green, Blue, Deep Purple, Pink, Amber) in Settings inspired by Beacon reference.

---

## 2. Verification Results

- **`flutter analyze`:** **0 Errors** (Clean static analysis).
- **`flutter test`:** **7/7 Tests Passed** (100% test pass rate for schedule generation, 3-2-1 countdown, cooldowns, pause/resume rebasing, completion, and widget tree rendering).
- **`npm --prefix functions run build`:** **PASSED** (Compiled TypeScript Cloud Functions v2 without errors).

---

## 3. Directory & File Reference

```text
Be-Perfect/
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml          -> Timer Be Perfect label & permissions
│       └── res/raw/
│           └── be_perfect_round_alarm.mp3 -> Bundled alarm sound
├── functions/                           -> Serverless Cloud Functions v2 TypeScript
├── lib/
│   ├── app/routes.dart                  -> Controller, Timer, Announcements, Settings navigation
│   ├── core/
│   │   ├── firebase/                    -> RoomRepository, PresenceService, Riverpod 3 providers
│   │   ├── models/                      -> Room, Member, RoomRun, Phase, FeedEvent, SoundMode
│   │   ├── notifications/               -> NotificationService (22.2.0 API) & Channels
│   │   ├── theme/                       -> AppTheme (Selectable M3 seeds)
│   │   └── timer/                       -> ScheduleEngine (Pure schedule derivation)
│   ├── features/
│   │   ├── home/home_page.dart          -> Logo placeholder & Firebase error banner
│   │   ├── rooms/                       -> CreateRoomDialog, JoinRoomDialog, QrScannerPage
│   │   ├── timer/                       -> ControllerDashboardPage, ParticipantTimerPage, TimerDisplayWidget
│   │   ├── announcements/               -> AnnouncementsPage
│   │   └── settings/                    -> SettingsPage (M3 Seed Picker) & AboutPage
│   └── main.dart                        -> Application entry point & emulator toggle
├── test/
│   ├── unit/schedule_engine_test.dart   -> Schedule unit test suite
│   └── widget_test.dart                 -> App widget test
├── docs/internal/prompts/ANTIGRAVITY_QA_HANDOFF.md -> Independent QA findings log
├── docs/internal/IMPLEMENTATION_STATUS.md          -> Live milestone log
└── docs/internal/HANDOFF.md                        -> Developer handoff document
```

---

## 4. How to Run & Build

### Running with Firebase Emulators (Physical Phone / ADB Reverse)

```powershell
# Setup ADB port forwarding for physical USB Android 10 phone
adb reverse tcp:9099 tcp:9099
adb reverse tcp:8080 tcp:8080
adb reverse tcp:9000 tcp:9000
adb reverse tcp:5001 tcp:5001

# Run mobile app pointing to local emulators via 127.0.0.1
flutter run -d <device_id> --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=PHYSICAL_PHONE_EMULATOR=true
```

### Running with Firebase Emulators (Android Emulator)

```powershell
flutter run -d <emulator_id> --dart-define=USE_FIREBASE_EMULATORS=true
```

### Building Signed Release Split APKs

```powershell
flutter build apk --release --split-per-abi
```
