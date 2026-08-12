<!-- Historical prompt artifact. Sensitive values should be represented as
<Hidden value placed here, for security purposes> rather than real credentials. -->

# Gemini Implementation Prompt — Be Perfect

Copy everything below the separator into Gemini Flash 3.6 High while its working directory is the `Be-Perfect` repository.

---

You are the primary senior Flutter, Android, Firebase, and QA engineer responsible for implementing **Be Perfect**. Work directly in the current repository and continue until the largest safe, testable implementation milestone is complete. Do not stop after generating a mock UI or a high-level plan.

Read `README.md` first. Treat it as the product source of truth. This prompt is an implementation contract that makes the important requirements explicit.

## 1. Mission

Build a production-oriented Android Flutter application for coordinating timed rounds during church student-activity events.

One application supports two runtime roles:

- **controller:** a room controller.
- **Participant:** a read-only participant/viewer.

Any installation can create a room and become that room's controller. Other devices join that specific controller through a QR code or a six-digit numeric PIN.

Many independent controllers and rooms may exist concurrently. There is no developer-maintained master allowlist and no separate master APK. The Firebase project owner is not automatically a controller.

For V1:

- One device/UID owns and controls each room.
- A join PIN never grants controller authority.
- Clients are viewers and cannot change the schedule or send feed messages.
- One installation works with one selected active room at a time in the UI.
- The backend must isolate simultaneous rooms correctly.

Use the application ID and namespace:

```text
com.cyberbonk.beperfect
```

Use the display name:

```text
Be Perfect
```

## 2. Mandatory Working Rules

1. Inspect the repository, installed Flutter SDK, Android toolchain, Java, Node.js, Firebase CLI, and existing files before editing.
2. Preserve user-authored work. Do not delete or replace unrelated files.
3. If no Flutter project exists, initialize one in this repository with Android as the only required platform and organization `com.cyberbonk`.
4. Use current stable package versions that are mutually compatible. Pin resolved versions in `pubspec.lock`.
5. Do not invent Firebase project IDs, service-account files, API credentials, signing passwords, or the final custom audio binary.
6. Never place an Admin SDK key or FCM server credential in the Flutter application.
7. If live Firebase credentials are unavailable, implement and verify against the Firebase Emulator Suite. Clearly document the exact remaining live-configuration commands.
8. Keep the application buildable after every vertical slice.
9. Run formatting, static analysis, unit tests, emulator tests where possible, and a release build before claiming completion.
10. Maintain an `IMPLEMENTATION_STATUS.md` file containing:
    - Completed work.
    - Tests and commands run.
    - Current blockers.
    - Temporary assets or configuration.
    - Next concrete tasks.
11. Prefer direct, maintainable code over speculative abstractions or code generation.
12. Do not make network requests or database writes once per displayed second.
13. Do not keep a Dart isolate awake merely to update a notification countdown.
14. Do not claim a device state is synchronized when it is using cached data.

## 3. Platform Policy

The app is Android-only for this milestone.

- **Primary behavior and quality baseline:** Android 10 / API 29.
- **Intended minimum:** Android 8.0 Oreo / API 26.
- Configure:

```kotlin
minSdk = 26
```

Keep API 26 only if all core dependencies and the complete timer, Firebase, notification, reboot, and release tests pass without a degraded Oreo-specific implementation. If maintaining Oreo would materially risk correctness on Android 10+, document the evidence before proposing `minSdk = 29`.

Compile and target the current SDK required by the selected stable Flutter and notification packages. A low `minSdk` does not bypass the runtime rules of newer Android versions.

The release format is signed ABI-split APKs:

```powershell
flutter build apk --release --split-per-abi
```

This milestone does not include Google Play publication.

## 4. Product Defaults and Validation

Default room/run configuration:

| Setting | Default |
| --- | ---: |
| Participant capacity | 6 |
| Rounds | 6 |
| Round duration | 20 minutes |
| Cooldown | 0 seconds |

