# localstore-app

Flutter client for **LocalStore**: a single-vendor storefront app for a local business (browse, cart, checkout, order tracking) with an in-app owner/admin mode unlocked by an owner or staff account. Android 9+ first; iOS stays one build away.

The backend is in [`localstore-api`](https://github.com/rachitt51/localstore-api). Product and domain docs live there: [scope](https://github.com/rachitt51/localstore-api/blob/master/docs/scope.md) · [domain model](https://github.com/rachitt51/localstore-api/blob/master/docs/domain-model.md) · [API surface](https://github.com/rachitt51/localstore-api/blob/master/docs/api-surface.md).

## Prerequisites

- Flutter stable (3.47+, Dart 3.13+) on `PATH`
- Android SDK + an emulator or a device (`flutter doctor` should be clean for Android)
- `localstore-api` running locally (see its README)

## Run locally

```powershell
flutter pub get
flutter run                                              # emulator -> API at http://10.0.2.2:3000
flutter run --dart-define=API_BASE_URL=http://<lan-ip>:3000   # physical device
```

The home screen shows `API: ok` when the app can reach `GET /health`.

## Checks

| Command | What |
|---|---|
| `dart format lib test` | Format |
| `flutter analyze` | Lints (`flutter_lints`) |
| `flutter test` | Widget + unit tests |

## Layout

```
lib/
  main.dart        entry point (ProviderScope)
  app/             MaterialApp, router (go_router), theme
  core/            cross-feature code: config (--dart-define), API client (dio)
  features/<area>/ one folder per area (auth, catalog, cart, checkout, orders, owner)
test/              mirrors lib/
```

State management is Riverpod; routing is go_router; HTTP is dio.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md): issue first, feature branch, Conventional Commits, PR with the template. No direct pushes to `master`.
