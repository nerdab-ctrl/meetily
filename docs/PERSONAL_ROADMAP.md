# Neeraj Notes — Upgrade Roadmap

## Next upgrade: auto-prompt recording for meetings

**Goal:** when a scheduled or ad-hoc call starts (Google Meet in Chrome, Zoom, Teams),
the app shows a "Meeting detected — Record?" prompt; one click starts recording + transcription.
Stop automatically when the call ends.

### Approach (decided)

| # | Trigger | How | Covers |
|---|---------|-----|--------|
| 1 | **Call detection (primary)** | Poll every ~5s: is the mic in use (CoreAudio `kAudioDevicePropertyDeviceIsRunningSomewhere`) **and** is a meeting app active (Zoom `CptHost` process / Teams / Chrome window titled `Meet - …`)? | Every call, scheduled or not |
| 2 | **Calendar (secondary)** | Read macOS Calendar via EventKit (Google Calendar synced into Calendar.app; no OAuth app needed). 1 min before an event with a Meet/Zoom/Teams link → notification; pre-fill meeting name from event title + attendees | Scheduled meetings; better titles |
| 3 | Chrome extension | Rejected for v1 — more build effort, Meet-only, duplicates #1 | — |

- **Prompt, not silent auto-record** by default (consent of other participants). Setting: "Auto-start for meetings on my calendar".
- **Auto-stop:** mic released + meeting app closed / Meet tab gone for >30s → stop + generate summary with `leadership_scr`.

### Building blocks already in code
- Tray "start recording" flow: `frontend/src-tauri/src/tray.rs` sets `autoStartRecording` → handled in `frontend/src/hooks/useRecordingStart.ts`.
- Native notifications: `frontend/src-tauri/src/notifications/`.
- Recording start/stop commands: `frontend/src-tauri/src/audio/recording_commands.rs`.

### New pieces needed
- `src-tauri/src/meeting_detect/` (macOS mic-in-use + process/window check), background task started in `lib.rs`.
- `src-tauri/src/calendar/` (EventKit via objc2 / swift bridge; needs `NSCalendarsFullAccessUsageDescription` in `Info.plist`).
- Actionable notification ("Record" / "Ignore") → triggers existing auto-start path.
- Settings toggles: detection on/off, auto-start for calendar meetings, which apps to watch.

### Open items
- macOS permissions: Calendar access, Accessibility (window titles) — first-run prompts.
- Windows support later (WASAPI session enumeration for mic-in-use).