Participant capacity and round count are independent values.

Use sensible bounded validation:

- Participant capacity: 1–30.
- Round count: 1–30.
- Standard round duration: 1–180 whole minutes.
- Cooldown: 0–600 whole seconds.
- Participant display name: trimmed, 1–30 visible characters.
- Announcement: trimmed, 1–500 visible characters.
- Join code: exactly six numeric digits.

Participant-name uniqueness is case-insensitive after trimming and whitespace normalization.

## 5. Room and Identity Model

Use Firebase Anonymous Authentication. The anonymous UID persists through normal application restarts and identifies the installation.

### Creating a room

- Every authenticated installation can call `createRoom`.
- Generate a cryptographically random six-digit PIN on the trusted backend.
- Resolve collisions transactionally.
- Store an opaque random room ID separately from the PIN.
- The creator UID becomes `ownerUid`.
- Return the room ID and PIN to the creator.
- Generate a QR code containing a versioned invitation payload, not a Firebase credential.

Recommended QR payload:

```json
{
  "v": 1,
  "type": "be-perfect-room",
  "code": "123456"
}
```

### Joining

- Allow PIN entry or QR scanning.
- Ask the client for one unique custom Participant name.
- `joinRoom` validates:
  - Authenticated UID.
  - Valid open room.
  - Available capacity.
  - Unique normalized Participant name.
  - Idempotent rejoin by the same UID.
- Successful joining creates Firestore membership and the minimal Realtime Database membership mirror needed for presence rules.
- Joining does not expose `ownerUid` privileges.

### Ownership

- Only `ownerUid` can issue controller commands for that room.
- Another room owner has no access to this room unless explicitly joined.
- Clearing app data loses the anonymous identity and therefore room control. Show this limitation before room creation.
- Co-controllers, ownership recovery, and ownership transfer are explicitly out of scope.

### Room lifecycle

Room states:

```text
lobby
active
completed
closed
```

Run states:

```text
starting
running
paused
completed
ended
```

- Completing a run does not close the room.
- Members remain joined after completion.
- The owner can configure and start another run.
- Closing a room revokes membership access, removes messaging tokens, clears presence, cancels local room alarms, and returns clients to the home screen.

## 6. Timer and Schedule Contract

The backend owns schedule mutations. Clients render time locally from trusted timestamped state.

### Starting

- Starting a run creates a trusted future start timestamp five seconds ahead.
- The UI shows a synchronized `3`, `2`, `1` during the final three seconds.
- A late client jumps to the correct current point; it never begins an independent countdown.

### Running

- Progress displays `currentRound / totalRounds`.
- Progress uses round count, never Participant count.
- The server generates an explicit schedule of round and cooldown phases.
- Each phase includes:
  - Stable phase ID.
  - Phase type: `round` or `cooldown`.
  - Round index where relevant.
  - Trusted `startsAt`.
  - Trusted `endsAt`.
- Clients derive the effective current phase from time and the newest revision.
- Do not write a server value every second or at every visual tick.

### Round transition

At a non-final round boundary:

1. The scheduled local alarm fires.
2. The UI marks the round complete.
3. Cooldown begins.
4. The next full-duration round starts automatically.

If cooldown is zero, the next round starts immediately.

Normal automatic transitions do not use a special synchronized start overlay. The visible cooldown naturally counts down.

### Completion

At the final round boundary:

- Play the final local alarm.
- Derive the run as completed.
- Keep devices in the room.
- Replace the ongoing timer notification with a normal completion notification.

### Pause and resume

- Pause freezes whichever phase is active, including cooldown.
- Store the paused phase identity and trusted remaining milliseconds.
- Cancel obsolete local boundary alarms.
- Resume rebases the remaining schedule using a new trusted start timestamp five seconds ahead.
- Show synchronized `3-2-1` on resume.
- Rebuild and reschedule future local boundaries.

### Active-round adjustment

The controller receives exactly these controls:

