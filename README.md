# TutorEverywhere
Project for 01418342 Mobile Application Design and Development

Frontend: Flutter

Backend: ExpressJS

Database: PostgreSQL

`npm install` to install dependencies first!

`npm install --only=dev` to install development depedencies

**Backend script commands:**

`npm run dev` to run api in development mode

**Essential frontend commands:**

`dart run build_runner build` to generate json serializable/ retrofit code

**Bind frontend to Railway backend**

```bash
flutter run --dart-define=API_BASE_URL=https://your-service-name.up.railway.app
```

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-service-name.up.railway.app
```

**Google Maps API key (Android)**

Add this to `tutoreverywhere_frontend/android/local.properties` (this file is ignored by git):

```
MAPS_API_KEY=YOUR_ANDROID_MAPS_API_KEY
```

You can also provide it in CI via environment variable:

```
MAPS_API_KEY=YOUR_ANDROID_MAPS_API_KEY
```

**Backend .env examples**

```
AUTH_SECRET_KEY=MobileAppAuthKey
PGHOST=localhost
PGPORT=5432
PGDATABASE=tutorApp
PGUSER=postgres
PGPASSWORD=somchok
```

**In exampleDB, password for teststudent, testtutor, and testadmin are 123456**
