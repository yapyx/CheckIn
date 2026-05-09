# CheckIn

CheckIn is an elder-care triage app that turns a senior's voice message into a caregiver-ready triage report.

The repository is structured as a small monorepo:

```text
CheckIn/
  functions/              # Firebase Python backend
  frontend/               # Frontend app placeholder
  app-context.md          # Product context and user flow
  backend-instructions.md # Backend implementation notes
  firebase.json           # Firebase functions/emulator config
```

## Backend

The backend lives in `functions/` and deploys two Firebase Functions in `asia-southeast1`:

- `api`: HTTP API for ingestion, analysis, feeds, status updates, account linking, and dead-letter handling.
- `process_audio_upload`: Cloud Storage finalize trigger for end-to-end audio processing.

See `functions/README.md` for endpoint details.

Run backend tests:

```bash
cd functions
python -m unittest discover -s tests
```

Deploy backend:

```bash
firebase deploy --only functions
```

## Frontend

The frontend should live in `frontend/`. Keep framework-specific files inside that folder so the backend and frontend can evolve independently.

Suggested setup for a Vite app:

```bash
npm create vite@latest frontend
cd frontend
npm install
npm run dev
```

When the frontend is ready for Firebase Hosting, configure `firebase.json` to serve the frontend build output, usually `frontend/dist`.

## Environment

Never commit real secrets. Use example files as templates:

- `functions/.env.example`
- `frontend/.env.example`

Local secrets should stay in `.env` files, which are ignored by git.

## Firebase

Current project config is stored in `.firebaserc`. The backend expects:

- Firestore users with `role`, `linked_accounts`, `profile_context`, and `fcm_tokens`.
- Cloud Storage uploads shaped like `triage_uploads/{senior_id}/{filename}` or object metadata containing `senior_id`.
- OpenAI environment variables configured for deployed functions.
