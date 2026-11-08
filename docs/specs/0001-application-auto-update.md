# Application Auto-Update & Release Management

## Status and agreed direction

Updated 24 October 2026 after inspecting the local Bokrah working copy. This is a development specification, not evidence that the feature is complete or released.

The first delivery checks official GitHub Releases and opens the matching installer URL in the system browser. The browser owns transfer progress, cancellation, the saved file, and transfer completion. Bokrah reports whether it successfully opened the URL; it must not claim that the installer downloaded or installed successfully.

The installed application version is currently declared as `3.3.0` in `pubspec.yaml`. `Demo v1.2.0` is the separate documentation edition and must not be used for application-version comparison.

## Contents

- [Problem statement](#problem-statement)
- [Solution](#solution)
- [User stories](#user-stories)
- [Implementation decisions](#implementation-decisions)
- [Observable behavior](#observable-behavior)
- [Acceptance criteria](#acceptance-criteria)
- [Working-copy observations](#working-copy-observations)
- [Testing decisions](#testing-decisions)
- [Out of scope](#out-of-scope)
- [Decisions before completion](#decisions-before-completion)
- [Further notes](#further-notes)

## Problem Statement

Users need a reliable way to discover a newer official Bokrah release, understand its changes, and obtain its installer without searching manually. Earlier update facilities were split between legacy Sparkle artifacts and an incomplete GitHub screen. The current working copy already introduces a repository, Cubit, release datasource, version comparison, update UI, and tests. Development should complete and verify that implementation against the behavior below.

## Solution

A platform-aware update checker built upon GitHub Releases. The intended startup check runs in the background without blocking accounting work. An available update can be presented in a dismissible prompt with Download Update, Later, and Skip This Version. Manual checking provides explicit success or failure feedback. Download Update opens the selected installer in the browser. This flow does not automatically execute installers or restart Bokrah.

## User Stories

1. As a Bokrah user, I want the application to automatically check for updates when I open the app, so that I am always aware of new features, bug fixes, and security improvements without manual intervention.
2. As a Bokrah user, I want background update checks to fail silently when I am offline or when API limits are hit, so that my workflow is never interrupted by intrusive error alerts during normal startup.
3. As a Bokrah user, I want to see an update alert dialog when a newer Release is available, so that I can quickly decide whether to upgrade immediately or continue working.
4. As a Bokrah user, I want to view the new version tag, publication date, and release changelog in the update prompt, so that I know what has changed before updating.
5. As a Bokrah user, I want to click "Download Update" to have my default browser open the direct download link for the platform-specific Installer Asset, so that the installer downloads reliably with full browser download management.
6. As a Bokrah user on Windows, I want the update checker to locate the `.exe` or `.msi` Installer Asset, so that I receive the correct Windows setup file.
7. As a Bokrah user on Android, I want the update checker to locate the `.apk` Installer Asset, so that I receive an Android package installable on my device.
8. As a Bokrah user on macOS, I want the update checker to locate the `.dmg` or `.zip` Installer Asset, so that I receive a compatible macOS installer.
9. As a Bokrah user, I want the option to click "Remind me later" on an update prompt, so that I can postpone the update without permanently dismissing it.
10. As a Bokrah user, I want the option to "Skip this version", so that I am not prompted again on subsequent launches for this specific Release version.
11. As a Bokrah user who previously skipped a version, I want to automatically receive an update prompt when an even higher Release version is published in the future, so that I don't miss subsequent releases.
12. As a Bokrah user, I want the home screen notification bell icon to display a notification indicator only when an unskipped update is actively available, so that the badge is truthful and meaningful.
13. As a Bokrah user, I want to navigate to a dedicated update status screen by tapping the notification bell or from Settings, so that I can inspect update status on demand.
14. As a Bokrah user, I want to manually trigger "Check for updates" on the update screen, so that I can force a check whenever I want to verify I have the latest build.
15. As a Bokrah user running a manual check, I want to see explicit error feedback if the network request fails or rate limits occur, so that I know why the manual check was unsuccessful.
16. As a Bokrah user on the latest version, I want to see a clear confirmation that my application is up to date, so that I have peace of mind.
17. As a developer, I want all obsolete WinSparkle and DSA signature files removed from the codebase, so that the project is maintainable and free of confusing dead code.

## Implementation Decisions

- **GitHub Releases as Single Distribution Authority**: In accordance with ADR 0001, GitHub Releases API serves as the single source of truth for release discovery, changelogs, and installer binary downloads.
- **Clean Architecture Boundaries**: The feature will be partitioned into three decoupled modules:
  - Domain module: Defines immutable models representing a Release and the platform Installer Asset, alongside an abstract repository contract for release queries and preference persistence.
  - Data module: Implements remote GitHub API client communication, platform-based asset pattern matching, local key-value persistence for skipped versions, and semantic version comparison against the genuine runtime application metadata.
  - Presentation module: Implements state management using Cubit, managing states for checking, available, up-to-date, and error conditions, differentiating between automatic background checks and explicit manual user checks.
- **Version Comparison**: Read the installed version from real platform metadata and compare numeric release-version components, including `1.10.0 > 1.9.0`. The existing comparator also orders numeric `+build` suffixes; this is an application-specific convention, not standard SemVer precedence. Confirm that policy before accepting build-only upgrades. Malformed versions must not be silently treated as zero.
- **Platform-Aware Asset Selection**: Installer Asset resolution examines the active platform operating system at runtime and filters release asset filenames by extension:
  - Windows: `.exe`, `.msi`
  - Android: `.apk`
  - macOS: `.dmg`, `.zip`
- **External Download Delegation**: When the user requests a download, URL launching delegates to the system's default browser rather than embedding an in-app file download manager.
- **Silent Background Error Handling**: Background checks isolate and log errors, transitioning the presentation state smoothly without popping error dialogs or snackbars. Manual checks propagate user-facing errors.
- **Preference Persistence**: Persist the skipped release version. A newer skipped release remains visible on the manual update screen but does not cause automatic prompts or a notification badge. Later dismisses the current prompt without persistently skipping the release. The current implementation suppresses versions less than or equal to the skipped version; confirm whether exact-version or threshold suppression is intended.
- **Dynamic Badge State**: The home page notification badge subscribes to the update state and activates only when an unskipped update is confirmed available.
- **Removal of Legacy Artifacts**: Legacy Sparkle removals are present in the current uncommitted changes. Verify remaining references and release tooling before considering that cleanup complete.

## Observable behavior

1. A background startup check must not block normal work. A failed background request produces no intrusive error prompt and must not be presented as a successful up-to-date check.
2. Manual checking shows Checking followed by Update Available, Up To Date, No Published Release, or an actionable error. An empty release list does not prove the installed app is the latest version.
3. An available release shows the installed version, release version, publication date when supplied, and release notes when supplied. Do not invent missing release metadata.
4. Stable distribution excludes draft and prerelease entries and compares valid versions explicitly. Do not assume the first release-list entry is the highest supported stable version.
5. Select the installer for the approved OS and architecture. File extension alone does not establish CPU architecture or distinguish an installer from an arbitrary archive. Approve a deterministic rule before supporting multiple assets for the same platform.
6. Download Update launches the selected official HTTPS asset URL externally. A successful launch means the browser was opened, not that a download completed. The browser manages the actual file transfer.
7. If the installer is missing or ambiguous, show an explicitly labeled View Release Page action instead of claiming a direct installer is available. If opening a URL fails, keep the update available and show a retryable error.
8. Later postpones the prompt. Skip This Version persists the agreed suppression preference. A higher eligible release can notify the user again. Manual checking still exposes an otherwise skipped release for deliberate downloading.
9. Automatic checks, prompts, and badges share one update state and must avoid duplicate requests or repeated prompts during a session. The dedicated update screen remains reachable when no badge is active.
10. Update discovery and browser handoff do not modify financial data, launch an installer, or close unsaved work. Installation remains a user-controlled step outside this feature.

## Acceptance criteria

| ID | Scenario | Expected result |
| --- | --- | --- |
| F07 AC01 | A compatible stable version is newer than the installed version | Show release details and the direct download action. |
| F07 AC02 | Installed version is equal to or greater than the eligible release | Do not offer an upgrade or downgrade. Compare `1.10.0` numerically above `1.9.0`. |
| F07 AC03 | Startup request fails while offline | Normal work continues; no intrusive update error or false up-to-date confirmation appears. |
| F07 AC04 | Manual request fails or is rate limited | Show failure and a retry path; respect the agreed timeout and retry policy. |
| F07 AC05 | Draft, prerelease, malformed version, or empty release list | Apply the documented stable-release policy; distinguish no published release from up to date. |
| F07 AC06 | User selects Download Update | Open the selected installer URL in the browser; never claim transfer or installation completion. |
| F07 AC07 | Installer is absent, ambiguous, or unsupported | Explain the condition and offer View Release Page when available. |
| F07 AC08 | External URL launch fails | Preserve the available release and provide an actionable retryable error. |
| F07 AC09 | User selects Later, then restarts | The release is not persistently skipped; the next approved automatic check may prompt again. |
| F07 AC10 | User skips a release and later a higher release appears | Persist suppression according to the agreed policy; allow the higher release to notify again. |
| F07 AC11 | User manually checks an otherwise skipped release | Show its details and permit intentional download without an automatic prompt. |
| F07 AC12 | Startup and manual checks overlap | No duplicated handoff or prompt; stale responses do not replace a newer result. |

## Working-copy observations

These observations are from source inspection on 24 October 2026. Tests have not been run as part of this documentation alignment.

- `data/datasources/github_release_datasource.dart` requests the GitHub releases list. `data/repositories/app_update_repository_impl.dart` currently selects its first entry; stable-release filtering and explicit selection remain to be verified or implemented.
- Runtime package metadata, external browser launching, skipped-version persistence, and Cubit check states are present in the working copy.
- `presentation/app_update_screen.dart` triggers manual checks and displays release information. A home-screen route exists. The inspected code does not yet wire a background startup check, show `UpdatePromptDialog` from a listener, or derive the home badge from `hasUnskippedUpdate`.
- `data/utils/platform_asset_matcher.dart` currently selects the first matching extension. It includes Linux candidates and macOS `.pkg` in addition to the initial story list. Supported distributions, architecture matching, and ambiguous assets need an explicit policy.
- The repository launcher returns a success boolean, but the screen and dialog callbacks currently ignore the result. Failed handoff feedback still needs implementation or verification.
- The Cubit currently falls back to `0.0.0` if installed-version lookup fails and no version is known; that must not be presented as the genuine installed version. An empty release response currently becomes Up To Date, which differs from the required distinction above.
- Comparator and Cubit test files exist. Their presence does not establish that the feature passes tests, works on supported devices, or has been released.

## Testing Decisions

- **Good Test Definition**: Tests must exercise external behavior and observable state transitions, never implementation details or internal private methods. Tests should verify that given specific installed versions and remote release responses, the feature emits expected states, correctly stores skipped versions, and respects silent versus loud error reporting.
- **Single Highest Test Seam**: The primary test seam is the state management Cubit seam wired to fake/mock remote datasources and in-memory key-value storage:
  - Verifies startup background checks emit available states for newer versions and silence errors on network failures.
  - Verifies manual check calls trigger error states when the remote datasource throws.
  - Verifies SemVer comparison with edge cases (e.g. `1.0.0` vs `1.0.1`, `3.3.0` vs `3.3.0+1`, single digit versions).
  - Verifies skipping a version suppresses available status on subsequent checks until a higher version is introduced.
  - Verifies platform asset resolution extracts the appropriate installer URL.
- **Prior Art**: The project's existing authentication cubit tests (`test/auth_cubit_test.dart`) establish the pattern: setting up in-memory storage, injecting zero-latency fake services into the cubit, and asserting state transitions.

## Out of Scope

- Silent in-app binary downloading, file checksum verification, and background process execution of installers without user interaction.
- In-app download progress, cancellation, saved-file management, transfer-complete claims, and resume behavior; the browser owns those operations in this delivery.
- Mandatory/blocking force-updates that lock users out of the application.
- Self-hosted release servers or custom appcast feed hosting.
- In-app differential delta patching.

## Decisions before completion

- Confirm the supported operating systems and CPU architectures and a deterministic installer asset naming/selection rule.
- Define stable release selection, malformed-version behavior, and whether numeric build metadata participates in upgrade precedence.
- Confirm exact-version versus threshold skip suppression, prompt frequency, and manual-download behavior for skipped releases.
- Choose where the startup check runs, when the dismissible prompt appears, and how concurrency and stale results are handled.
- Define request timeout, rate-limit feedback, retry timing, localized messages, and missing-installed-version behavior.
- Verify browser handoff and installer availability on every approved platform. Browser-managed transfer does not remove the publisher's responsibility for trustworthy release assets.

## Further Notes

- The repository coordinates (`owner` and `repo`) should reside in a centralized application configuration constant.
- Unauthenticated GitHub API calls are subject to rate-limiting (60 calls/hour per IP address). Silent background error handling ensures users never see disruptive errors if the rate limit is hit.
