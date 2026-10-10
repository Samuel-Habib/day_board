# Stupid DashBoard — System Documentation & Features Guide

**Stupid DashBoard** is an ambient Apple TV dashboard designed for tvOS 26.2. It unifies daily habit execution, health timing, weather awareness, a late-night retro alert takeover, and a dedicated Work & Focus timekeeping engine with a visual day calendar timeline.

---

## 1. System Overview & Design Philosophy

* **Target Platform:** Apple TV / tvOS 26.2 (4K & 1080p displays).
* **Control Paradigm:** Siri Remote (Clickpad navigation, Menu/Back dismissal, Play/Pause).
* **Ambient Display (Zero Interruption):** The system disables the Apple TV screensaver and sleep timer (`UIApplication.shared.isIdleTimerDisabled = true`) so the dashboard remains active continuously.
* **Quiet Luxury UI:** Background synchronization with the timekeeping API is completely silent and automatic. All technical URLs, cloud badges, and server statuses are hidden from the user interface to maintain a calm, distraction-free environment.
* **Local-First Reliability:** All tasks, habits, and work sessions are persisted locally in the application's sandbox (`Documents` directory) as JSON. If the network is unavailable, the dashboard remains 100% functional and synchronizes whenever a connection is established.

```
┌────────────────────────────────────────────────────────────────────────┐
│                          STUPID DASHBOARD                              │
├───────────────────────────────────┬────────────────────────────────────┤
│           LEFT COLUMN             │            RIGHT COLUMN            │
│  - Time & Date (Giant Monospace)  │  - Weather (Open-Meteo + UV Index) │
│  - Omeprazole / Meds Countdown    │  - Today's Tasks Checklist         │
│  - Habits Grid (Morning / Night)  │  - Work & Focus Widget             │
│    (Sun / Moon Icon Switcher)     │  - Bottom Action Toolbar           │
└───────────────────────────────────┴────────────────────────────────────┘
                                   │
              ┌────────────────────┴────────────────────┐
              ▼                                         ▼
   [ 10 PM Night Takeover ]                   [ Work & Focus Hub ]
   - Giant Retro Typography                   - Timer View (Left)
   - Red Background + Scanlines               - Day Calendar Timeline (Right)
   - Dismiss with any remote button           - Hourly Work Blocks & "Now" Line
```

---

## 2. Core Features Breakdown

### 2.1. Screensaver Resistance
To prevent Apple TV's Aerial screensaver from activating or putting the TV to sleep:
* `UIApplication.shared.isIdleTimerDisabled = true` is set:
  1. At application launch in `Stupid_DashBoardApp.init()`.
  2. In `AppState.init()`.
  3. In `ContentView.onAppear`.
  4. Whenever the app returns to the foreground in `ContentView.onChange(of: scenePhase)`.
  5. In `WorkFocusView.onAppear`.

---

### 2.2. Main Ambient Dashboard (`ContentView.swift`)

#### Top Header: Clock, Date & Weather
* **Live Clock:** Large bold time display formatted as `h:mm a`, updating every second without lag via a 1.0s background timer.
* **Full Date:** Formatted as `EEEE, MMMM d` (e.g. *Monday, September 7*).
* **Live Weather Engine (`fetchWeather`):**
  * Queries the Open-Meteo forecast API using device coordinates (via `LocationManager`) or New York fallback.
  * Displays current condition emoji, descriptive weather summary, precipitation probability (%), and current rain status.
  * Computes the daily peak **UV Index** with color-coded risk levels:
    * `0.0 – 2.9`: Green (*Low*)
    * `3.0 – 5.9`: Yellow (*Moderate*)
    * `6.0 – 7.9`: Orange (*High*)
    * `8.0 – 10.9`: Red (*Very High*)
    * `11.0+`: Purple (*Extreme*)
  * Refreshes automatically every 15 minutes.