```text
-5 minutes
-1 minute
+1 minute
+5 minutes
```

- Adjustments are valid only while a round phase is running.
- They affect only the active round's remaining duration.
- Future rounds retain the configured standard duration.
- Later absolute phase timestamps shift by the accepted delta.
- If subtraction reaches zero, end the current round normally and enter cooldown, the next round, or final completion as appropriate.

Also implement:

- End current round now.
- End event now.

### Revisions and idempotency

Every accepted room command:

- Includes a unique `clientCommandId`.
- Includes `expectedRevision`.
- Runs in a transaction.
- Validates owner and current effective state.
- Increments `revision`.
- Writes a feed event.
- Produces a notification outbox record when `notifyDevices` is true.

Clients:

- Accept only the highest revision.
- Deduplicate event IDs.
- Recompute current state on app resume.
- Cancel obsolete alarms before scheduling replacements.
- Never trust FCM as the state source.

## 7. Offline Contract

### Participant offline

- Continue the last confirmed schedule.
- Continue local round and cooldown derivation.
- Fire already scheduled local alarms.
- Display a persistent warning:

```text
Offline — timer continues, but recent changes may be missing.
```

- Use Firestore snapshot metadata and Realtime Database connection state to distinguish cached data from confirmed server state.
- On reconnect, load the newest revision, cancel obsolete alarms, and reconcile without duplicate alerts.

### Controller offline

- Continue displaying the last confirmed schedule.
- Disable all shared mutation controls.
- Do not queue pause, resume, time adjustment, message, removal, or ending commands.
- Explain that control requires reconnection.

### Limitations

- A client cannot receive a change that never reached it.
- Force-stopping the app in Android Settings disables alarms and FCM until reopening.
- Do not hide these limitations.

## 8. Background and Ongoing Notification Contract

Users do not need to keep the Flutter UI open.

Every controller and joined Participant device displays one ongoing Android notification while a run is:

- Starting.
- Running.
- Paused.
- In cooldown.

Use Android's system-rendered notification chronometer through `flutter_local_notifications`. Do not create a one-second background Dart timer.

The ongoing notification contains:

- Be Perfect and room identity.
- Current status.
- `Round X of N`.
- Countdown to current round end.
- Countdown to next round during cooldown.
- Static remaining time while paused.
- Tap action opening the correct room.
- Public lock-screen visibility, subject to device privacy settings.

Use behavior equivalent to:

```dart
AndroidNotificationDetails(
  'be_perfect_active_timer_v1',
  'Active event timer',
  ongoing: true,
  autoCancel: false,
  onlyAlertOnce: true,
  silent: true,
  playSound: false,
  visibility: NotificationVisibility.public,
  usesChronometer: true,
  chronometerCountDown: true,
  when: phaseEndTimestampMilliseconds,
)
```

Use one stable ongoing notification ID for the selected room. Exact scheduled local operations update that same notification at phase boundaries.

State behavior:

| State | Ongoing notification |
| --- | --- |
| Starting/resuming | Countdown to trusted start |
| Running | Countdown to round end |
| Cooldown | Countdown to next round |
| Paused | Static paused state and remaining time |
| Completed | Cancel ongoing notification; show normal completion |
| Left/closed | Cancel notification and pending alarms |

Implement and declare the receivers required by `flutter_local_notifications` for:

- Scheduled notifications.
- Exact alarms.
- Reboot restoration.
- Notification tap actions.

Use:

- `POST_NOTIFICATIONS` request on Android 13+.
- `SCHEDULE_EXACT_ALARM` and the user-facing special-access flow on versions that require it.
- `RECEIVE_BOOT_COMPLETED`.

Do not use `USE_EXACT_ALARM` unless a later distribution/policy review explicitly approves it.

Do not add a permanent foreground service in the first implementation. The system chronometer, persisted schedule, exact alarms, reboot restoration, and FCM background handling must be tried and tested first.

## 9. Custom Be Perfect Sound

