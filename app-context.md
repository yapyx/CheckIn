# App Context: ElderCare Triage (Hackathon Project)

## 1. Vision & Purpose
**ElderCare Triage** is a voice-first communication bridge designed to alleviate "Missed Call Anxiety" for working caregivers. It solves the uncertainty of receiving a missed call from an aging parent during work hours by using AI to categorize the urgency of the communication before the caregiver even picks up the phone.

## 2. The Problem Statement
Working adult caregivers often experience panic or distraction when they miss a call from an elderly parent, fearing an emergency. In reality, many calls are routine (e.g., asking about dinner). This "uncertainty gap" leads to:
*   **Caregiver Burnout:** Constant high-cortisol states due to perceived emergencies.
*   **Workplace Distraction:** Inability to focus during meetings or deep work.
*   **Senior Isolation:** Elderly parents may stop calling to avoid "bothering" their busy children.

## 3. Core Value Proposition
The application transforms a "Missed Call" notification into an **Actionable Triage Report**.
*   **From:** "Missed Call from Mum"
*   **To:** "Routine: Mum wants to know if you are coming home for dinner. No urgent concern detected."

## 4. User Personas
### The Senior (The Caller)
*   **Profile:** Aging parent, likely living alone or with limited supervision. 
*   **Tech Literacy:** Low. Prefers voice over typing. May have limited vision or dexterity.
*   **Interaction:** Uses a "One-Button" interface to record a voice message.

### The Caregiver (The Receiver)
*   **Profile:** Busy working professional (e.g., Data Analyst, Manager) juggling career and family.
*   **Tech Literacy:** High. Needs quick, scannable information.
*   **Interaction:** Receives binary emergency/not-emergency notifications on a dashboard and takes one-tap actions.

## 5. Key Features & Logic
1.  **Voice-First Input:** Seniors speak naturally; the app handles the rest.
2.  **AI Transcription:** Powered by **OpenAI Whisper Large V3 Turbo** (optimized for SEA/Singlish accents).
3.  **Intelligent Triage:** Powered by **GPT-5.5 Instant** using RAG (Retrieval-Augmented Generation). It uses the senior's medical/routine context to decide if a message is an emergency.
4.  **Priority System:**
    *   **Emergency:** Potential emergency, immediate safety concern, medication danger, or unclear audio that cannot be safely dismissed.
    *   **Not Emergency:** Routine/social messages, logistics, groceries, dinner, chat, or clearly low-risk comfort requests.

## 6. Technical Design Philosophy
*   **Safety First:** The system defaults to "Emergency" if the AI confidence is low.
*   **Low Latency:** Every second counts. The backend is optimized for a <5s processing loop.
*   **Minimal Friction:** No complex menus for the senior. No manual typing required for the basic loop.

## 5. Key Features & Logic
1.  **Voice-First Input:** Seniors speak naturally; the app handles the rest.
2.  **AI Transcription:** Powered by **OpenAI Whisper Large V3 Turbo**.
3.  **Intelligent Triage:** Powered by **GPT-5.5 Instant**.
4.  **Instant Notifications:** The moment the senior finishes their message, the caregiver receives a push notification on their phone.
    *   **Critical Alerts:** Emergency messages bypass "Do Not Disturb" or "Silent" modes to ensure the caregiver is alerted to potential emergencies immediately.
    *   **Rich Summaries:** Notifications include the AI-generated summary so the caregiver doesn't have to open the app to understand the context.
