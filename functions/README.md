# ElderCare Triage Backend

Python Firebase/Cloud Functions backend for the hackathon MVP.

## Entry Points

- `api(request)`: HTTP API router for `/api/v1/*` endpoints.
- `process_audio_upload(cloud_event)`: Cloud Storage finalize handler. It expects uploaded audio to include `senior_id` object metadata or a path like `triage_uploads/{senior_id}/{filename}`.

Both functions are configured for the Singapore region: `asia-southeast1`.

## HTTP Endpoints

All routes are served under the `api` Cloud Function. In production, use:

```text
https://asia-southeast1-checkin-c4d3a.cloudfunctions.net/api/api/v1/...
```

### `POST /api/v1/triage/ingest`

Creates a new `triage_messages` document with `status: "processing"`. Use this when the frontend has already uploaded audio and wants the backend to register the work item. The Storage trigger can also perform ingestion automatically for uploads shaped like `triage_uploads/{senior_id}/{filename}`.

Request:

```json
{
  "senior_id": "senior-1",
  "storage_path": "gs://checkin-c4d3a.firebasestorage.app/triage_uploads/senior-1/audio.ogg"
}
```

Response `202`:

```json
{
  "message_id": "auto-generated-id",
  "status": "processing"
}
```

### `POST /api/v1/triage/transcribe`

Downloads the uploaded audio from Storage, sends it to OpenAI transcription, and updates the message with `transcript`. This is mostly an internal/manual validation endpoint; the Storage trigger normally runs this as part of the full pipeline.

Request:

```json
{
  "message_id": "auto-generated-id"
}
```

Response `200`: the updated message document.

### `POST /api/v1/triage/analyze`

Reads the message transcript and the senior's `profile_context`, asks the GPT model to classify the message, updates Firestore, sets `status: "unread"`, and sends caregiver FCM notifications.

The backend now uses binary triage:

- `Emergency`
- `Not Emergency`

If model analysis fails, the transcript is empty, or the audio is too ambiguous to safely dismiss, the backend falls back to `Emergency`.

Request:

```json
{
  "message_id": "auto-generated-id"
}
```

Response `200`: the analyzed message, including `summary`, `priority`, `reasoning`, and `suggested_action`.

### `GET /api/v1/messages/feed`

Returns caregiver-visible messages for linked senior accounts. Results are sorted by `priority` first, with `Emergency` before `Not Emergency`, then by newest `created_at`.

Query parameters:

- `caregiver_id` required
- `status` optional: `processing`, `unread`, `acknowledged`, or `resolved`
- `limit` optional, defaults to `20`, capped at `100`

Example:

```text
GET /api/v1/messages/feed?caregiver_id=caregiver-1&status=unread&limit=20
```

Response `200`: an array of message objects.

### `PATCH /api/v1/messages/{message_id}/status`

Lets a caregiver mark a message as handled. Only caregiver-writable statuses are accepted: `acknowledged` and `resolved`.

Request:

```json
{
  "status": "acknowledged",
  "action_taken": "Called Mum back and confirmed she is okay."
}
```

Response `200`:

```json
{
  "success": true
}
```

### `POST /api/v1/users/link`

Links a caregiver account to a senior account using a senior pairing code. The implementation accepts either a configured pairing code resolved by the repository or, for simple setup/testing, a senior user id that belongs to a `senior` user.

Request:

```json
{
  "caregiver_id": "caregiver-1",
  "senior_pairing_code": "PAIR-123"
}
```

Response `200`:

```json
{
  "linked_senior_id": "senior-1"
}
```

### `PUT /api/v1/users/{senior_id}/context`

Updates the senior's routine/medical context. This context is sent to the GPT triage step so the classifier can interpret messages with more relevant background.

Request:

```json
{
  "routine_context": "Lives alone. Takes blood pressure medication at 8am. History of falls."
}
```

Response `200`:

```json
{
  "success": true
}
```

### `POST /api/v1/system/dead-letter`

Manual safety endpoint for forcing a message into the caregiver queue when processing fails. It marks the message `unread`, sets `priority: "Emergency"`, records the error, and sends a caregiver notification.

Request:

```json
{
  "message_id": "auto-generated-id",
  "error": "Transcription timed out"
}
```

Response `200`: the updated message document.

### CORS Preflight

All endpoints respond to `OPTIONS` with permissive CORS headers for the MVP frontend.

## Model Configuration

The backend keeps model IDs configurable by environment:

- `OPENAI_TEXT_MODEL`, default `gpt-5.5`
- `OPENAI_TRANSCRIPTION_MODEL`, default `whisper-1`

The project spec mentions `gpt-5.5-instant` and `whisper-large-v3-turbo`, but the official OpenAI docs found during implementation list `gpt-5.5` for GPT-5.5 and `whisper-1` for Whisper transcription. Set the environment variables above if your hackathon account has different aliases enabled.

## Local Tests

```bash
cd functions
python -m unittest discover -s tests
```

The tests use in-memory fakes for Firestore, Storage, OpenAI, and FCM, so they do not need credentials.

## Local Functions Framework

```bash
cd functions
pip install -r requirements.txt
functions-framework --target api --debug
```

Then call `http://localhost:8080/api/v1/...`.

## Firebase Deploy

```bash
firebase deploy --only functions
```

Before deploying, configure:

- Firebase Admin credentials or default Google Cloud credentials
- `OPENAI_API_KEY`
- `STORAGE_BUCKET` if Firebase cannot infer the default Storage bucket from `FIREBASE_CONFIG`
- Firestore `users` documents with `role`, `linked_accounts`, `profile_context`, and `fcm_tokens`