The ongoing timer notification is silent.

Round boundaries use one bundled Be Perfect sound so all phones ring consistently.

Expected final asset:

```text
android/app/src/main/res/raw/be_perfect_round_alarm.wav
```

Reference it without the extension:

```dart
sound: const RawResourceAndroidNotificationSound(
  'be_perfect_round_alarm',
),
audioAttributesUsage: AudioAttributesUsage.alarm,
```

The final audio file has not yet been supplied. Do not fabricate or silently claim a placeholder is final. During development:

- If the resource exists, use it.
- If it does not exist, use a clearly documented temporary/system sound.
- Add a visible blocker to `IMPLEMENTATION_STATUS.md`.
- Keep the release gate failing until the final sound is provided and tested.

The bundled sound plays only for:

- Natural round completion.
- A round ended early by the controller.
- Final event completion.
- Settings sound test.

It must not play for:

- Ongoing notification refresh.
- Pause.
- Resume.
- Time adjustment.
- Cooldown start.
- Silent state synchronization.

Settings choices:

- **Be Perfect sound** — bundled sound plus vibration; default.
- **Device default** — default notification/alarm sound plus vibration.
- **Vibration only**.
- **Test sound**.
- **Open Android notification settings**.

Android 8+ notification channels are immutable after creation. Use separate stable channels:

```text
be_perfect_active_timer_v1
be_perfect_round_custom_v1
be_perfect_round_system_v1
be_perfect_round_vibration_v1
be_perfect_announcements_v1
```

Changing sound mode:

1. Updates the local preference.
2. Cancels remaining scheduled round alarms.
3. Reschedules them on the selected channel.

The user retains final control through Android volume, channel settings, silent mode, and Do Not Disturb. Detect disabled or low-importance channels where the API permits and link to system settings.

## 10. Announcements and Feed

The feed is one-way.

- controller can send announcements.
- Participants can only read.
- System control events appear in the feed.
- Both roles see the same allowed room feed.

For controller announcements and applicable control changes:

- `notifyDevices` defaults to `true`.
- Turning it off suppresses the FCM notification only.
- Synchronization and the feed audit event still occur.
- Local timer alarms are not controlled by this toggle.

Starting another run asks:

- **Keep history:** show all retained events with run dividers.
- **Fresh feed:** show only the new run in the current view without unsafe bulk deletion.

Use bounded, paginated feed queries.

## 11. Firebase Architecture

