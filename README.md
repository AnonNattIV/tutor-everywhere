# TutorEverywhere
Project for 01418342 Mobile Application Design and Development

Frontend: Flutter

Backend: ExpressJS

Database: PostgreSQL

`npm install` to install dependencies first!

`npm install --only=dev` to install development depedencies

**Backend script commands:**

`npm run dev` to run api in development mode

**Backend with Docker (`docker run`)**

Build image:

```bash
docker build -t tutor-everywhere-backend ./tutoreverywhere_backend
```

Run container (uses root `.env` file):

```bash
docker run --rm -p 3000:3000 --env-file ./.env --name tutor-everywhere-backend tutor-everywhere-backend
```

Backend supports both `PG_*` and `DB_*` env names for database config.
If your database does not use SSL, set `PGSSL=disable` (or `DB_SSL=false`) in `.env`.

**Essential frontend commands:**

`dart run build_runner build` to generate json serializable/ retrofit code

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

# S3-compatible object storage (Railway bucket or compatible provider)
OBJECT_STORAGE_BUCKET=your-bucket-name
OBJECT_STORAGE_ENDPOINT=https://your-s3-endpoint
OBJECT_STORAGE_PUBLIC_URL=https://your-public-bucket-base-url
OBJECT_STORAGE_ACCESS_KEY_ID=your-access-key
OBJECT_STORAGE_SECRET_ACCESS_KEY=your-secret-key
OBJECT_STORAGE_REGION=auto
OBJECT_STORAGE_FORCE_PATH_STYLE=true
```

**In exampleDB, password for teststudent, testtutor, and testadmin are 123456**