#### Omeprazole / Meds Timing & Blurred Checklist Modal (`MedsChecklistView.swift`)
* **Focused Checklist Modal:** Clicking on any "Meds" card (Morning or Night) activates an ambient backdrop blur (`.blur(radius: 24)`) and dark overlay (`Color.black.opacity(0.68)`), bringing an interactive medication checklist into the crisp foreground.
* **Per-Period Medication Tracking:** Users can view, check off, add (`+ Add Medication`), or delete medications for Morning or Night routines.
* **Automatic Omeprazole Timer Integration:** Checking off Omeprazole in the checklist triggers the 30-minute eating wait-timer banner on the dashboard.
* **Smart Habit Synchronization:** Completing all medications for the selected period automatically marks the parent "Meds" card as done and saves the completion milestone.
* **Apple TV Remote Navigation:** Full Siri Remote clickpad focus, Play/Pause quick toggling, and instant dismissal with the Back/Menu button (`.onExitCommand`).
* **Wait Phase (0 – 30 Minutes):**
  * Displays a live countdown (`MM:SS`) until food can be safely eaten.
  * Shows exact "Eat after (30m)" timestamp.
* **Eating Window (30 – 60 Minutes):**
  * Turns green with icon `fork.knife` indicating the optimal eating window is open.
  * Shows remaining minutes before the window closes.
* **Dismissible:** Users can tap "Dismiss" or uncheck the task to reset.

