# TutorEverywhere
Mobile tutoring platform project for 01418342 Mobile Application Design and Development.

## Stack
- Frontend: Flutter (Dart)
- Backend: Express.js (TypeScript)
- Database: PostgreSQL
- Media storage: S3-compatible object storage (Railway bucket / compatible provider)

## Branch Strategy
- `main`: full project (frontend + backend)
- `app-release`: frontend-only branch (`tutoreverywhere_frontend`)
- `backend-cloud`: backend-only branch (`tutoreverywhere_backend`)

## Project Structure
- `tutoreverywhere_frontend/` Flutter app
- `tutoreverywhere_backend/` Express API
- `exampleDB/` SQL/sample data

## Local Setup

### 1) Backend
From project root:

```bash
cd tutoreverywhere_backend
npm install
npm run dev
```

Backend runs on `http://localhost:3000` by default.

### 2) Frontend
From `tutoreverywhere_frontend`:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Use your Railway URL for real-device/cloud testing:

```bash
flutter run --dart-define=API_BASE_URL=https://your-backend-domain.example.com
```

## Docker (Backend)
From repo root:

```bash
docker build -t tutor-everywhere-backend ./tutoreverywhere_backend
docker run --rm -p 3000:3000 --env-file ./.env --name tutor-everywhere-backend tutor-everywhere-backend
```

## Android Maps API Key
Add this to `tutoreverywhere_frontend/android/local.properties` (ignored by git):

```properties
MAPS_API_KEY=YOUR_ANDROID_MAPS_API_KEY
```

## Backend Environment Variables
Use either `PG_*` or `DB_*` names for DB config.

```env
AUTH_SECRET_KEY=MobileAppAuthKey
PGHOST=localhost
PGPORT=5432
PGDATABASE=tutorApp
PGUSER=postgres
PGPASSWORD=your_password
PGSSL=disable

# S3-compatible object storage
OBJECT_STORAGE_BUCKET=your-bucket-name
OBJECT_STORAGE_ENDPOINT=https://your-s3-endpoint
OBJECT_STORAGE_PUBLIC_URL=https://your-public-bucket-base-url
OBJECT_STORAGE_ACCESS_KEY_ID=your-access-key
OBJECT_STORAGE_SECRET_ACCESS_KEY=your-secret-key
OBJECT_STORAGE_REGION=auto
OBJECT_STORAGE_FORCE_PATH_STYLE=true
```

## API + Function Map (Request/Send to Backend)
All Retrofit endpoint declarations are in:
- `tutoreverywhere_frontend/lib/service/api.dart`
- Generated client implementation: `tutoreverywhere_frontend/lib/service/api.g.dart`

### Auth + Registration
- `main.dart` -> `login()` calls `client.testLogin()` -> `POST /auth`
- `pages/registration/student.dart` -> `_register()` calls `registerStudent()` -> `POST /register/student`
- `pages/registration/tutor.dart` -> `_register()` calls `registerTutor()` -> `POST /register/tutor`

### Profile + Tutor/Student Data
- `pages/tutor/profile.dart` calls:
  - `getTutorDataById()` -> `GET /tutors/profile/{userId}`
  - `setTutorBio()` -> `POST /tutors/bio`
  - `setTutorLocation()` -> `PATCH /tutors/location`
  - `uploadTutorProfilePicture()` -> `PATCH /tutors/profile-picture`
  - `uploadTutorPromptPayPicture()` -> `PATCH /tutors/promptpay-picture`
  - `uploadTutorVerificationPicture()` -> `PATCH /tutors/verification-picture`
- `pages/student/profile.dart` calls:
  - `getStudentsDataById()` -> `GET /students/profile/{userId}`
  - `setStudentBio()` -> `POST /students/bio`
  - `uploadStudentProfilePicture()` -> `PATCH /students/profile-picture`

### Subjects + Reviews + Schedule
- `pages/tutor/subjects_tab.dart` calls:
  - `getTutorSubjectsByTutorId()` -> `GET /tutors/subjects/{userId}`
  - `addTutorSubject()` -> `POST /tutors/subjects/`
  - `updateTutorSubjectPrice()` -> `PATCH /tutors/subjects/`
  - `deleteTutorSubject()` -> `DELETE /tutors/subjects/`
- `pages/tutor/reviews_tab.dart` calls:
  - `getReviewsByRevieweeId()` -> `GET /reviews/{tutorId}`
  - `addReview()` -> `POST /reviews`
- Schedule pages call:
  - `getAppointmentByTutorId()` -> `GET /tutors/appointments/{userId}`
  - `getAppointmentByStudentId()` -> `GET /students/appointments/{userId}`
  - Supports query filters: `year`, `month`, `day`

### Chat + Request Money
Chat is handled with direct Dio calls in `pages/all/chat.dart` and `pages/tutor/requestMoney.dart`:
- `GET /chat/conversations`
- `GET /chat/messages/:otherUserId`
- `POST /chat/messages/:otherUserId` (text/location)
- `POST /chat/messages/:otherUserId/image` (multipart image)
- `POST /chat/messages/:otherUserId/request-money`
- `POST /chat/accept` (via `acceptPromptPay()` in `api.dart`)

## How Request/Send Flow Works
1. UI action (button submit/send) triggers a page method (example: `_register`, `_sendTextMessage`).
2. The page method builds payload data (`@Body`, `@Field`, or multipart file).
3. `Authorization` token is included for protected routes.
4. Backend validates payload, stores in DB, and returns JSON response.
5. UI updates local state and renders success/error messages.

## Build Release APK
From `tutoreverywhere_frontend`:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-backend-domain.example.com
```

Output:
- `tutoreverywhere_frontend/build/app/outputs/flutter-apk/app-release.apk`

## Notes
- Keep `.env` and `android/local.properties` out of git.
- If database or bucket credentials rotate, update Railway variables and redeploy.
- Example DB test users (`teststudent`, `testtutor`, `testadmin`) use password: `123456`.
