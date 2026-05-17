# my_bill

Electricity and water bill management for 6 rooms, with Khmer + English UI,
auto-calculation, history, PDF invoice export, and Excel export.

## Features

- Dashboard with monthly totals (KHR + USD), kWh, m3, rooms reported, and a
  6-month bar trend rendered with `CustomPaint`.
- Per-room summary tiles and a dedicated room detail page.
- Input usage form with live bill preview and validation.
- History view with room + month filters.
- Settings: tariff rates, FX rate (KHR/USD), language (en/km), room renaming,
  and a reset-data action.
- Bottom navigation + centered floating action button.
- PDF invoice export (A5, bundled Noto Sans Khmer font).
- Excel export with a `Summary` sheet and one sheet per room.
- Firebase Firestore history (optional, falls back to local storage when not
  configured).
- No authentication.

## Run locally

```bash
flutter pub get
flutter run
```

The app ships with **no demo data**. The dashboard, history, and per-room
pages all start empty until you tap the floating "+" button and enter
real meter readings. Every save flows through the repository abstraction
and lands in Firestore (or local storage when Firebase isn't configured).

## Firestore

`lib/firebase_options.dart` is already generated (project `my-bill-1a987`) and
`lib/services/firebase_bootstrap.dart` calls
`Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`. On
start, `main.dart` brings Firebase up and swaps to
`FirestoreReadingsRepository`. The `readings` collection only ever contains
documents the user has saved through the input form.

If you reconfigure or move projects, just re-run:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### Firestore security rules

The repo ships `firestore.rules`. Because the app has no authentication,
they:

- allow read/write on `readings/{docId}` only when the document shape is
  valid (string `roomId`, `yearMonth` matching `YYYY-MM`, numeric
  meters with `curr >= prev`, timestamps for `month` and `createdAt`);
- allow read/write on `settings/{docId}` (the rates/FX/locale mirror);
- deny everything else.

Deploy them with the Firebase CLI:

```bash
firebase deploy --only firestore:rules --project my-bill-1a987
```

Or paste the contents of `firestore.rules` into the Firebase console under
**Firestore Database → Rules**. A default of `allow read, write: if false`
blocks the app entirely; replacing it with this file is required for the
input form to write and the dashboard to read.

These rules are still open to anyone who knows the project id. Before
shipping publicly, layer App Check on top, or add Firebase Auth and
switch them to `request.auth != null`.

If `Firebase.initializeApp` fails on a given platform (for example Linux
desktop, which the generated options skip), the app silently falls back to
the local `SharedPreferences` repository.

## Project layout

```
lib/
  app.dart                          MaterialApp + locale wiring
  main.dart                         entry, DI, Firebase bootstrap
  core/                             constants, theme, formatters
  models/                           Room, Reading, BillBreakdown, AppSettings
  services/                         repositories, bill calculator, PDF, Excel
  controllers/                      GetX controllers
  ui/
    shell/app_shell.dart            BottomNavigationBar + FAB
    dashboard/                      stats cards, room tiles, trend chart
    rooms/                          rooms list, room detail
    input/                          input usage form + live preview
    history/                        history list with filters
    settings/                       rates, FX, language, room names
  l10n/                             app_en.arb + app_km.arb (+ generated)
assets/fonts/NotoSansKhmer-Regular.ttf
```

## Testing

```bash
flutter test
```

Unit tests cover the pure bill calculator.
