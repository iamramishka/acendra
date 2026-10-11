# Flutter dependency integration (CSA-037)

Owner: CODEX. Coordination: GitHub issue #39; source PRs #34–36.
Base: dev. SDK: Flutter 3.44.0 / Dart 3.12.0.

The bot-generated lockfiles selected newer SDK-pinned dependencies
(meta, matcher, test_api and vector_math) that Flutter 3.44 cannot restore.
Resolve with the pinned Flutter SDK and commit its generated pubspec.lock.
Keep CI's --enforce-lockfile check.

The combined update uses flutter_riverpod 3.4.3, riverpod_annotation 4.0.7,
riverpod_generator 4.0.9 and flutter_lints 6.0.0. The stable generator's
upstream dependency includes riverpod_analyzer_utils 1.0.0-dev.12;
no direct dependency selects a prerelease.

build_runner is bounded to >=2.15.1 <2.15.2. Releases from 2.15.2 onward
require analyzer >=13.3, which needs meta newer than Flutter 3.44's
meta 1.18.0 pin. The resolver selects analyzer 13.0.0 with 2.15.1.
Revisit this bound when the approved Flutter SDK changes. Do not use
dependency_overrides or relax CI to force a newer release.

Riverpod migration: AsyncValue.value replaces valueOrNull; StateProvider
uses Riverpod's supported legacy import to retain the existing verification
email contract. Stream tests keep an active listener and dispose their
container before closing the stream, matching Riverpod 3 pause behavior.
New coverage exercises sign-in/sign-out propagation, failed auth streams
and verification-email updates. New lint diagnostics use Dart wildcard
parameters for unused callback arguments.

References:
- https://riverpod.dev/docs/3.0_migration
- https://pub.dev/packages/build_runner/versions/2.15.1
- https://pub.dev/packages/build_runner/versions/2.15.2
- https://pub.dev/packages/riverpod_generator/versions/4.0.9

Verification commands:
- flutter pub get --enforce-lockfile
- dart format --output=none --set-exit-if-changed lib test
- flutter analyze --no-pub
- flutter test --no-pub --concurrency=1
- dart run build_runner build --build-filter=lib/dependency_codegen_smoke.g.dart (temporary annotated provider; generated provider executed successfully)
- flutter build web --release --no-pub

The initial Windows test run exhausted memory with default parallel workers.
Use one worker on this laptop; clean hosted CI retains normal concurrency.
Executed results and CI links are recorded in the integration PR and issue #39.
No database or deployment changes are part of this update.
