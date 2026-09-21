# localstore-app

Flutter (Dart) client for a single-vendor local-store app: customer storefront plus an in-app owner mode. The NestJS backend and all product docs live in the sibling repo `localstore-api`.

## Read first
- `../localstore-api/docs/scope.md` — what is and is not in the MVP (Bootstrap tier of the client proposal).
- `../localstore-api/docs/domain-model.md` — entities, order state machine, pricing rules.
- `../localstore-api/docs/api-surface.md` — routes and roles the app consumes.

## Commands
- `flutter pub get`, `flutter run` (emulator reaches the host API at `http://10.0.2.2:3000`).
- `dart format lib test` / `flutter analyze` / `flutter test`.

## Conventions
- Feature-first: `lib/features/<area>/`; shared code in `lib/core/`; app wiring in `lib/app/`.
- Riverpod for state, go_router for navigation, dio (via `dioProvider`) for HTTP. No direct `Dio()` in features.
- Config only through `AppConfig` (`--dart-define`); no secrets or keys in the repo.
- Prices come from the API already computed; the app never re-derives a price.
- Owner-mode routes are guarded by role (`OWNER`/`STAFF`) in the router, not just hidden in the UI.
- Branch/PR/commit rules in `CONTRIBUTING.md` (Conventional Commits, issue-first, no direct pushes to `master`).
