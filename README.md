# CheckIn - Voice-First Elder Care Triage App

CheckIn is a voice-first communication bridge that turns a senior's voice message into an **AI-powered caregiver triage report**. It solves "Missed Call Anxiety" by intelligently categorizing message urgency before the caregiver even picks up the phone.

**Status:** Hackathon MVP | **Language:** Dart (Flutter) + Python (Firebase)

---

## 🎯 Problem Statement

Working adult caregivers experience panic and workplace distraction when receiving missed calls from elderly parents, fearing emergencies. In reality, many calls are routine (e.g., asking about dinner). CheckIn bridges this uncertainty gap by:

- Automatically transcribing the senior's voice message
- Analyzing it with AI triage
- Sending a high-priority notification with a actionable summary

**From:** "Missed Call from Mum"  
**To:** "Routine: Mum wants to know if you are coming home for dinner. No urgent concern detected."

---

## 📋 Project Structure

```text
CheckIn/
  ├── flutter_app/              # Flutter frontend (Android/iOS)
  │   ├── lib/
  │   │   ├── screens/          # UI screens (Senior recorder, Caregiver dashboard)
  │   │   ├── services/         # Firebase integration, API calls
  │   │   ├── models/           # Data models
  │   │   └── widgets/          # Reusable UI components
  │   ├── android/              # Android-specific config (Gradle)
  │   └── pubspec.yaml          # Flutter dependencies
  │
  ├── functions/                # Firebase Python backend
  │   ├── backend/
  │   │   ├── ai.py             # OpenAI integration (Whisper + GPT)
  │   │   ├── api.py            # HTTP API router
  │   │   ├── auth.py           # Password hashing & auth
  │   │   ├── service.py        # Core triage business logic
  │   │   ├── repository.py     # Firestore data layer
  │   │   ├── storage.py        # Firebase Storage gateway
  │   │   ├── notifications.py  # FCM push notifications
  │   │   └── models.py         # Data schemas
  │   ├── tests/                # Unit tests
  │   ├── main.py               # Cloud Function entrypoints
  │   └── requirements.txt      # Python dependencies
  │
  ├── app-context.md            # Product vision & user personas
  ├── backend-instructions.md   # Backend architecture details
  └── firebase.json             # Firebase config
```

---

## 🏗️ Backend Architecture