Use:

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_database`
- `firebase_messaging`
- `cloud_functions`

Use Cloud Functions v2 with TypeScript. Use a European Firebase region suitable for the project and colocate services where supported; do not hard-code a project ID before configuration.

### Firestore layout

Use a layout equivalent to:

```text
roomCodes/{sixDigitCode}
rooms/{roomId}
rooms/{roomId}/members/{uid}
rooms/{roomId}/runs/{runId}
rooms/{roomId}/feed/{eventId}
notificationOutbox/{eventId}
```

`roomCodes` must not expose room contents. It maps a short invitation code to an opaque room ID on the trusted backend.

Suggested room fields:

```text
ownerUid
state
sectorCapacity
activeRunId
revision
createdAt
updatedAt
closedAt
```

Suggested member fields:

```text
uid
sectorName
normalizedSectorName
joinedAt
updatedAt
notificationReadiness
exactAlarmReadiness
selectedSoundMode
fcmTokens
```

Suggested run fields:

```text
runId
status
revision
roundCount
standardRoundDurationMs
cooldownMs
startsAt
schedule[]
pausedState
createdAt
updatedAt
endedAt
```

Keep documents comfortably below Firestore size limits. A maximum of 30 rounds makes an explicit phase schedule practical.

### Callable Functions

Implement and validate operations equivalent to:

```text
createRoom
joinRoom
startRun
applyRoomCommand
sendAnnouncement
updateMember
leaveRoom
removeMember
refreshMessagingToken
closeRoom
```

Use typed request/response contracts shared or mirrored deliberately between TypeScript and Dart. Validate all server input; never rely on Flutter validation alone.

### FCM

- Store tokens under memberships.
- Refresh on token rotation.
- Send only to active members of the target room.
- Do not use one global FCM topic.
- Include `eventId`, `roomId`, `runId`, and `revision`.
- Use notification-plus-data messages for visible announcements where appropriate.
- Use data handling to trigger state refresh and ongoing-notification reconciliation.
- Add a top-level `@pragma('vm:entry-point')` Flutter background handler.
- Treat delivery as best effort.
- Deduplicate notification events on the client.

### Notification outbox

Room mutations atomically create unique outbox records when a push is requested. A Firestore-triggered function:

- Claims an unsent outbox record idempotently.
- Resolves current room member tokens.
- Sends the FCM message.
- Records delivery attempt metadata.
- Removes invalid tokens.

Cloud Function triggers may be duplicated or out of order. Do not depend on exactly-once delivery.

### Presence

Use Realtime Database:

```text
roomAccess/{roomId}/ownerUid
roomAccess/{roomId}/members/{uid}
presence/{roomId}/{uid}/connections/{connectionId}
presence/{roomId}/{uid}/lastSeen
```

- Use `.info/connected`.
- Register `onDisconnect` before marking the connection online.
- A client writes only its own connection.
- controller reads the roster for its room.
- Do not implement periodic Firestore heartbeat writes.

## 12. Security Rules

Write and emulator-test Firestore and Realtime Database rules.

Required invariants:

- Authentication is mandatory.
- Room owner can read its room and issue commands only through trusted Functions.
- Joined members can read only the room, current run, membership, and feed needed by the UI.
- Clients cannot directly modify owner, schedule, revision, feed system events, or other members.
- PIN knowledge alone never grants direct Firestore access.
- One room cannot read another room's data.
- Realtime Database clients write only their own connection nodes.
- Presence reads are limited to permitted room participants.
- Closed-room access is revoked.

Prefer denying direct writes to protected collections and routing mutations through callable Functions.

## 13. Flutter Architecture

Use Material 3 and Riverpod.

Recommended feature-first structure:

```text
lib/
  app/
  core/
    firebase/
    theme/
    notifications/
    time/
  features/
    home/
    rooms/
    lobby/
    timer/
    announcements/
    settings/
