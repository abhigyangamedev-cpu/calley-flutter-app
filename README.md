# Calley

Flutter app built from the "Get Calley App" Figma design and the Calley Mock API V2 (Postman).

## Screens
Language selection → Register → WhatsApp OTP verification → Sign in → Welcome (intro video) → Dashboard (calling lists bottom sheet, list detail with call-status donut chart, side drawer).

## Run
```bash
flutter pub get
flutter run
flutter test
```

A release APK is attached to the GitHub release.

## API
Base URL: `https://mock-api.calleyacd.com/api` (register, send/verify OTP, login, calling lists).

At the time of writing the mock server returns HTTP 404 / a mismatched TLS certificate, so the app
falls back to a built-in **demo mode** (amber banner) when the API is unreachable:
- OTP: `123456`
- Sample list: "Test List" (27 pending / 23 done / 11 scheduled)

Once the API is back up, the app uses it automatically.

See [SUBMISSION_NOTES.md](SUBMISSION_NOTES.md) for the server status, the endpoints, and the
TLS workaround.
