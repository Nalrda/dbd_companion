# DBD Companion

A Flutter companion app for **Dead by Daylight** — manage builds, track matches, plan with your squad, and randomize perks on the fly.

---

## Features

| Feature | Description |
|---|---|
| **Builds** | Create, save, and share Survivor & Killer perk builds. Import/export via share codes. |
| **Matches** | Log your games, track outcomes, and view win rate stats per role. |
| **Perks Browser** | Browse all Survivor and Killer perks with search and filtering. |
| **Randomizer** | Roll a random perk loadout for any role. Save the result as a build. |
| **Group Planner** | Coordinate perk builds for your full 4-player SWF squad. |
| **Maps** | Browse all realms and maps with callout references. |
| **Killers** | Browse killer roster with powers and add-on info. |

---

## Tech Stack

- **Flutter** — cross-platform (Android, iOS, Windows, Web, macOS, Linux)
- **Riverpod** — state management
- **Hive** — local storage
- **Firebase** — auth + cloud sync (Firestore)
- **go_router** — navigation
- **flutter_animate** — animations
- **Google Fonts** (Outfit) — typography

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>=3.0.0`
- Firebase project configured (see `firebase_options.dart`)

### Run

```bash
flutter pub get
flutter run
```

### Code generation (after model changes)

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Project Structure

```
lib/
├── app/              # Router & shell scaffold
├── core/
│   ├── models/       # Hive data models
│   ├── providers/    # Riverpod providers
│   ├── repositories/ # Data access (perks, maps, builds, etc.)
│   ├── services/     # Build sharing, guest mode
│   ├── theme/        # AppTheme — glassmorphism dark palette
│   └── widgets/      # Shared UI components & design system
├── features/
│   ├── auth/
│   ├── builds/
│   ├── group_planner/
│   ├── maps/
│   ├── matches/
│   ├── perks/
│   ├── randomizer/
│   └── settings/
└── main.dart
```

---

## Localization

The app supports **English** and **Polish**. Translations live in `lib/l10n/` and are generated via Flutter's `intl` tooling.

To regenerate after editing `.arb` files:

```bash
flutter gen-l10n
```

---

## Build Sharing

Builds can be exported as a compact share code (`DBD:...`) and imported by other players. Group plans use the `DBDG:...` format.