#### Guided Mobility & Stretching Protocol (`StretchingRoutineView.swift`, `StretchingExerciseIllustrationView.swift`)
* **Dedicated Stretching Engine:** Follows the full-screen guided protocol design of Foot Rehab, featuring:
  1. **Low Lunge with Hands Inside** (Lizard / Runner's Lunge) — Hip flexors & psoas lengthening.
  2. **Wall Figure-4 Stretch** (Wall Piriformis Stretch) — Supine wall-supported glute and piriformis decompression.
  3. **Puppy Pose** (Uttana Shishosana) — Vertical thigh alignment, thoracic spine extension, and shoulder opening.
  4. **Seated Side Bend Stretch** (Parsva Sukhasana) — Grounded sit bones with lateral arc opening obliques and lats.
* **Static Vector Graphic Illustrations:** Clean, high-fidelity SwiftUI anatomical vector illustrations drawn with dark limbs, joint nodes, ground/wall surfaces, glowing cyan/teal target stretch bands, alignment tags, and subtle ambient breathing glow.
* **Timer & Set Progression:** Dedicated set tracking (`SET 1 OF 2`), countdown clock with visual progress bar, Next Set, and Skip actions.
* **Automatic Habit Synchronization:** Completing the protocol marks the "Stretch" morning card as completed on the dashboard.

#### Habit Cards (Morning vs. Night)
* **Header Controls:** Clean Sun (`sun.max.fill`) and Moon (`moon.stars.fill`) icon toggle buttons. All distracting text labels (*MORNING HABITS*, *Start Routine*, *Take Meds*) have been removed for minimal aesthetics.
* **Adaptive Grid:** Renders tasks in a 4-column tvOS card grid with specialized badge indicators for `ROUTINE` (Foot), `STRETCH` (Mobility), and `MEDS`.
* **Interactive Toggling:**
  * Unchecked: Bold title, subtle circle border or routine badge.
  * Checked: Dimmed card opacity, green checkmark icon, and recorded habit duration tag.
* **Daily Reset:** Daily reset logic runs every minute (`checkDayChange`). At midnight, habit checkmarks and medications automatically reset for the new day.

#### Today's Tasks
* Day-specific tasks (e.g., errands, meetings, reminders).
* Tasks older than today are automatically cleaned up.
* Tap `[+ Add Task]` to create a new task via an on-screen dialog.

---

### 2.3. Dedicated Work & Focus Screen (`WorkFocusView.swift`)

When the user starts a sprint or taps **`Work & Focus`**, the app transitions into a dedicated full-screen work station.

```
┌────────────────────────────────────────────────────────────────────────┐
│  [← Dashboard]   WORK & FOCUS                   Monday, Sep 7  1:45 PM │
├───────────────────────────────────┬────────────────────────────────────┤
│       LEFT: FOCUS TIMER           │     RIGHT: DAY CALENDAR TIMELINE   │
│                                   │                                    │
│  ● ACTIVE SPRINT                  │  7 AM ───────────────────────────  │
│  DEEP WORK                        │  8 AM ───────────────────────────  │
│                                   │  9 AM ┌─────────────────────────┐  │
│          00:42:15                 │       │ Morning Sprint (1h 15m) │  │
│                                   │ 10 AM └─────────────────────────┘  │
│  [ ⏹ Stop & Save Sprint ]         │ 11 AM ───────────────────────────  │
│                                   │ 12 PM ───────────────────────────  │
│  Preset Chips:                    │  1 PM ┌─────────────────────────┐  │
│  [Deep Work] [Coding] [Writing]   │───────● NOW (1:45 PM)           │  │
│                                   │       │ ● Active Sprint (42m)   │  │
│  ── Today's Stats ──────────────  │  2 PM └─────────────────────────┘  │
│  Total: 1h 57m  •  2 Sprints      │  ...                               │
│                                   │ 11 PM ───────────────────────────  │
└───────────────────────────────────┴────────────────────────────────────┘
```

#### Left Column — Timer View
* **Active State:**
  * Orange pulsing status badge (`● ACTIVE SPRINT`).
  * Sprint title (e.g. *DEEP WORK*).
  * Giant monospace digital clock displaying live elapsed time (`HH:MM:SS` / `MM:SS`).
  * Start timestamp (e.g. *Started at 1:03 PM*).
  * Prominent **`[⏹ Stop & Save Sprint]`** button.
* **Idle State:**
  * Focus presets: `Deep Work`, `Coding`, `Writing`, `Reading`, `Planning`.
  * Inactive digital clock (`00:00`).
  * Prominent **`[▶️ Start Focus Sprint]`** button.
* **Session Metrics:**
  * `TOTAL FOCUS TODAY`: Total accumulated focus time today.
  * `SPRINTS DONE`: Number of completed work sessions today.
  * `LONGEST SPRINT`: Longest uninterrupted focus block today.
* **Today's History Log:** Scrollable list of today's completed sprints with exact start/end times, durations, and delete actions.

#### Right Column — Day Calendar Timeline
* **Hourly Scale:** Displays a continuous visual hourly map from morning to night (7:00 AM to 11:00 PM, adaptive if sessions occur earlier/later).
* **Hour Guidelines:** Subtle horizontal dividers with clean monospaced time markers (`7 AM`, `8 AM`, ..., `11 PM`).
* **Completed Work Blocks:**
  * Every session completed today is drawn as a colored block positioned along the vertical timeline according to its exact start and end times.
  * Displays the session title, time range (e.g. *9:00 AM – 10:15 AM*), and a duration badge (*1h 15m*).
* **Active Sprint Real-Time Expansion:**
  * While a sprint is running, its block begins at `activeSession.startTime` and expands downward to the current second in real-time.
  * Highlighted with an orange border and an `ACTIVE` tag.
* **Live "NOW" Marker:**
  * A bright red horizontal line with a red `NOW` badge sweeps across the timeline matching the current hour and minute.
  * Gives an instant visual reference of where you are in the day relative to your completed and active work sessions.
* **Remote Navigation:** Press the **Back / Menu button** on the Siri Remote at any time (`.onExitCommand`) or tap **`[← Dashboard]`** to return to the main dashboard. Active sessions continue timing in the background.

---

### 2.4. 10 PM Retro Typography Night Takeover

* **Trigger:** Automatically takes over the screen at 10:00 PM every night (or can be previewed from the dashboard toolbar).
* **Aesthetic:** High-impact retro typography inspired by vintage emergency broadcast PSAs:
  * Giant stacked phrase across 5 lines:
    ```
    do you
    know
    what you
    are
    doing
    ```
  * Deep retro red background (`#A30000`).
  * Cyan/sky-blue condensed lettering (`#5CE1E6`) with subtle dark shadows.
  * Animated CRT scanlines overlay.
* **Single-Click Dismissal:** Pressing *any* button on the Siri Remote (Select, Play/Pause, directional click, or touchpad tap) dismisses the takeover and switches the habit view to Night habits.
* **Cycle Lock:** Once dismissed, the alert will not trigger again during the same night cycle. The lock resets automatically the next morning.

---

### 2.5. Silent Background Timekeeping Synchronization

The system connects to `https://timekeeping.samuelhabib.com` using the user's preconfigured API key (`e2f98c1d58fcad13dcbf7f4a476516e73122d9030ade06c1`).

* **API Endpoints Utilized:**
  * `POST /api/timer/start`: Initiates a live timer on the cloud when starting a focus sprint or habit routine.
  * `POST /api/timer/{id}/stop`: Gracefully stops the remote timer upon sprint completion, attaching task notes, duration, and tags (`work,focus,appletv`).
  * `POST /api/entries`: Fallback direct entry creation for offline resilience.
  * `GET /api/stats`: Fetches aggregated statistics (total hours, total entries, active timers, project breakdowns).
  * `GET /api/entries?limit=20`: Fetches recent server entries.
  * `DELETE /api/entries/{id}`: Deletes remote entries.
* **UI Invisibility:** All synchronization occurs silently in background tasks (`Task`). No URLs, server names, or cloud badges clutter the user interface.

---

### 2.6. No-Choice Single-Card Morning Focus Engine (`MorningFocusView.swift`)

When the Apple TV powers on in the morning (or whenever incomplete morning habits exist), the dashboard activates **Morning Focus Mode**:
* **Zero Decision Fatigue (No Choice):** Replaces the multi-card grid with a single, full-screen card representing the active priority habit. The user cannot see future cards or browse ahead, removing cognitive load and keeping attention strictly on what is happening right now.
* **Sequential Schedule Starting at 8:15 AM:**
  1. **Teeth & Morning Prep** (8:15 AM – 8:25 AM • 10m window)
  2. **Meds** (8:25 AM – 8:30 AM • 5m window)
  3. **Stretch** (8:30 AM – 8:40 AM • 10m window)
  4. **Exercise** (8:40 AM – 8:55 AM • 15m window)
  5. **Foot Rehab** (8:55 AM – 9:05 AM • 10m window)
  6. **Bathroom** (9:05 AM – 9:30 AM • 25m window • Condensed Shave, Shower, Cleanse, Sunscreen)
  7. **Pack & Prep** (9:30 AM – 9:40 AM • 10m window)
  8. **Breakfast** (9:40 AM – 10:00 AM • 20m window)
* **Live Deadline Countdowns:** Calculates the exact remaining time to the card's target deadline with live second-by-second countdowns (`07:42 REMAINING`). If a deadline passes, the timer switches into high-contrast warning mode (`+02:15 OVERDUE`).
* **Condensed Bathroom Protocol:** Displays interactive checkboxes directly on the card for `Shave`, `Shower`, `Cleanse`, and `Sunscreen`.
* **Seamless Guided Routine Integration:** Directly launches dedicated guided engines for Foot Rehab, Stretching, Bodyweight Exercise, and Meds checklist. Completing any guided routine automatically advances to the next morning card.
* **Single-Click Remote Navigation:** Center Clickpad or Play/Pause (`.onPlayPauseCommand`) on the Siri Remote instantly marks the item completed and triggers a smooth slide transition into the next card.

---

### 2.7. Guided Bodyweight & Pushups Workout Protocol (`BodyweightExerciseRoutineView.swift`, `BodyweightExerciseIllustrationView.swift`)

A dedicated calisthenics engine designed for guided at-home bodyweight training:
* **High-Impact Anatomical Illustrations:** High-contrast SwiftUI vector graphics featuring luminous body silhouettes, joint articulation nodes, ground surfaces, and glowing cyan/teal target muscle indicators:
  1. **Standard Pushups:** Neutral rigid plank angle with 90° elbow depth, targeting pectorals, triceps, and anterior core bracing.
  2. **Bodyweight Air Squats:** Parallel thigh depth, upright torso, and arms forward for hip mobility and quadriceps/glutes stamina.
  3. **Forearm Plank Hold:** Isometric core alignment with transverse abdominal tension.
* **Set & Rest Interval Tracking:** Automatic set progression (`SET 1 OF 3`), target repetition logging, countdown timer for holds, and an automated 45-second rest timer with skip options.
* **Automatic Routine Completion:** Completing all workout sets logs the exercise habit and advances the morning routine.

---

## 3. Architecture & File Structure

```
Stupid DashBoard/
├── Stupid_DashBoardApp.swift             // App entry point; disables screensaver on launch
├── AppState.swift                        // Central @Observable state store; timers, data loading & sync
├── ContentView.swift                     // Root layout, dashboard view, 10 PM takeover, routing
├── MorningFocusView.swift                // Single-card "no-choice" morning routine with live deadline countdowns
├── BodyweightExerciseRoutineView.swift   // Full-screen guided pushups & bodyweight calisthenics routine
├── BodyweightExerciseIllustrationView.swift // High-contrast anatomical vector graphics for pushups, squats & plank
├── MedsChecklistView.swift               // Blurred background modal checklist for daily medications
├── StretchingRoutineView.swift           // Full-screen guided mobility & stretching routine engine
├── StretchingExerciseIllustrationView.swift // Static animated vector graphics for stretching poses
├── FootRoutineView.swift                 // Full-screen guided foot rehabilitation engine
├── FootExerciseAnimationView.swift       // Animated vector graphics for foot exercises
├── RoutineSummaryDashboardView.swift     // WorkFocusView: Timer view + Day Calendar Timeline
├── Models.swift                          // Swift data structures for habits, tasks, stretches, medications, weather
├── TimekeepingService.swift              // Actor handling REST API networking & authentication
├── SettingsView.swift                    // Habit configuration, stretching/foot routines & time sync key dialog
├── LocationManager.swift                 // CoreLocation manager for local weather coordinates
└── RoutineSummaryView.swift              // Legacy routine summary modal view
```

### File Responsibilities

| File | Primary Responsibility |
|---|---|
| [`Stupid_DashBoardApp.swift`](file:///Users/samuelfahim/Library/Mobile%20Documents/com~apple~CloudDocs/dev/developingApps/Stupid%20DashBoard/Stupid%20DashBoard/Stupid_DashBoardApp.swift) | Sets `UIApplication.shared.isIdleTimerDisabled = true` and launches `ContentView`. |
| [`AppState.swift`](file:///Users/samuelfahim/Library/Mobile%20Documents/com~apple~CloudDocs/dev/developingApps/Stupid%20DashBoard/Stupid%20DashBoard/AppState.swift) | Central observable state manager. Manages timers, day rollover, foot & stretching routines, bodyweight exercises, morning lock, and sync. |
| [`ContentView.swift`](file:///Users/samuelfahim/Library/Mobile%20Documents/com~apple~CloudDocs/dev/developingApps/Stupid%20DashBoard/Stupid%20DashBoard/ContentView.swift) | Main routing, Morning Focus lock, Sun/Moon habit switcher, Omeprazole banner, Meds blurred modal overlay. |
| [`MorningFocusView.swift`](file:///Users/samuelfahim/Library/Mobile%20Documents/com~apple~CloudDocs/dev/developingApps/Stupid%20DashBoard/Stupid%20DashBoard/MorningFocusView.swift) | Single-card zero-choice morning focus engine displaying one item at a time with live deadline timers. |
| [`BodyweightExerciseRoutineView.swift`](file:///Users/samuelfahim/Library/Mobile%20Documents/com~apple~CloudDocs/dev/developingApps/Stupid%20DashBoard/Stupid%20DashBoard/BodyweightExerciseRoutineView.swift) | Guided sets & reps calisthenics routine for pushups, squats, and plank holds with rest timer. |
| [`BodyweightExerciseIllustrationView.swift`](file:///Users/samuelfahim/Library/Mobile%20Documents/com~apple~CloudDocs/dev/developingApps/Stupid%20DashBoard/Stupid%20DashBoard/BodyweightExerciseIllustrationView.swift) | Luminous anatomical vector illustrations for standard pushups, air squats, and plank holds. |
| [`MedsChecklistView.swift`](file:///Users/samuelfahim/Library/Mobile%20Documents/com~apple~CloudDocs/dev/developingApps/Stupid%20DashBoard/Stupid%20DashBoard/MedsChecklistView.swift) | High-contrast medication checklist modal with ambient background blur and Omeprazole timer trigger. |
| [`StretchingRoutineView.swift`](file:///Users/samuelfahim/Library/Mobile%20Documents/com~apple~CloudDocs/dev/developingApps/Stupid%20DashBoard/Stupid%20DashBoard/StretchingRoutineView.swift) | Full-screen guided mobility & stretching routine with timed holds, set tracking, and completion milestones. |
| [`StretchingExerciseIllustrationView.swift`](file:///Users/samuelfahim/Library/Mobile%20Documents/com~apple~CloudDocs/dev/developingApps/Stupid%20DashBoard/Stupid%20DashBoard/StretchingExerciseIllustrationView.swift) | Static animated vector illustrations for Low Lunge, Wall Figure-4, Puppy Pose, and Seated Side Bend. |
| [`FootRoutineView.swift`](file:///Users/samuelfahim/Library/Mobile%20Documents/com~apple~CloudDocs/dev/developingApps/Stupid%20DashBoard/Stupid%20DashBoard/FootRoutineView.swift) | Full-screen guided foot rehabilitation protocol. |
| [`FootExerciseAnimationView.swift`](file:///Users/samuelfahim/Library/Mobile%20Documents/com~apple~CloudDocs/dev/developingApps/Stupid%20DashBoard/Stupid%20DashBoard/FootExerciseAnimationView.swift) | Vector anatomical graphics and animations for plantar fascia and calf rehabilitation. |
| [`RoutineSummaryDashboardView.swift`](file:///Users/samuelfahim/Library/Mobile%20Documents/com~apple~CloudDocs/dev/developingApps/Stupid%20DashBoard/Stupid%20DashBoard/RoutineSummaryDashboardView.swift) | Implements `WorkFocusView`. Contains the Timer column (left) and the Calendar Day Timeline (right). |
| [`Models.swift`](file:///Users/samuelfahim/Library/Mobile%20Documents/com~apple~CloudDocs/dev/developingApps/Stupid%20DashBoard/Stupid%20DashBoard/Models.swift) | Codable data models (`MorningTask`, `BodyweightExercise`, `MedicationItem`, `StretchingExercise`, etc.). |
| [`TimekeepingService.swift`](file:///Users/samuelfahim/Library/Mobile%20Documents/com~apple~CloudDocs/dev/developingApps/Stupid%20DashBoard/Stupid%20DashBoard/TimekeepingService.swift) | Actor performing network requests with `X-API-Key` authentication header. |
| [`SettingsView.swift`](file:///Users/samuelfahim/Library/Mobile%20Documents/com~apple~CloudDocs/dev/developingApps/Stupid%20DashBoard/Stupid%20DashBoard/SettingsView.swift) | Configure habits, morning deadlines, stretching/foot routines & time sync key dialog. |

---

## 4. Data Models & Local Persistence

All data is saved as JSON in the application's `Documents` sandbox directory:

1. **`morning_tasks.json`**: List of morning habits (Teeth, Meds, Stretch, Foot, Shave, Shower, Cleanse, Sunscreen, Pack, Breakfast).
2. **`night_tasks.json`**: List of night habits (Teeth, Floss, Cleanse, Meds).
3. **`daily_tasks.json`**: Day-specific tasks with creation date and completion state.
4. **`medications.json`**: Daily medications list with completion states, dosages/notes, and Omeprazole flags.
5. **`stretching_routine_exercises.json`**: Configurable exercises for the daily stretching protocol.
6. **`stretching_routine_sessions.json`**: Recorded stretching routine sessions and completed milestones.
7. **`foot_routine_exercises.json`**: Foot rehabilitation exercise protocol.
8. **`foot_routine_sessions.json`**: Recorded foot rehab sessions.
9. **`work_sessions.json`**: Array of `WorkSession` focus sprint items.
10. **`routine_sessions.json`**: Habit milestone timing records.

### UserDefaults Keys
* `timekeepingApiKey`: API key for background sync (defaults to pre-configured key).
* `lastActiveDate`: YYYY-MM-DD string used to detect midnight day rollover.
* `lastDismissedNightCycle`: YYYY-MM-DD string preventing repeated 10 PM popups on the same night.
* `medsTakenTimestamp`: Unix epoch timestamp of when morning medication was taken.

---

## 5. Apple TV Remote Shortcuts & Controls

| Screen | Action | Remote Button / Gesture |
|---|---|---|
| **Any Screen** | Resist Screensaver | Handled automatically in background (`isIdleTimerDisabled = true`). |
| **10 PM Alert** | Dismiss Alert | Any remote button (Select, Play/Pause, Touchpad Click, Directional Arrow). |
| **Dashboard** | Toggle Habit Period | Click Sun (`☀️`) or Moon (`🌙`) icon button. |
| **Dashboard** | Check Off Habit / Task | Select card / row and click Siri Remote center button. |
| **Dashboard** | Open Work & Focus Hub | Click `[Start Focus Sprint]` or `[Work & Focus]` in bottom bar. |
| **Work & Focus** | Stop Active Sprint | Click `[⏹ Stop & Save Sprint]`. |
| **Work & Focus** | Return to Dashboard | Click `[← Dashboard]` or press remote **Menu / Back** button. |
| **Dashboard** | Configure Tasks | Click `[⚙️ Configure Tasks]` in bottom bar. |

---

## 6. Build & Deployment

* **Project Format:** Xcode 16+ `PBXFileSystemSynchronizedRootGroup` (any `.swift` file placed in the project folder is automatically compiled).
* **Target:** tvOS 26.2 (Deployment target: tvOS 26.2).
* **Build Command:**
  ```bash
  xcodebuild -scheme "Stupid DashBoard" -destination "generic/platform=tvOS" -configuration Debug build
  ```

---

## 7. Server Persistence & Behavioral Friction Engine

A high-performance persistence database and FastAPI server runs directly on the local workstation/server:

* **Location:** [`server/`](file:///home/dev/products/day_board/server)
* **Database Engine:** SQLite 3 with Write-Ahead Logging (`WAL` mode) at [`server/dashboard.db`](file:///home/dev/products/day_board/server/dashboard.db)
* **Systemd Service:** `dayboard-server.service` (Active, running on port 8080)
* **Server URL:**
  * Local: `http://localhost:8080`
  * Apple TV LAN: `http://10.0.0.148:8080`
  * Interactive API Docs: `http://10.0.0.148:8080/docs`

### Primary Endpoints
| Endpoint | Method | Description |
|---|---|---|
| `/api/routines/morning` | `POST` / `GET` | Morning routine start/finish times, completion flag, start delay past 8:15 AM, total overdue slippage, and flow friction score. |
| `/api/tasks/event` | `POST` | Fine-grained habit milestone event (started, checked off, exact duration, deadline adherence, overdue seconds, subtasks). |
| `/api/medications/log` | `POST` | Medication intake; automatically computes Omeprazole 30m wait countdown and 30-60m eating window. |
| `/api/medications/eating-event` | `POST` | Validates breakfast timing against Omeprazole window; flags breach friction if eaten too early or late. |
| `/api/guided/session` | `POST` | Foot Rehab, Stretching, and Bodyweight workout session tracking (sets, exercises, hold durations). |
| `/api/work/session` | `POST` | Work & Focus Hub sprints (project, duration, runway bucket, exit reason, fatigue/interruption notes). |
| `/api/friction/log` | `POST` / `GET` | Dedicated friction logging (productive resistance vs unproductive bottlenecks). |
| `/api/sync/state` | `POST` | Full offline-first state reconciliation and daily JSON backup snapshot in a single payload. |
| `/api/analytics/today` | `GET` | Live real-time dashboard intelligence: morning progress, Omeprazole countdown, sprint totals, and friction alerts. |
| `/api/analytics/trends` | `GET` | 7-day and 30-day analytics: bottleneck tasks, morning duration averages, and focus hours. |
