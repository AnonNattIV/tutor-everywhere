# TutorEverywhere Frontend

## Bind App To Railway Backend

The app reads backend URL from compile-time define `API_BASE_URL`.

Example Railway URL:

```text
https://your-service-name.up.railway.app
```

Run on emulator/device:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://your-service-name.up.railway.app
```

Build release APK:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-service-name.up.railway.app
```

Build Android App Bundle:

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://your-service-name.up.railway.app
```

## Notes

- Use `https` Railway domain.
- If login fails, confirm Railway backend env vars and database connectivity are configured.
- If backend returns image URLs from object storage, app now supports both absolute URLs and relative paths.