### Tech Stack
- **Infrastructure:** Firebase (Firestore, Cloud Storage, Cloud Messaging)
- **Compute:** Google Cloud Functions (Python 3.11+, region: `asia-southeast1`)
- **AI Models:**
  - **STT:** OpenAI Whisper Large V3 Turbo (with Singlish context injection)
  - **Triage:** OpenAI GPT-5.5 Instant (RAG-based inference with senior's medical context)

### Core Processing Pipeline

```
1. Audio Upload
   ↓ (Cloud Storage finalize trigger)
   ↓
2. Speech-to-Text (Whisper)
   → Output: Transcript
   ↓
3. Context Retrieval (Firestore)
   → Fetch: Senior's medical profile & history
   ↓
4. Triage Inference (GPT-5.5 Instant)
   → Input: Transcript + Profile Context (RAG)
   → Output: { priority, summary, reasoning, suggested_action }
   ↓
5. Safety Fallback
   → If AI confidence low or API timeout → Hardcode EMERGENCY
   ↓
6. State Update & Notification
   → Write result to Firestore
   → Send high-priority FCM notification to caregiver
```

### Data Schema (Firestore)

**`users` Collection**
```json
{
  "uid": "senior-mary",
  "role": "senior" | "caregiver",
  "display_name": "Mary Tan",
  "profile_context": "Lives alone. Takes blood pressure medication at 8am.",
  "linked_accounts": ["caregiver-john-uid"],
  "fcm_tokens": ["token1", "token2"],
  "pairing_code": "CI-123ABC"
}
```

**`triage_messages` Collection**
```json
{
  "message_id": "auto-generated",
  "senior_id": "senior-mary",
  "audio_url": "gs://bucket/triage_uploads/senior-mary/audio.webm",
  "transcript": "Can you come home early today?",
  "summary": "Senior asking about dinner plans",
  "priority": "Emergency" | "Not Emergency",
  "suggested_action": "Call back to confirm plans",
  "status": "processing" | "unread" | "acknowledged" | "resolved",
  "created_at": 1715339400,
  "updated_at": 1715339410
}
```

### API Endpoints

**Authentication**
- `POST /api/v1/auth/signup` — Create senior/caregiver account
- `POST /api/v1/auth/login` — Authenticate and receive pairing code

**Triage Processing**
- `POST /api/v1/triage/ingest` — Register new audio for processing
- `POST /api/v1/triage/transcribe` — (Internal) Call Whisper API
- `POST /api/v1/triage/analyze` — (Internal) Call GPT-5.5 for triage

**Caregiver Dashboard**
- `GET /api/v1/messages/feed` — Fetch paginated message history
- `PATCH /api/v1/messages/{message_id}/status` — Update message status (acknowledged/resolved)

**Account Linking**
- `POST /api/v1/users/link` — Link senior to caregiver via pairing code

See `functions/README.md` for detailed endpoint examples.

### Safety Guarantees
- **Emergency Default:** If AI confidence is low or API fails, the system defaults to "Emergency" status
- **Low Latency:** <5 second processing target from audio upload to caregiver notification
- **Context-Aware:** Uses senior's medical profile (RAG) to make safe triage decisions

---

## 📱 Frontend Architecture

### Tech Stack
- **Framework:** Flutter (Dart)
- **State Management:** Provider + local models
- **Backend Integration:** Firebase SDK + REST API calls
- **UI Library:** Material Design 3

### User Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          CHECKIN APP                             │
└─────────────────────────────────────────────────────────────────┘

                    ┌──────────────────────┐
                    │  ONBOARDING FLOW     │
                    └──────────────────────┘
                             │
                             ├─ Sign Up (Senior or Caregiver)
                             │   └─ Choose Role
                             │   └─ Set Display Name
                             │   └─ Set Profile Context (Seniors)
                             │   └─ Create Password
                             │
                             ├─ Account Linking
                             │   └─ Senior: Share Pairing Code
                             │   └─ Caregiver: Enter Pairing Code
                             │
                             └─► Home Screen
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
                    ↓              ↓              ↓
         ┌─────────────────┐  ┌──────────────┐  ┌───────────────┐
         │ SENIOR HOME     │  │ CAREGIVER    │  │  FAMILY LINK  │
         │                 │  │  DASHBOARD   │  │  MANAGEMENT   │
         │ • One-Button    │  │              │  │               │
         │   Record Voice  │  │ • View msgs  │  │ • Link/unlink │
         │ • Recording UI  │  │   by priority│  │   seniors     │
         │ • Upload audio  │  │ • Mark read/ │  │               │
         │ • Confirmation  │  │   resolved   │  │               │
         │   screen        │  │ • Call senior│  │               │
         │                 │  │ • View full  │  │               │
         │                 │  │   transcript │  │               │
         │                 │  │   & context  │  │               │
         └─────────────────┘  └──────────────┘  └───────────────┘
                    │              │              │
                    │     ┌─────────┘              │
                    │     │                        │
                    └─────┼────────────────────────┘
                          │
                    ┌─────▼──────────┐
                    │  MESSAGE DETAIL│
                    │   SCREEN       │
                    │                │
                    │ • Full text    │
                    │ • Play audio   │
                    │ • Priority     │
                    │ • Actions      │
                    └────────────────┘
```

### Key Screens
1. **Onboarding** — Sign up & account linking flow
2. **Senior Home Screen** — One-button voice recorder
3. **Recorder Screen** — Real-time voice recording with countdown
4. **Caregiver Dashboard** — Inbox sorted by priority (Emergency first)
5. **Message Detail** — Full transcript, audio playback, action buttons
6. **Family Screen** — Manage linked accounts

### Firebase Integration
- Firebase Auth for user authentication
- Firestore listeners for real-time message updates
- Firebase Storage for audio uploads
- Firebase Cloud Messaging (FCM) for push notifications
- Firebase Configuration (API keys, project IDs) injected via `--dart-define`

---

## 🚀 Setup & Deployment

### Prerequisites
- **Node.js** 18+ (for Firebase CLI)
- **Python** 3.11+ (for backend)
- **Flutter** 3.0+ (for mobile app)
- **Java 11+** (for Android build)
- **Firebase Account** with a project created
- **OpenAI API Key** with Whisper & GPT-5.5 access

### Local Setup

#### 1. Clone & Install
```bash
git clone <repo-url>
cd CheckIn

# Backend setup
cd functions
pip install -r requirements.txt
cd ..

# Frontend setup
cd flutter_app
flutter pub get
cd ..
```

#### 2. Configure Environment

**Backend (`functions/.env`)**
```bash
OPENAI_API_KEY=sk-...your-key...
FIREBASE_PROJECT_ID=checkin-c4d3a
GOOGLE_CLOUD_PROJECT=checkin-c4d3a
```

**Firebase Emulator** (optional, for local testing)
```bash
npm install -g firebase-tools
firebase emulators:start
```

#### 3. Run Backend Locally

```bash
cd functions

# Run tests
python -m unittest discover -s tests

# Run in emulator (with firebase-tools)
firebase emulators:start
```

#### 4. Run Frontend

```bash
cd flutter_app

# List connected devices
flutter devices

# Run on emulator/device with Firebase config
flutter run \
  -d emulator-5554 \
  --dart-define=FIREBASE_API_KEY=AIzaSyDzPDDpUmjx9AFPwc766N0sgfT5RWqH3qg \
  --dart-define=FIREBASE_APP_ID=1:345712023174:android:d48b62ae06a0409be16307 \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=345712023174 \
  --dart-define=FIREBASE_PROJECT_ID=checkin-c4d3a \
  --dart-define=FIREBASE_STORAGE_BUCKET=checkin-c4d3a.firebasestorage.app
```

### Deploy to Firebase

#### Backend (Cloud Functions)
```bash
cd functions
firebase deploy --only functions --region asia-southeast1
```

#### Frontend (Android APK)
```bash
cd flutter_app

# Build APK (release mode)
flutter build apk --release \
  --dart-define=FIREBASE_API_KEY=AIzaSyDzPDDpUmjx9AFPwc766N0sgfT5RWqH3qg \
  --dart-define=FIREBASE_APP_ID=1:345712023174:android:d48b62ae06a0409be16307 \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=345712023174 \
  --dart-define=FIREBASE_PROJECT_ID=checkin-c4d3a \
  --dart-define=FIREBASE_STORAGE_BUCKET=checkin-c4d3a.firebasestorage.app

# APK location: flutter_app/build/app/outputs/flutter-apk/app-release.apk
```

**Download APK:**  
📱 **[Download CheckIn APK](https://placeholder-apk-download-url.com)** (Update with actual hosting URL)

---

## 📚 Additional Resources

- **Product Context:** See [app-context.md](app-context.md) for vision, user personas, and feature details
- **Backend Details:** See [backend-instructions.md](backend-instructions.md) for system architecture & API specs
- **Backend API Docs:** See [functions/README.md](functions/README.md) for detailed endpoint examples
- **Firebase Config:** See [firebase.json](firebase.json) for function regions and emulator settings

---

## 🔒 Security & Best Practices

- **Never commit secrets** — Use `.env` files (ignored by Git)
- **Emergency Default** — Always triage as "Emergency" if AI is uncertain
- **Low Latency** — Target <5 second processing for critical safety
- **FCM Priority** — Emergency notifications bypass Do Not Disturb modes
- **Context Safety** — Profile context stored encrypted in Firestore

---

## 🧪 Testing

```bash
# Backend unit tests
cd functions
python -m unittest discover -s tests

# Frontend widget tests
cd flutter_app
flutter test
```

---

## 📝 License

Hackathon Project (OGP TheGoodHack)
