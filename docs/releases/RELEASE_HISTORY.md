# Release history

This history is reconstructed from the recorded Desktop delivery folder, build
metadata, checksums, and project handoff records. APKs and AABs should be
attached to GitHub Releases rather than committed to the source tree.

The public repository was initialized after these delivery milestones, so the
release assets and checksums are the authoritative version evidence; earlier
source commits were not preserved in the original workspace.

| Version | Build | Position in the project | Evidence |
| --- | ---: | --- | --- |
| 2.1.0 | 4 | First verified delivery milestone | Desktop release folder, APK/AAB checksums, 36 tests, clean analyzer |
| 2.2.0 | 5 | Shared alarm and locale transition milestone | `pubspec.yaml`, Android metadata, recorded APK rebuild |
| 2.2.5 | 6 | Current polished release | `pubspec.yaml`, UI tests, release APK/AAB checksums, GitHub Release |

## 2.1.0+4

The first verified delivery package established the usable product baseline:

- English and Arabic localization, including the church-specific `تنويه` /
  `التنويهات` wording.
- Multi-room QR/PIN joining with controller and participant roles.
- Firestore-authoritative schedules with local countdowns and offline warnings.
- Persistent round alarms and ongoing Android timer notification behavior.
- Firebase base-plan fallback path, with Cloud Functions documented as an
  optional Blaze-plan enhancement.
- Obfuscated split-ABI APKs, an App Bundle, external symbol files, and
  `SHA256SUMS.txt`.
- Verification recorded as 36 passing Flutter tests, clean `flutter analyze`,
  and successful APK/AAB builds.

## 2.2.0+5

The current release line extends that baseline rather than changing the core
room model:

- Round-boundary alarm scheduling moved into the shared active-run listener so
  controllers and participants receive the same alarm behavior.
- Schedule-key deduplication prevents repeated alarm scheduling across run
  updates.
- English/Arabic locale changes use a 500 ms app-level fade transition.
- Version metadata moved from `2.1.0+4` to `2.2.0+5`.
- Release APKs were rebuilt with split ABIs, obfuscation, external symbols,
  resource shrinking, and minimized output.

The recorded `2.2.0+5` APK and App Bundle rebuilds are verified. The current
App Bundle is 62.2 MB and was built on 2026-08-12.

## 2.2.5+6

This release keeps the same controller/participant architecture and focuses on
the event experience and release presentation:

- System feed entries use short summaries instead of repeating full backend
  command text.
- Round transitions are presented as a clear **Next round** state.
- The timer card now foregrounds time remaining and shows compact round
  progress.
- Widget coverage verifies the compact summaries and cooldown presentation.
- Version metadata advanced to `2.2.5+6`.
- Obfuscated split-ABI APKs and an App Bundle were rebuilt with external symbol
  output and SHA-256 checksums.

The published `2.2.5+6` artifacts are the current release assets. The source
repository remains the place for code and documentation; binaries belong to the
GitHub Release.

## Difference at a glance

```text
2.1.0+4  ->  verified product baseline and first Desktop delivery
2.2.0+5  ->  shared controller alarms + duplicate-scheduling guard
              + 500 ms locale transition + refreshed release metadata/build
2.2.5+6  ->  shorter system summaries + clearer next-round timer state
              + compact timer card + refreshed release artifacts
```