```

Use:

- Immutable Dart models.
- Dart 3 enums/sealed types where useful.
- Repository interfaces around Firebase.
- Pure timer/schedule derivation functions.
- Dependency injection through Riverpod providers.
- Streams only where live state is needed.

Avoid unnecessary code generation and excessive clean-architecture ceremony.

Suggested non-Firebase packages, only if compatible:

- `flutter_riverpod`
- `flutter_local_notifications`
- `timezone`
- `qr_flutter`
- `mobile_scanner`
- `shared_preferences`
- `package_info_plus`
- `url_launcher`

Do not use connectivity status alone as proof of internet access. Firebase connection state and snapshot metadata are the authoritative synchronization indicators.

## 14. Material 3 UI

No literal colors inside feature widgets. Use:

```dart
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.surface
Theme.of(context).colorScheme.errorContainer
Theme.of(context).textTheme
```

Use one polished initial `ColorScheme.fromSeed`. Seven selectable seed themes are a stretch goal only after core reliability passes.

### Home

- App identity.
- **Create room**.
- **Join room**.
- Restore active room when valid.

### Controller

Use Material 3 `NavigationBar` destinations:

- Dashboard.
- Announcements.
- Settings.

Dashboard contains:

- Six-digit PIN.
- QR code.
- Participant capacity, round count, duration, and cooldown configuration when editable.
- Joined-Participant roster.
- Online/offline and last seen.
- Notification and exact-alarm readiness.
- Timer state and controls.
- Default-enabled notify checkbox for applicable actions.

### Participant

Use `NavigationBar` destinations:

- Timer.
- Announcements.

Timer contains:

- `Round X / N` progress.
- Large central countdown with tabular figures.
- Running, paused, cooldown, starting, completed, and offline states.
- Persistent offline/stale warning.
- Accessible status not communicated by color alone.

### Settings

Include:

- Sound mode.
- Test sound.
- Open Android notification channel settings.
- Notification readiness.
- Exact-alarm readiness.
- Leave room where applicable.
- About page.

### About

Display:

> Developed for Be Perfect by [CyberBonk](https://github.com/CyberBonk)

The CyberBonk name opens:

```text
https://github.com/CyberBonk
```

Use the external browser. Also display application name, version, and build number.

## 15. Readiness Gate

Before a controller starts a run, show each joined device's available readiness:

- Currently online/offline.
- Last seen.
- Notification permission status.
- Exact-alarm permission status.
- Selected sound mode.
- Selected channel enabled/importance status where detectable.

Do not permanently block the owner from starting because one Participant is not ready, but require an explicit warning confirmation.

Each device gets a local readiness page with actions to:

- Request notification permission.
- Open exact-alarm settings.
- Open notification channel settings.
- Test the selected sound.
- Confirm current Firebase connection.

## 16. Testing Contract

### Dart unit tests

Test:

- Schedule generation.
- Current-phase derivation.
- Start and resume lead time.
- `3-2-1`.
- Zero and nonzero cooldown.
- Pause during round.
- Pause during cooldown.
- Resume schedule rebasing.
- `-5`, `-1`, `+1`, and `+5`.
- Subtraction crossing zero.
- Early round end.
- Early event end.
- Final completion.
- Mid-run join.
- Clock offset.
- Lifecycle resume.
- Higher/lower revision selection.
- Event-ID deduplication.

Use fake time; do not wait for real minutes.

### Flutter widget tests

Cover:

- Home.
- Create/join validation.
- controller lobby.
- Participant lobby.
- All timer states.
- Offline/stale banners.
- Readiness states.
- Announcement feed.
- Sound settings.
- About link.
- Material light/dark rendering.

### Functions and rules tests

Use Firebase Emulator Suite to prove:

- Any UID may create a room.
- Separate owners cannot control each other's rooms.
- PIN join never grants ownership.
- Outsiders cannot read room data.
- Members cannot modify schedules.
- Capacity survives simultaneous joins.
- Normalized Participant-name uniqueness survives races.
- Duplicate command IDs are idempotent.
- Stale revisions are rejected.
- FCM/outbox events do not cross rooms.
- Closed rooms reject further access.
- Realtime Database presence writes are self-only.

### Android integration matrix

Test at minimum:

- Android 8 / API 26.
- Android 10 / API 29.
- Android 12.
- Android 13.
- Android 14.
- Newest locally available Android image/device.

Test:

- One controller plus six Participants.
- Two simultaneous independent rooms.
- PIN and QR joining.
- Ongoing notification in shade and lock screen.
- System chronometer accuracy.
- UI closed/swiped away.
- Process reclaimed.
- Device reboot.
- Notification denied where applicable.
- Exact alarm denied/revoked where applicable.
- Manufacturer battery restrictions when real devices are available.
- Client offline through multiple rounds.
- Reconnect after controller changed schedule.
- controller offline.
- Delayed, duplicated, and out-of-order FCM.
- Bundled/system/vibration channel selection.
- Sound choice reschedules future alarms.
- Silent ongoing updates never replay alarm.
- Room completion, second run, and both feed-history choices.
- Closing one room does not affect another.
- Force-stop limitation and recovery after reopening.

### Acceptance criteria

- No per-second network writes.
- No per-second background Dart notification updates.
- Online timer displays agree within one displayed second after synchronization.
- Normal online commands appear within two seconds on a healthy test network.
- Ongoing notification agrees with the app within one displayed second.
- Notification transitions happen without opening the Flutter UI.
- Offline clients finish the last confirmed schedule.
- Reconnection adopts the newest revision without duplicate alarms.
- Default sound is identical across prepared phones.
- Security tests show complete room isolation.
- `flutter analyze` is clean.
- Unit/widget tests pass.
- Functions compile and emulator tests pass.
- Signed or signing-ready ABI-split release builds succeed.

## 17. Cost and Battery Guardrails

- Blaze is allowed because deployed Functions require it.
- Configure billing alerts and document that they are not a spending cap.
- Functions use `minInstances: 0`.
- Use a conservative `maxInstances` value.
- No polling loops.
- No Firestore heartbeat writes.
- No per-second state documents.
- Bounded/paginated feed reads.
- Listen only to the selected room's small active documents.
- Use local schedule derivation and Android chronometers.
- Do not add Analytics unless explicitly requested.

## 18. Explicitly Out of Scope

Do not implement:

- Multiple co-controllers inside one room.
- Ownership recovery or transfer.
- Student accounts.
- Student ratings.
- Team identities or rosters.
- Team movement tracking.
- “Team X is coming to your Participant.”
- Integration with the future student-rating application.
- Client chat or replies.
- iOS, web, desktop, or Google Play publication.

Keep room, Participant, run, round, phase, and future team concepts separate so deferred features remain possible.

## 19. Ordered Implementation Pipeline

Work in this order:

### Phase 0 — Grounding

- Inspect repository and tool versions.
- Read `README.md`.
- Create/update `IMPLEMENTATION_STATUS.md`.
- Confirm whether Flutter/Firebase scaffolding exists.
- Run current tests before changes.

### Phase 1 — Foundation

- Initialize Flutter Android project if absent.
- Set namespace/application ID.
- Set intended `minSdk = 26`.
- Add Material 3 theme and Riverpod.
- Add Firebase configuration hooks without inventing credentials.
- Add emulator configuration.
- Establish models, repositories, and root role/room state.
- Add CI-friendly format/analyze/test commands.

### Phase 2 — Rooms and lobby

- Anonymous auth.
- Cloud Functions TypeScript foundation.
- Room creation.
- PIN and QR join.
- Membership and capacity.
- controller and Participant lobby.
- Realtime Database presence.
- Security rules and emulator tests.

### Phase 3 — Timer engine

- Pure schedule generation and derivation.
- Start, rounds, cooldown, completion.
- Pause/resume.
- Active-round adjustment.
- Revision and idempotency.
- Unit tests with fake time.

### Phase 4 — Android background behavior

- Local notification channels.
- Ongoing chronometer.
- Exact boundary alarms.
- Reboot restoration.
- Permission/readiness flow.
- Temporary sound fallback clearly documented if final asset is absent.
- Lifecycle tests.

### Phase 5 — Announcements and FCM

- One-way feed.
- Notify checkbox.
- Token lifecycle.
- Notification outbox.
- FCM background handler.
- Cross-room isolation tests.

### Phase 6 — Polish and release

- About page.
- Accessibility.
- Error/loading/empty states.
- Multi-device rehearsal.
- Android 8 compatibility gate.
- Release signing configuration without committing secrets.
- ABI-split build.
- Final documentation and status report.

Do not start the seven optional themes until Phases 1–6 meet their core reliability gates.

## 20. Final Reporting Format

At the end of each substantial run, report:

1. What now works.
2. Files and major components added or changed.
3. Commands and tests run, with results.
4. Firebase or Android configuration still required from the user.
5. Whether the final custom sound is present.
6. Whether API 26 passed or remains unverified.
7. Known limitations.
8. The next highest-value implementation step.

Do not claim unrun tests passed. Do not claim background reliability from an emulator-only check. Separate verified facts from planned or unverified behavior.

Begin now by inspecting the repository and local toolchain, then implement Phase 0 and proceed into Phase 1 without waiting for permission unless a real credential, irreversible Firebase-region choice, signing secret, or missing user asset blocks that exact step.
