# Contributing

## Every change starts with an issue

Open a GitHub issue (use an issue template) before writing code, including small fixes. The issue is what the branch and PR link back to, and where scope is agreed before code is written.

## No direct pushes to `master`

`master` is always releasable. Every change goes through a branch and a PR. The repo is private on a free plan, so server-side branch protection is not on yet; this is enforced by convention until it is. Do not push to `master` directly.

## Branching

- `master` — always releasable.
- Feature branches named after the issue: `<type>/<issue#>-<short-desc>`, e.g. `feat/7-otp-sign-in`, `fix/21-cart-badge-count`.
  `<type>` ∈ `feat | fix | chore | docs | refactor`.

## Commits — Conventional Commits

```
<type>(<scope>): <summary>
```

`type` ∈ `feat | fix | chore | docs | refactor | test | perf | ci | build`.
`scope` is the feature area: `auth`, `catalog`, `cart`, `checkout`, `orders`, `owner`, `core`, `app`.

## Definition of Done (every PR)

- Builds from a clean clone via `flutter pub get`; `pubspec.lock` committed.
- `dart format`, `flutter analyze` and `flutter test` pass.
- Widget/unit tests added or updated for new screens and logic.
- Checked on a real or emulated Android 9+ device.
- Owner-mode screens unreachable for `CUSTOMER` accounts.
- No secrets in code; config through `--dart-define`.
- API contract change → matching `localstore-api` PR linked.

## Local checks before pushing

```powershell
dart format lib test
flutter analyze
flutter test
```

## Workflow

1. Open or find the issue.
2. `git checkout master && git pull`
3. `git checkout -b <type>/<issue#>-<short-desc>`
4. Commit with Conventional Commits; keep the branch scoped to the issue.
5. Open a PR using the template; link the issue with `Closes #N`.
