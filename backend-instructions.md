# Backend Implementation Instructions: AI Elder-Care Triage App (Hackathon MVP)

## 1. System Architecture Overview
This backend operates on a "Push-to-Compute", event-driven serverless architecture utilizing Firebase and Python. The goal is to achieve a sub-5-second triage loop from audio ingestion to caregiver notification.

**Tech Stack:**
*   **Infrastructure:** Firebase (Cloud Storage, Firestore, Cloud Messaging).
*   **Compute:** Google Cloud Functions (Python runtime).
*   **AI Providers:** OpenAI (Whisper Large V3 Turbo for STT, GPT-5.5 Instant for Inference).

**Core Workflow:**
1. Frontend uploads `.webm`/`.m4a` to Firebase Cloud Storage.
2. Cloud Storage event triggers a Python Cloud Function.
3. Function orchestrates STT (Whisper) and Intent Inference (GPT-5.5 Instant).
4. Function writes results to Firestore.
5. Firestore `onCreate`/`onUpdate` triggers (or direct push) send high-priority FCM notifications to the Caregiver.

---

## 2. Data Schema (Firestore NoSQL)

Implement the following collections and document structures:

### `users` Collection
*   **Document ID:** `uid` (String, Primary Key)
*   `role`: String (Enum: "senior" | "caregiver")
*   `linked_accounts`: Array of Strings (UIDs)
*   `profile_context`: String (Critical for RAG-based triage, e.g., "Lives alone, history of hypertension.")
*   `fcm_tokens`: Array of Strings (For push notifications)

### `triage_messages` Collection
*   **Document ID:** `message_id` (String, Auto-generated)
*   `senior_id`: String (Reference to users collection)
*   `audio_url`: String (Firebase Storage gs:// path or download URL)
*   `transcript`: String (Output from Whisper)
*   `summary`: String (Output from GPT-5.5)
*   `priority`: String (Enum: "Emergency" | "Not Emergency")
*   `suggested_action`: String (Output from GPT-5.5)
*   `status`: String (Enum: "processing" | "unread" | "acknowledged" | "resolved")
*   `created_at`: ServerTimestamp
*   `updated_at`: ServerTimestamp

---

## 3. The AI Processing Pipeline Logic

The main Cloud Function must orchestrate the following logic sequentially:

1. **Audio Extraction:** Retrieve the audio file from Firebase Storage.
2. **Speech-to-Text (STT):** Call OpenAI API (`whisper-large-v3-turbo`). 
   * *Requirement:* Inject a localized prompt (e.g., "Singlish context: Uncle, Auntie, Makan, Alamak") to bias transcription accuracy.
3. **Context Retrieval:** Fetch the `profile_context` from the `users` collection for the specific `senior_id`.
4. **Triage Inference:** Call OpenAI API (`gpt-5.5-instant`).
   * *System Prompt Rules:* Act as a medical dispatcher. Use the transcript and context to classify priority.
   * *Priority Definitions:* 
     * Emergency: Acute physical pain, falls, chest pain, confusion, medication danger, home safety danger, or unclear/ambiguous audio that cannot be safely dismissed.
     * Not Emergency: Social check-ins, routine questions, meals, groceries, or clearly low-risk comfort requests.
   * *Output Format:* Strictly enforce JSON response: `{ "summary": str, "priority": str, "reasoning": str, "suggested_action": str }`
5. **Safety Fallback:** If LLM confidence is low or API times out, hardcode fallback priority to "Emergency".
6. **State Update:** Write the final JSON payload back to the `triage_messages` document and update status to `unread`.

---

## 4. API Endpoints to Implement

Implement these exact signatures. For the Hackathon MVP, these can be structured as HTTP Cloud Functions (REST) or callable Firebase Functions.

### A. Ingestion & AI Pipeline APIs

*   **`POST /api/v1/triage/ingest`**
    *   **Trigger:** Storage trigger preferred, or HTTP called by frontend after upload.
    *   **Payload:** `{ "senior_id": "string", "storage_path": "string", "timestamp": "ISO8601" }`
    *   **Action:** Creates `triage_messages` doc with status `processing`.
    *   **Response:** `202 Accepted` `{ "message_id": "string", "status": "processing" }`

*   **`POST /api/v1/triage/transcribe`** (Internal)
    *   **Action:** Calls Whisper Large V3 Turbo. Updates Firestore doc with `transcript`.

*   **`POST /api/v1/triage/analyze`** (Internal)
    *   **Action:** Calls GPT-5.5 Instant with RAG context. Updates Firestore doc with `priority`, `summary`, and sets status to `unread`. Triggers FCM notification.

### B. Caregiver Dashboard APIs

*   **`GET /api/v1/messages/feed`**
    *   **Description:** Fetches paginated history for the dashboard.
    *   **Query Params:** `?caregiver_id=string&status=unread&limit=20`
    *   **Response:** `200 OK` Array of message objects, sorted by `priority` (Emergency first), then `created_at` (desc).

*   **`PATCH /api/v1/messages/{message_id}/status`**
    *   **Description:** Updates message status when caregiver taps an action.
    *   **Payload:** `{ "status": "acknowledged" | "resolved", "action_taken": "string" }`
    *   **Response:** `200 OK` `{ "success": true }`

### C. User & Context Management APIs

*   **`POST /api/v1/users/link`**
    *   **Description:** Links senior to caregiver.
    *   **Payload:** `{ "caregiver_id": "string", "senior_pairing_code": "string" }`
    *   **Action:** Updates `linked_accounts` arrays in both user documents.
    *   **Response:** `200 OK` `{ "linked_senior_id": "string" }`

*   **`PUT /api/v1/users/{senior_id}/context`**
    *   **Description:** Updates the RAG context string for the AI.
    *   **Payload:** `{ "routine_context": "string" }`
    *   **Response:** `200 OK` `{ "success": true }`

### D. Safety & Fallback APIs

*   **`POST /api/v1/system/dead-letter`**
    *   **Description:** Exception handler endpoint.
    *   **Action:** Triggered on try/catch failure of any AI API. Immediately updates message status to `unread`, priority to `Emergency`, and pushes raw audio notification to caregiver.


### E. Notification Pipeline (FCM)
The backend must trigger a push notification immediately upon the completion of the `analyze` task.

*   **Priority Mapping:** 
    *   **Emergency:** Must use `priority: high` and `android_channel_id` with "Emergency" importance to bypass system silences (Critical Alerts).
    *   **Not Emergency:** Standard high-priority delivery.
*   **Payload Structure:**
    ```json
    {
      "to": "caregiver_fcm_token",
      "notification": {
        "title": "Triage [EMERGENCY/NOT EMERGENCY]: Mum",
        "body": "[Summary of the voice message]"
      },
      "data": {
        "message_id": "string",
        "priority": "string",
        "click_action": "FLUTTER_NOTIFICATION_CLICK"
      }
    }
