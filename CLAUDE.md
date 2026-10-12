# Oogo

Minimalist kettlebell/bodyweight training app. Exported from Rork (`rork.json`). Two parts:

- `ios-oogo/` — native iOS app, SwiftUI, Swift 5, iOS 18.0 deployment target, Xcode project `Oogo.xcodeproj`.
- `backend/` — Supabase. Only `types.ts` (auto-generated DB types) was exported; no migrations or RLS policies are in the repo.

## iOS app layout (`ios-oogo/Oogo/`)

- `OogoApp.swift` — entry point. Creates `OogoStore` and `OogoSync`, injects them plus `AuthManager.shared` via `.environment(...)`. Syncs on launch, on sign-in, and when the scene becomes active.
- `ContentView.swift` — shows `OnboardingView` until `store.hasOnboarded`, then `RootTabView`.
- `ViewModels/OogoStore.swift` — main `@Observable` app state, persisted to `UserDefaults`. Source of truth for plan, history ("cave wall"), membership.
- `ViewModels/SessionRunner.swift` — live workout session timer/state.
- `Services/SupabaseService.swift` — shared `Backend.client` plus upsert/fetch DTOs.
- `Services/OogoSync.swift` — local ⇄ cloud sync of plan, sessions, membership.
- `Services/AuthManager.swift` — sign-in through **Rork Auth** (`ASWebAuthenticationSession`, callback scheme `rork-<projectID>`). The Rork JWT is passed to Supabase so RLS matches on `user_id()`.
- `Services/NudgeService.swift` — local notification reminders.
- `Models/` — `OogoModels` (movements, plans, sessions), `OogoRank`, `MovementCues`.
- `Theme/OogoTheme.swift` — design tokens: `OogoColor`, `OogoFont`, `OogoRadius`, `OogoMetric`, `OogoMotion`, `Haptic`. Use these instead of raw values.
- `Views/Components/OogoComponents.swift` — shared UI components (`OogoPrimaryButton`, `OogoChip`, `CaveWallGrid`, ...). Reuse before creating new ones.
- `Views/` — tabs (`TrainView`, `CampView`, `MethodView`, `ProfileView`), `SessionFlowView`, `PaywallView`, `Onboarding/`.

## Supabase tables

`profiles`, `hooman_plan`, `work_sessions`, `membership`. SQL function `user_id()`. See `backend/types.ts` for columns.

## Config and secrets

`ios-oogo/Oogo/Config.swift` has empty string values on purpose; Rork injected the real values at build time. It is listed in `ios-oogo/.gitignore`. To build outside Rork, fill in locally (never commit):

- `EXPO_PUBLIC_SUPABASE_URL`, `EXPO_PUBLIC_SUPABASE_ANON_KEY`
- `EXPO_PUBLIC_RORK_AUTH_URL`, `EXPO_PUBLIC_RORK_APP_KEY`, `EXPO_PUBLIC_PROJECT_ID`

## Known constraints

- Building and running needs macOS + Xcode. The dev machine is Windows, so code edits happen here and builds happen in Rork, on a Mac, or on a macOS CI runner.
- Auth depends on Rork's hosted auth service. If the app leaves Rork, `AuthManager` must be replaced (for example with Supabase Auth + Sign in with Apple).
- `PaywallView` has no StoreKit purchase code; membership is local state synced to the `membership` table.

## Conventions

- Swift Observation (`@Observable`, `@Environment(Type.self)`), not `ObservableObject`.
- Many types are marked `nonisolated`; keep concurrency annotations consistent with neighbors.
- App copy uses the "caveman" voice ("hooman", "cave wall", "Oog"). Match it in new UI text.
