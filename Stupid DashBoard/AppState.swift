import Foundation
import SwiftUI
import Observation
import CoreLocation

@Observable
public class AppState {
    // Current Time and Date
    public var currentTime: String = ""
    public var currentDateString: String = ""
    public var currentDate: Date = Date()
    
    // 10 PM Night Mode State
    public var is10PMNightModeActive: Bool = false
    public var isPreviewing10PM: Bool = false
    public var lastDismissedNightCycle: String = UserDefaults.standard.string(forKey: "lastDismissedNightCycle") ?? ""
    
    // Overtime Sprint Management (Phase 4)
    public var isOvertimeSprint: Bool = false
    public var overtimeCapSeconds: TimeInterval = 1800 // 30 minutes
    public var showOvertimeShutdownAlert: Bool = false
    
    public var isTenPMOrLater: Bool {
        let hour = Calendar.current.component(.hour, from: currentDate)
        return hour >= 22 || hour < 5 // 10:00 PM until 4:59 AM
    }
    
    public var currentNightCycleKey: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentDate)
        let cycleDate: Date
        if hour < 5 {
            // Midnight to 4:59 AM belongs to the cycle that started yesterday at 10 PM
            cycleDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        } else {
            cycleDate = currentDate
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: cycleDate)
    }
    
    public func trigger10PMNightModePreview() {
        isPreviewing10PM = true
        is10PMNightModeActive = true
    }
    
    public func dismiss10PMNightMode() {
        if isTenPMOrLater {
            lastDismissedNightCycle = currentNightCycleKey
            UserDefaults.standard.set(lastDismissedNightCycle, forKey: "lastDismissedNightCycle")
        }
        is10PMNightModeActive = false
        isPreviewing10PM = false
    }
    
    // Tasks
    public var morningTasks: [MorningTask] = []
    public var nightTasks: [NightTask] = []
    public var dailyTasks: [DailyTask] = []
    
    // Foot Rehab Routine State
    public var footExercises: [FootExercise] = []
    public var footRoutineSessions: [FootRoutineSession] = []
    public var activeFootSession: FootRoutineSession?
    public var showFootRoutineScreen: Bool = false
    public var footRoutineSourcePeriod: HabitPeriod?
    public var footRoutineSourceTaskId: UUID?
    
    public var isTodayFootRoutineCompleted: Bool {
        footRoutineSessions.contains { Calendar.current.isDateInToday($0.date) && $0.isCompleted }
    }
    
    public var todayIncompleteFootSession: FootRoutineSession? {
        footRoutineSessions.first { Calendar.current.isDateInToday($0.date) && !$0.isCompleted && (!$0.completedExerciseIds.isEmpty || $0.currentExerciseIndex > 0) }
    }
    
    public var enabledFootExercises: [FootExercise] {
        footExercises.filter { $0.isEnabled }.sorted { $0.order < $1.order }
    }
    
    // Stretching & Mobility Routine State
    public var stretchingExercises: [StretchingExercise] = []
    public var stretchingRoutineSessions: [StretchingRoutineSession] = []
    public var activeStretchingSession: StretchingRoutineSession?
    public var showStretchingRoutineScreen: Bool = false
    public var stretchingRoutineSourcePeriod: HabitPeriod?
    public var stretchingRoutineSourceTaskId: UUID?
    
    public var isTodayStretchingRoutineCompleted: Bool {
        stretchingRoutineSessions.contains { Calendar.current.isDateInToday($0.date) && $0.isCompleted }
    }
    
    public var todayIncompleteStretchingSession: StretchingRoutineSession? {
        stretchingRoutineSessions.first { Calendar.current.isDateInToday($0.date) && !$0.isCompleted && (!$0.completedExerciseIds.isEmpty || $0.currentExerciseIndex > 0) }
    }
    
    public var enabledStretchingExercises: [StretchingExercise] {
        stretchingExercises.filter { $0.isEnabled }.sorted { $0.order < $1.order }
    }
    
    // Bodyweight Exercise Routine State
    public var bodyweightExercises: [BodyweightExercise] = []
    public var bodyweightRoutineSessions: [BodyweightRoutineSession] = []
    public var activeBodyweightSession: BodyweightRoutineSession?
    public var showExerciseRoutineScreen: Bool = false
    public var exerciseRoutineSourceTaskId: UUID?
    
    public var isTodayExerciseRoutineCompleted: Bool {
        bodyweightRoutineSessions.contains { Calendar.current.isDateInToday($0.date) && $0.isCompleted }
    }
    
    public var enabledBodyweightExercises: [BodyweightExercise] {
        bodyweightExercises.filter { $0.isEnabled }.sorted { $0.order < $1.order }
    }
    
    // Tri-Mode Morning Launch System State
    public var currentMorningMode: MorningRoutineMode = .full
    public var morningModeStartTime: Date?
    public var activeTaskStartTime: Date?
    public var presetRunwayBucketForDesk: RunwayBucket? = nil
    
    public var hasRelocatedAfternoonRecharge: Bool {
        currentMorningMode == .express
    }
    
    public var todayDateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: currentDate)
    }
    
    // Backend Server State
    public var backendServerUrl: String {
        get {
            UserDefaults.standard.string(forKey: "dashboardPersistenceServerUrl") ?? DashboardPersistenceService.defaultServerURL
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "dashboardPersistenceServerUrl")
        }
    }
    public var isServerReachable: Bool = false
    public var lastServerSyncDate: Date? = nil
    public var isServerSyncing: Bool = false
    public var isSyncingFromServer: Bool = false
    
    // Morning Focus "No Choice" Mode State
    public var lastBypassedMorningDate: String = UserDefaults.standard.string(forKey: "lastBypassedMorningDate") ?? ""
    
    public var isMorningFocusBypassed: Bool {
        get {
            lastBypassedMorningDate == todayDateKey
        }
        set {
            if newValue {
                lastBypassedMorningDate = todayDateKey
                UserDefaults.standard.set(todayDateKey, forKey: "lastBypassedMorningDate")
            } else {
                lastBypassedMorningDate = ""
                UserDefaults.standard.removeObject(forKey: "lastBypassedMorningDate")
            }
        }
    }
    
    public var hasActiveMorningRoutine: Bool {
        !morningTasks.isEmpty && morningTasks.contains(where: { !$0.isCompleted })
    }
    
    public var isMorningFocusActive: Bool {
        hasActiveMorningRoutine && !isMorningFocusBypassed && !is10PMNightModeActive
    }
    
    public var currentMorningTask: MorningTask? {
        morningTasks.first(where: { !$0.isCompleted })
    }
    
    public var currentMorningTaskIndex: Int {
        morningTasks.firstIndex(where: { !$0.isCompleted }) ?? 0
    }
    
    // Medications State
    public var medications: [MedicationItem] = []
    
    // Routine & Work Tracking State
    public var activeRoutineSession: RoutineSession?
    public var routineSessions: [RoutineSession] = []
    public var lastRoutineSummaryToShow: RoutineSession?
    public var showRoutineResults: Bool = false
    public var showWorkFocusScreen: Bool = false
    public var activeWorkSession: WorkSession?
    public var workSessions: [WorkSession] = []
    public var cloudStats: TimeStatsResponse?
    public var cloudEntries: [TimeEntryResponse] = []
    public var isCloudSyncing: Bool = false
    public var timekeepingApiKey: String = UserDefaults.standard.string(forKey: "timekeepingApiKey") ?? "e2f98c1d58fcad13dcbf7f4a476516e73122d9030ade06c1"
    public var lastMilestoneTime: Date?
    
    public var todayWorkSessions: [WorkSession] {
        let calendar = Calendar.current
        return workSessions.filter { session in
            guard calendar.isDateInToday(session.startTime) else { return false }
            if let active = activeWorkSession {
                if let rId = session.remoteEntryId, let activeRId = active.remoteEntryId, rId == activeRId {
                    return false
                }
                if abs(session.startTime.timeIntervalSince(active.startTime)) < 60 && session.title == active.title {
                    return false
                }
            }
            return true
        }
    }
    
    public var todayWorkDurationSeconds: TimeInterval {
        let past = todayWorkSessions.reduce(0.0) { $0 + $1.durationSeconds }
        let active = activeWorkSession?.durationSeconds ?? 0.0
        return past + active
    }
    
    // Meds / Omeprazole Timer
    public var medsTakenTimestamp: Date?
    
    public var isMedsTimerActive: Bool {
        guard let taken = medsTakenTimestamp else { return false }
        // Keep active for up to 2 hours after meds were taken
        return currentDate.timeIntervalSince(taken) < 2 * 3600
    }
    
    public var eatAfterDate: Date? {
        medsTakenTimestamp?.addingTimeInterval(30 * 60) // 30 minutes lockout
    }
    
    public var eatBeforeDate: Date? {
        medsTakenTimestamp?.addingTimeInterval(60 * 60) // 60 minutes window
    }
    
    public var isOmeprazoleWaitPhase: Bool {
        guard let eatAfter = eatAfterDate else { return false }
        return currentDate < eatAfter
    }
    
    public var isOmeprazoleEatingWindow: Bool {
        guard let eatAfter = eatAfterDate, let eatBefore = eatBeforeDate else { return false }
        return currentDate >= eatAfter && currentDate <= eatBefore
    }
    
    public var omeprazoleWaitSecondsRemaining: Int {
        guard let eatAfter = eatAfterDate else { return 0 }
        return max(0, Int(eatAfter.timeIntervalSince(currentDate)))
    }
    
    public var omeprazoleEatingWindowMinutesRemaining: Int {
        guard let eatBefore = eatBeforeDate else { return 0 }
        let secs = max(0, Int(eatBefore.timeIntervalSince(currentDate)))
        return max(1, (secs + 59) / 60)
    }
    
    // Weather
    public var weather: WeatherSummary = WeatherSummary()
    public var isWeatherLoading: Bool = false
    
    // Location Manager
    public let locationManager = LocationManager()
    
    // Timers & Observers
    private var clockTimer: Timer?
    private var maintenanceTimer: Timer?
    private var weatherTimer: Timer?
    
    // Persistence paths
    private var morningTasksURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("morning_tasks.json")
    }
    
    private var nightTasksURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("night_tasks.json")
    }
    
    private var dailyTasksURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("daily_tasks.json")
    }
    
    private var routineSessionsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("routine_sessions.json")
    }
    
    private var workSessionsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("work_sessions.json")
    }
    
    private var footExercisesURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("foot_routine_exercises.json")
    }
    
    private var footRoutineSessionsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("foot_routine_sessions.json")
    }
    
    private var stretchingExercisesURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("stretching_routine_exercises.json")
    }
    
    private var stretchingRoutineSessionsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("stretching_routine_sessions.json")
    }
    
    private var medicationsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("medications.json")
    }
    
    private var bodyweightExercisesURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("bodyweight_routine_exercises.json")
    }
    
    private var bodyweightRoutineSessionsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("bodyweight_routine_sessions.json")
    }
    
    public static func schedule(for mode: MorningRoutineMode) -> [MorningTask] {
        switch mode {
        case .full:
            return [
                MorningTask(
                    title: "Teeth",
                    subtitle: "Brush teeth & quick morning bathroom prep",
                    isCompleted: false,
                    routineType: nil,
                    durationMinutes: 5,
                    subtasks: nil
                ),
                MorningTask(
                    title: "Meds",
                    subtitle: "Omeprazole + D3 + 16 oz water (30m eating lock)",
                    isCompleted: false,
                    routineType: .meds,
                    durationMinutes: 2,
                    subtasks: nil
                ),
                MorningTask(
                    title: "Foot",
                    subtitle: "Guided Plantar Fascia & Calf Rehab",
                    isCompleted: false,
                    routineType: .foot,
                    durationMinutes: 10,
                    subtasks: nil
                ),
                MorningTask(
                    title: "Stretch",
                    subtitle: "Guided mobility & spine decompression",
                    isCompleted: false,
                    routineType: .stretching,
                    durationMinutes: 10,
                    subtasks: nil
                ),
                MorningTask(
                    title: "Neck",
                    subtitle: "Suboccipital release & neck stretches",
                    isCompleted: false,
                    routineType: .neck,
                    durationMinutes: 5,
                    subtasks: nil
                ),
                MorningTask(
                    title: "Exercise",
                    subtitle: "Bodyweight Pushups & Calisthenics",
                    isCompleted: false,
                    routineType: .exercise,
                    durationMinutes: 15,
                    subtasks: nil
                ),
                MorningTask(
                    title: "Bathroom",
                    subtitle: "Shave • Shower • Cleanse • Sunscreen",
                    isCompleted: false,
                    routineType: .bathroom,
                    durationMinutes: 15,
                    subtasks: ["Shave", "Shower", "Cleanse", "Sunscreen"]
                ),
                MorningTask(
                    title: "Breakfast",
                    subtitle: "Breakfast & morning hydration (eating window open)",
                    isCompleted: false,
                    routineType: nil,
                    durationMinutes: 15,
                    subtasks: nil
                )
            ]
            
        case .express:
            return [
                MorningTask(
                    title: "Teeth & Face",
                    subtitle: "Teeth brushing & cold water splash",
                    isCompleted: false,
                    routineType: nil,
                    durationMinutes: 3,
                    subtasks: nil
                ),
                MorningTask(
                    title: "Meds",
                    subtitle: "Omeprazole + D3 + 16 oz water",
                    isCompleted: false,
                    routineType: .meds,
                    durationMinutes: 2,
                    subtasks: nil
                ),
                MorningTask(
                    title: "Shower",
                    subtitle: "Hot shower, cleanse & sunscreen",
                    isCompleted: false,
                    routineType: .bathroom,
                    durationMinutes: 10,
                    subtasks: ["Shower", "Cleanse", "Sunscreen"]
                ),
                MorningTask(
                    title: "Tech & Hydration",
                    subtitle: "Grab water, cold brew & tech gear",
                    isCompleted: false,
                    routineType: nil,
                    durationMinutes: 5,
                    subtasks: nil
                )
            ]
            
        case .hitByTruck:
            return [
                MorningTask(
                    title: "Electrolyte Saline",
                    subtitle: "16–20 oz water + electrolyte packet or pinch of salt",
                    isCompleted: false,
                    routineType: nil,
                    durationMinutes: 2,
                    subtasks: nil,
                    triageType: .electrolyteHydration
                ),
                MorningTask(
                    title: "CO₂ Breath Reset",
                    subtitle: "Guided 15 physiological sighs (double inhale nose, long exhale mouth)",
                    isCompleted: false,
                    routineType: nil,
                    durationMinutes: 3,
                    subtasks: nil,
                    triageType: .breathingReset
                ),
                MorningTask(
                    title: "Cold/Heat & Teeth",
                    subtitle: "Ice on temples / forehead + warm water on neck / traps",
                    isCompleted: false,
                    routineType: nil,
                    durationMinutes: 5,
                    subtasks: nil,
                    triageType: .temperatureContrast
                ),
                MorningTask(
                    title: "Jaw & Suboccipital",
                    subtitle: "Masseter knuckle drop (5x) & Occipital traction lift (20s)",
                    isCompleted: false,
                    routineType: nil,
                    durationMinutes: 3,
                    subtasks: nil,
                    triageType: .jawRelease
                ),
                MorningTask(
                    title: "Meds Triage",
                    subtitle: "Omeprazole + Acetaminophen (Tylenol) • Avoid NSAIDs",
                    isCompleted: false,
                    routineType: .meds,
                    durationMinutes: 2,
                    subtasks: nil,
                    triageType: .medsSafety
                )
            ]
        }
    }
    
    public static func defaultMorningSchedule() -> [MorningTask] {
        schedule(for: .full)
    }
    
    public func switchMorningMode(to newMode: MorningRoutineMode) {
        guard newMode != currentMorningMode else { return }
        
        let oldTasks = morningTasks
        var newTasks = AppState.schedule(for: newMode)
        
        // Carry over completed progress intelligently:
        let teethCompleted = oldTasks.contains { ($0.title.contains("Teeth") || $0.triageType == .temperatureContrast) && $0.isCompleted }
        let medsCompleted = oldTasks.contains { $0.isMedsTask && $0.isCompleted }
        let showerCompleted = oldTasks.contains { $0.isBathroomTask && $0.isCompleted }
        let stretchCompleted = oldTasks.contains { $0.isStretchingRoutine && $0.isCompleted }
        let footCompleted = oldTasks.contains { $0.isFootRoutine && $0.isCompleted }
        let exerciseCompleted = oldTasks.contains { $0.isExerciseRoutine && $0.isCompleted }
        
        for i in 0..<newTasks.count {
            if (newTasks[i].title.contains("Teeth") || newTasks[i].triageType == .temperatureContrast) && teethCompleted {
                newTasks[i].isCompleted = true
            } else if newTasks[i].isMedsTask && medsCompleted {
                newTasks[i].isCompleted = true
            } else if newTasks[i].isBathroomTask && showerCompleted {
                newTasks[i].isCompleted = true
            } else if newTasks[i].isStretchingRoutine && stretchCompleted {
                newTasks[i].isCompleted = true
            } else if newTasks[i].isFootRoutine && footCompleted {
                newTasks[i].isCompleted = true
            } else if newTasks[i].isExerciseRoutine && exerciseCompleted {
                newTasks[i].isCompleted = true
            }
        }
        
        currentMorningMode = newMode
        UserDefaults.standard.set(newMode.rawValue, forKey: "currentMorningMode")
        morningTasks = newTasks
        
        let now = Date()
        activeTaskStartTime = now
        if let firstIncompleteIdx = morningTasks.firstIndex(where: { !$0.isCompleted }) {
            morningTasks[firstIncompleteIdx].activeStartedAt = now
        } else {
            activeTaskStartTime = nil
            if newMode == .hitByTruck {
                presetRunwayBucketForDesk = .grounding
            }
        }
        
        saveMorningTasks()
    }
    
    public init() {
        // Resist screensaver on Apple TV while app is active
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Load persisted morning mode if present
        if let savedModeRaw = UserDefaults.standard.string(forKey: "currentMorningMode"),
           let savedMode = MorningRoutineMode(rawValue: savedModeRaw) {
            self.currentMorningMode = savedMode
        }
        
        // Ensure default API key is saved
        if UserDefaults.standard.string(forKey: "timekeepingApiKey") == nil || (UserDefaults.standard.string(forKey: "timekeepingApiKey")?.isEmpty ?? true) {
            UserDefaults.standard.set("e2f98c1d58fcad13dcbf7f4a476516e73122d9030ade06c1", forKey: "timekeepingApiKey")
            timekeepingApiKey = "e2f98c1d58fcad13dcbf7f4a476516e73122d9030ade06c1"
        }
        
        // Load initial state
        loadTasks()
        loadRoutineSessions()
        loadWorkSessions()
        loadFootRoutineData()
        loadMedications()
        loadStretchingRoutineData()
        loadBodyweightRoutineData()
        
        // Restore meds taken timestamp if valid within the last 2 hours
        let savedMedsTs = UserDefaults.standard.double(forKey: "medsTakenTimestamp")
        if savedMedsTs > 0 {
            let savedDate = Date(timeIntervalSince1970: savedMedsTs)
            if Date().timeIntervalSince(savedDate) < 2 * 3600 {
                self.medsTakenTimestamp = savedDate
            }
        }
        
        Task {
            await fetchCloudData()
            await fetchServerState()
            
            // Fallback: If local storage was purged and server couldn't restore tasks, regenerate them
            await MainActor.run {
                if self.morningTasks.isEmpty {
                    self.morningTasks = AppState.schedule(for: self.currentMorningMode)
                    self.saveMorningTasks()
                }
                if self.nightTasks.isEmpty {
                    self.nightTasks = [
                        NightTask(title: "Teeth"),
                        NightTask(title: "Floss"),
                        NightTask(title: "Cleanse"),
                        NightTask(title: "Meds")
                    ]
                    self.saveNightTasks()
                }
            }
        }
        
        // Populate or migrate to the Tri-Mode morning schedule
        let hasUpdatedV4 = UserDefaults.standard.bool(forKey: "hasUpdatedTriModeSchedule_v4")
        if !hasUpdatedV4 {
            morningTasks = AppState.schedule(for: currentMorningMode)
            saveMorningTasks()
            UserDefaults.standard.set(true, forKey: "hasUpdatedTriModeSchedule_v4")
        }
        
        // Populate default night tasks if empty
        let hasPopulatedNight = UserDefaults.standard.bool(forKey: "hasPopulatedNightTasks_v1")
        if !hasPopulatedNight {
            nightTasks = [
                NightTask(title: "Teeth"),
                NightTask(title: "Floss"),
                NightTask(title: "Cleanse"),
                NightTask(title: "Meds")
            ]
            saveNightTasks()
            UserDefaults.standard.set(true, forKey: "hasPopulatedNightTasks_v1")
        }
        
        // Start timers
        updateClock()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateClock()
        }
        
        maintenanceTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkDayChange()
            Task { [weak self] in
                await self?.fetchCloudData()
                await self?.fetchServerState()
            }
        }
        
        // Initial day change check
        checkDayChange()
        
        // Weather Timer (every 15 minutes)
        Task {
            await fetchWeather()
        }
        weatherTimer = Timer.scheduledTimer(withTimeInterval: 900.0, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchWeather()
            }
        }
        
        // Observe location changes to refresh weather
        // CoreLocation updates will eventually update locationManager.location, which we can check periodically.
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            if self?.locationManager.location != nil && self?.weather.conditionDescription == "Clear" && self?.weather.uvIndex == 0.0 {
                // If location was just acquired, refresh weather
                Task {
                    await self?.fetchWeather()
                }
            }
        }
        
        // Observe system clock & significant time changes
        NotificationCenter.default.addObserver(forName: UIApplication.significantTimeChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.updateClock()
            self?.checkDayChange()
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSSystemClockDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.updateClock()
            self?.checkDayChange()
        }
    }
    
    // MARK: - Clock Management
    public func updateClock() {
        let now = Date()
        currentDate = now
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        
        let newTime = timeFormatter.string(from: now)
        let newDate = dateFormatter.string(from: now)
        
        if currentTime != newTime {
            currentTime = newTime
        }
        if currentDateString != newDate {
            currentDateString = newDate
        }
        
        // 10 PM Night Mode Takeover Logic
        if isTenPMOrLater {
            // If it is 10 PM or later and tonight's cycle has not been dismissed yet:
            if lastDismissedNightCycle != currentNightCycleKey && !is10PMNightModeActive {
                is10PMNightModeActive = true
            }
        } else {
            // Daytime (5:00 AM - 9:59 PM)
            if is10PMNightModeActive && !isPreviewing10PM {
                is10PMNightModeActive = false
            }
        }
        
        // Overtime Sprint 30-Minute Hard Cap Enforcement
        if isOvertimeSprint, let active = activeWorkSession {
            if active.durationSeconds >= overtimeCapSeconds {
                stopWorkSession(exitReason: .completed, notes: "Overtime sprint ended by 30-minute hard cap")
                isOvertimeSprint = false
                showOvertimeShutdownAlert = true
            }
        }
        
        // Initialize Watchdog Launch Fuse for active morning focus
        if isMorningFocusActive {
            if morningModeStartTime == nil {
                morningModeStartTime = now
            }
            if activeTaskStartTime == nil {
                activeTaskStartTime = now
                if let idx = morningTasks.firstIndex(where: { !$0.isCompleted }) {
                    morningTasks[idx].activeStartedAt = now
                }
            }
        }
    }
    
    // MARK: - Day Change Logic
    public func checkDayChange() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())
        
        let lastDateString = UserDefaults.standard.string(forKey: "lastActiveDate") ?? ""
        
        if todayString != lastDateString {
            // New Day Reset!
            morningModeStartTime = nil
            activeTaskStartTime = nil
            presetRunwayBucketForDesk = nil
            clearMedsTimer()
            resetMorningTasks()
            resetNightTasks()
            cleanOldDailyTasks()
            resetMedications()
            isMorningFocusBypassed = false
            
            UserDefaults.standard.set(todayString, forKey: "lastActiveDate")
            
            // Also refresh weather & sync new day schedule to server
            Task {
                await fetchWeather()
                await syncStateWithServer()
            }
        }
    }
    
    private func resetMorningTasks() {
        morningModeStartTime = nil
        activeTaskStartTime = nil
        morningTasks = AppState.schedule(for: currentMorningMode)
        saveMorningTasks()
    }
    
    private func resetNightTasks() {
        for i in 0..<nightTasks.count {
            nightTasks[i].isCompleted = false
        }
        saveNightTasks()
    }
    
    private func cleanOldDailyTasks() {
        // We only delete daily tasks that are completed and from a previous day.
        // Incomplete daily tasks roll over to today.
        let calendar = Calendar.current
        dailyTasks = dailyTasks.filter { task in
            if task.isCompleted {
                // If it is completed, it must be today's date to keep it.
                return calendar.isDateInToday(task.date)
            }
            // Keep all incomplete tasks (they roll over).
            return true
        }
        saveDailyTasks()
    }
    
    // MARK: - Task CRUD Operations
    
    // Morning Tasks
    public func addMorningTask(title: String, routineType: RoutineType? = nil) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let isFoot = routineType == .foot || title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Foot") == .orderedSame
        let isStretch = routineType == .stretching ||
            title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Stretch") == .orderedSame ||
            title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Stretching") == .orderedSame ||
            title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Exercise") == .orderedSame ||
            title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Stretches") == .orderedSame
        let resolved: RoutineType? = isFoot ? .foot : (isStretch ? .stretching : routineType)
        morningTasks.append(MorningTask(title: title, routineType: resolved))
        saveMorningTasks()
    }
    
    public func toggleMorningTask(_ task: MorningTask) {
        if let index = morningTasks.firstIndex(where: { $0.id == task.id }) {
            morningTasks[index].isCompleted.toggle()
            saveMorningTasks()
        }
    }
    
    public func completeMorningTask(_ task: MorningTask) {
        if let index = morningTasks.firstIndex(where: { $0.id == task.id }) {
            morningTasks[index].isCompleted = true
            recordTaskCompletion(period: .morning, taskId: task.id, taskTitle: task.title)
            
            let now = Date()
            if let nextIdx = morningTasks.firstIndex(where: { !$0.isCompleted }) {
                activeTaskStartTime = now
                morningTasks[nextIdx].activeStartedAt = now
            } else {
                activeTaskStartTime = nil
                if currentMorningMode == .hitByTruck {
                    presetRunwayBucketForDesk = .grounding
                }
                // When morning routine completes, bypass so it doesn't reopen upon relaunch
                isMorningFocusBypassed = true
            }
            
            saveMorningTasks()
            
            let taskIdStr = task.id.uuidString
            let titleStr = task.title
            let allDone = morningTasks.allSatisfy { $0.isCompleted }
            let completedCount = morningTasks.filter { $0.isCompleted }.count
            let totalCount = morningTasks.count
            let todayKey = todayDateKey
            
            Task {
                let event = TaskEventCreate(
                    task_id: taskIdStr,
                    task_title: titleStr,
                    routine_period: "morning",
                    date: todayKey,
                    is_completed: true,
                    friction_notes: "Morning routine step completed"
                )
                _ = await DashboardPersistenceService.shared.logTaskEvent(event: event)
                
                let update = MorningRoutineUpdate(
                    date: todayKey,
                    is_completed: allDone,
                    tasks_count: totalCount,
                    completed_tasks_count: completedCount
                )
                _ = await DashboardPersistenceService.shared.updateMorningRoutine(update: update)
            }
            
            if task.isMedsTask && medsTakenTimestamp == nil {
                startMedsTimer()
            }
        }
    }
    
    // MARK: - Watchdog Launch Fuse Calculations
    public func activeTaskRemainingSeconds() -> Double {
        guard let task = currentMorningTask else { return 0.0 }
        let allotted = Double(task.durationMinutes ?? 5) * 60.0
        let start = activeTaskStartTime ?? currentDate
        let elapsed = currentDate.timeIntervalSince(start)
        return allotted - elapsed
    }
    
    public func modeTotalRemainingSeconds() -> Double {
        let modeTotal = Double(currentMorningMode.estimatedMinutes) * 60.0
        guard let start = morningModeStartTime else { return modeTotal }
        let elapsed = currentDate.timeIntervalSince(start)
        return modeTotal - elapsed
    }
    
    public func launchGentleRunwayGrounding() {
        isMorningFocusBypassed = true
        presetRunwayBucketForDesk = .grounding
        startWorkSession(title: "Runway: Grounding", project: "Runway", runwayBucket: .grounding)
        showWorkFocusScreen = true
    }
    
    public func updateMorningTaskDetails(id: UUID, title: String, subtitle: String?, targetDeadlineTime: String?, durationMinutes: Int?) {
        if let index = morningTasks.firstIndex(where: { $0.id == id }) {
            morningTasks[index].title = title
            morningTasks[index].subtitle = subtitle
            morningTasks[index].targetDeadlineTime = targetDeadlineTime
            morningTasks[index].durationMinutes = durationMinutes
            saveMorningTasks()
        }
    }
    
    public func deleteMorningTask(at offsets: IndexSet) {
        morningTasks.remove(atOffsets: offsets)
        saveMorningTasks()
    }
    
    public func moveMorningTask(from source: IndexSet, to destination: Int) {
        morningTasks.move(fromOffsets: source, toOffset: destination)
        saveMorningTasks()
    }
    
    public func updateMorningTaskTitle(id: UUID, newTitle: String) {
        if let index = morningTasks.firstIndex(where: { $0.id == id }) {
            morningTasks[index].title = newTitle
            let isFoot = morningTasks[index].routineType == .foot || newTitle.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Foot") == .orderedSame
            let isStretch = morningTasks[index].routineType == .stretching ||
                newTitle.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Stretch") == .orderedSame ||
                newTitle.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Stretching") == .orderedSame ||
                newTitle.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Exercise") == .orderedSame ||
                newTitle.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Stretches") == .orderedSame
            if isFoot {
                morningTasks[index].routineType = .foot
            } else if isStretch {
                morningTasks[index].routineType = .stretching
            }
            saveMorningTasks()
        }
    }
    
    // Night Tasks
    public func addNightTask(title: String, routineType: RoutineType? = nil) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let isFoot = routineType == .foot || title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Foot") == .orderedSame
        let isStretch = routineType == .stretching ||
            title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Stretch") == .orderedSame ||
            title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Stretching") == .orderedSame ||
            title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Exercise") == .orderedSame ||
            title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Stretches") == .orderedSame
        let resolved: RoutineType? = isFoot ? .foot : (isStretch ? .stretching : routineType)
        nightTasks.append(NightTask(title: title, routineType: resolved))
        saveNightTasks()
    }
    
    public func toggleNightTask(_ task: NightTask) {
        if let index = nightTasks.firstIndex(where: { $0.id == task.id }) {
            nightTasks[index].isCompleted.toggle()
            saveNightTasks()
        }
    }
    
    public func deleteNightTask(at offsets: IndexSet) {
        nightTasks.remove(atOffsets: offsets)
        saveNightTasks()
    }
    
    public func moveNightTask(from source: IndexSet, to destination: Int) {
        nightTasks.move(fromOffsets: source, toOffset: destination)
        saveNightTasks()
    }
    
    public func updateNightTaskTitle(id: UUID, newTitle: String) {
        if let index = nightTasks.firstIndex(where: { $0.id == id }) {
            nightTasks[index].title = newTitle
            let isFoot = nightTasks[index].routineType == .foot || newTitle.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Foot") == .orderedSame
            let isStretch = nightTasks[index].routineType == .stretching ||
                newTitle.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Stretch") == .orderedSame ||
                newTitle.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Stretching") == .orderedSame ||
                newTitle.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Exercise") == .orderedSame ||
                newTitle.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Stretches") == .orderedSame
            if isFoot {
                nightTasks[index].routineType = .foot
            } else if isStretch {
                nightTasks[index].routineType = .stretching
            }
            saveNightTasks()
        }
    }
    
    // Daily Tasks
    public func addDailyTask(title: String) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        dailyTasks.append(DailyTask(title: title, date: Date()))
        saveDailyTasks()
    }
    
    public func toggleDailyTask(_ task: DailyTask) {
        if let index = dailyTasks.firstIndex(where: { $0.id == task.id }) {
            dailyTasks[index].isCompleted.toggle()
            saveDailyTasks()
        }
    }
    
    public func deleteDailyTask(at offsets: IndexSet) {
        dailyTasks.remove(atOffsets: offsets)
        saveDailyTasks()
    }
    
    public func deleteDailyTask(id: UUID) {
        dailyTasks.removeAll(where: { $0.id == id })
        saveDailyTasks()
    }
    
    // Helper to get only today's daily tasks
    public var todayDailyTasks: [DailyTask] {
        let calendar = Calendar.current
        return dailyTasks.filter { calendar.isDateInToday($0.date) }
    }
    
    // MARK: - Persistence
    public func saveMorningTasks() {
        do {
            let data = try JSONEncoder().encode(morningTasks)
            try data.write(to: morningTasksURL)
        } catch {
            print("Failed to save morning tasks: \(error.localizedDescription)")
        }
        if !isSyncingFromServer {
            Task { [weak self] in
                await self?.syncStateWithServer()
            }
        }
    }
    
    public func saveNightTasks() {
        do {
            let data = try JSONEncoder().encode(nightTasks)
            try data.write(to: nightTasksURL)
        } catch {
            print("Failed to save night tasks: \(error.localizedDescription)")
        }
        if !isSyncingFromServer {
            Task { [weak self] in
                await self?.syncStateWithServer()
            }
        }
    }
    
    public func saveDailyTasks() {
        do {
            let data = try JSONEncoder().encode(dailyTasks)
            try data.write(to: dailyTasksURL)
        } catch {
            print("Failed to save daily tasks: \(error.localizedDescription)")
        }
        if !isSyncingFromServer {
            Task { [weak self] in
                await self?.syncStateWithServer()
            }
        }
    }
    
    private func loadTasks() {
        // Load Morning Tasks
        if FileManager.default.fileExists(atPath: morningTasksURL.path) {
            do {
                let data = try Data(contentsOf: morningTasksURL)
                morningTasks = try JSONDecoder().decode([MorningTask].self, from: data)
            } catch {
                print("Failed to load morning tasks: \(error.localizedDescription)")
            }
        }
        
        // Load Night Tasks
        if FileManager.default.fileExists(atPath: nightTasksURL.path) {
            do {
                let data = try Data(contentsOf: nightTasksURL)
                nightTasks = try JSONDecoder().decode([NightTask].self, from: data)
            } catch {
                print("Failed to load night tasks: \(error.localizedDescription)")
            }
        }
        
        // Load Daily Tasks
        if FileManager.default.fileExists(atPath: dailyTasksURL.path) {
            do {
                let data = try Data(contentsOf: dailyTasksURL)
                dailyTasks = try JSONDecoder().decode([DailyTask].self, from: data)
            } catch {
                print("Failed to load daily tasks: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Routine Management & Persistence
    public func setTimekeepingApiKey(_ key: String) {
        timekeepingApiKey = key
        UserDefaults.standard.set(key, forKey: "timekeepingApiKey")
    }
    
    private func saveRoutineSessions() {
        do {
            let data = try JSONEncoder().encode(routineSessions)
            try data.write(to: routineSessionsURL)
        } catch {
            print("Failed to save routine sessions: \(error.localizedDescription)")
        }
    }
    
    private func loadRoutineSessions() {
        if FileManager.default.fileExists(atPath: routineSessionsURL.path) {
            do {
                let data = try Data(contentsOf: routineSessionsURL)
                routineSessions = try JSONDecoder().decode([RoutineSession].self, from: data)
            } catch {
                print("Failed to load routine sessions: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Foot Rehab Routine Management
    public func loadFootRoutineData() {
        // 1. Load Foot Exercises
        if FileManager.default.fileExists(atPath: footExercisesURL.path) {
            do {
                let data = try Data(contentsOf: footExercisesURL)
                let loaded = try JSONDecoder().decode([FootExercise].self, from: data)
                footExercises = loaded.isEmpty ? FootExercise.defaultExercises : loaded
            } catch {
                print("Failed to load foot exercises: \(error)")
                footExercises = FootExercise.defaultExercises
            }
        } else {
            footExercises = FootExercise.defaultExercises
            saveFootExercises()
        }
        
        // 2. Load Foot Routine Sessions
        if FileManager.default.fileExists(atPath: footRoutineSessionsURL.path) {
            do {
                let data = try Data(contentsOf: footRoutineSessionsURL)
                footRoutineSessions = try JSONDecoder().decode([FootRoutineSession].self, from: data)
            } catch {
                print("Failed to load foot routine sessions: \(error)")
                footRoutineSessions = []
            }
        }
    }
    
    public func saveFootExercises() {
        do {
            let data = try JSONEncoder().encode(footExercises)
            try data.write(to: footExercisesURL)
        } catch {
            print("Failed to save foot exercises: \(error)")
        }
    }
    
    public func saveFootRoutineSessions() {
        do {
            let data = try JSONEncoder().encode(footRoutineSessions)
            try data.write(to: footRoutineSessionsURL)
        } catch {
            print("Failed to save foot routine sessions: \(error)")
        }
    }
    
    public func openFootRoutine(for taskId: UUID? = nil, period: HabitPeriod? = nil) {
        footRoutineSourceTaskId = taskId
        footRoutineSourcePeriod = period
        
        if let incomplete = todayIncompleteFootSession {
            activeFootSession = incomplete
        } else if activeFootSession == nil || !Calendar.current.isDateInToday(activeFootSession!.date) {
            let newSession = FootRoutineSession(date: Date(), startTime: Date())
            activeFootSession = newSession
        }
        showFootRoutineScreen = true
    }
    
    public func startNewFootSession() {
        let newSession = FootRoutineSession(date: Date(), startTime: Date())
        activeFootSession = newSession
        updateFootSessionInHistory(newSession)
    }
    
    public func resumeFootSession() {
        guard let active = activeFootSession else { return }
        updateFootSessionInHistory(active)
    }
    
    public func completeFootExercise(id: UUID) {
        guard var session = activeFootSession else { return }
        if !session.completedExerciseIds.contains(id) {
            session.completedExerciseIds.append(id)
        }
        activeFootSession = session
        updateFootSessionInHistory(session)
    }
    
    public func completeFootRoutine() {
        guard var session = activeFootSession else { return }
        session.isCompleted = true
        session.endTime = Date()
        activeFootSession = session
        updateFootSessionInHistory(session)
        
        // Mark Foot habit as completed in dashboard
        let targetTaskId = footRoutineSourceTaskId
        let targetPeriod = footRoutineSourcePeriod ?? .morning
        
        if targetPeriod == .morning {
            if let id = targetTaskId, let idx = morningTasks.firstIndex(where: { $0.id == id }) {
                completeMorningTask(morningTasks[idx])
            } else if let idx = morningTasks.firstIndex(where: { $0.isFootRoutine }) {
                completeMorningTask(morningTasks[idx])
            }
        } else {
            if let id = targetTaskId, let idx = nightTasks.firstIndex(where: { $0.id == id }) {
                nightTasks[idx].isCompleted = true
                recordTaskCompletion(period: .night, taskId: id, taskTitle: nightTasks[idx].title)
                saveNightTasks()
            } else if let idx = nightTasks.firstIndex(where: { $0.isFootRoutine }) {
                nightTasks[idx].isCompleted = true
                recordTaskCompletion(period: .night, taskId: nightTasks[idx].id, taskTitle: nightTasks[idx].title)
                saveNightTasks()
            }
        }
    }
    
    public func exitFootRoutine(savePartial: Bool = true) {
        if savePartial, let session = activeFootSession {
            updateFootSessionInHistory(session)
        }
        showFootRoutineScreen = false
    }
    
    private func updateFootSessionInHistory(_ session: FootRoutineSession) {
        if let idx = footRoutineSessions.firstIndex(where: { $0.id == session.id }) {
            footRoutineSessions[idx] = session
        } else {
            footRoutineSessions.append(session)
        }
        saveFootRoutineSessions()
    }
    
    public func resetFootExercisesToDefault() {
        footExercises = FootExercise.defaultExercises
        saveFootExercises()
    }
    
    // MARK: - Daily Mobility & Stretching Routine Management
    public func loadStretchingRoutineData() {
        // 1. Load Stretching Exercises
        if FileManager.default.fileExists(atPath: stretchingExercisesURL.path) {
            do {
                let data = try Data(contentsOf: stretchingExercisesURL)
                let loaded = try JSONDecoder().decode([StretchingExercise].self, from: data)
                stretchingExercises = loaded.isEmpty ? StretchingExercise.defaultExercises : loaded
            } catch {
                print("Failed to load stretching exercises: \(error)")
                stretchingExercises = StretchingExercise.defaultExercises
            }
        } else {
            stretchingExercises = StretchingExercise.defaultExercises
            saveStretchingExercises()
        }
        
        // 2. Load Stretching Routine Sessions
        if FileManager.default.fileExists(atPath: stretchingRoutineSessionsURL.path) {
            do {
                let data = try Data(contentsOf: stretchingRoutineSessionsURL)
                stretchingRoutineSessions = try JSONDecoder().decode([StretchingRoutineSession].self, from: data)
            } catch {
                print("Failed to load stretching routine sessions: \(error)")
                stretchingRoutineSessions = []
            }
        }
    }
    
    public func saveStretchingExercises() {
        do {
            let data = try JSONEncoder().encode(stretchingExercises)
            try data.write(to: stretchingExercisesURL)
        } catch {
            print("Failed to save stretching exercises: \(error)")
        }
    }
    
    public func saveStretchingRoutineSessions() {
        do {
            let data = try JSONEncoder().encode(stretchingRoutineSessions)
            try data.write(to: stretchingRoutineSessionsURL)
        } catch {
            print("Failed to save stretching routine sessions: \(error)")
        }
    }
    
    public func openStretchingRoutine(for taskId: UUID? = nil, period: HabitPeriod? = nil) {
        stretchingRoutineSourceTaskId = taskId
        stretchingRoutineSourcePeriod = period
        
        if let incomplete = todayIncompleteStretchingSession {
            activeStretchingSession = incomplete
        } else if activeStretchingSession == nil || !Calendar.current.isDateInToday(activeStretchingSession!.date) {
            let newSession = StretchingRoutineSession(date: Date(), startTime: Date())
            activeStretchingSession = newSession
        }
        showStretchingRoutineScreen = true
    }
    
    public func startNewStretchingSession() {
        let newSession = StretchingRoutineSession(date: Date(), startTime: Date())
        activeStretchingSession = newSession
        updateStretchingSessionInHistory(newSession)
    }
    
    public func resumeStretchingSession() {
        guard let active = activeStretchingSession else { return }
        updateStretchingSessionInHistory(active)
    }
    
    public func completeStretchingExercise(id: UUID) {
        guard var session = activeStretchingSession else { return }
        if !session.completedExerciseIds.contains(id) {
            session.completedExerciseIds.append(id)
        }
        activeStretchingSession = session
        updateStretchingSessionInHistory(session)
    }
    
    public func completeStretchingRoutine() {
        guard var session = activeStretchingSession else { return }
        session.isCompleted = true
        session.endTime = Date()
        activeStretchingSession = session
        updateStretchingSessionInHistory(session)
        
        // Mark Stretch habit as completed in dashboard
        let targetTaskId = stretchingRoutineSourceTaskId
        let targetPeriod = stretchingRoutineSourcePeriod ?? .morning
        
        if targetPeriod == .morning {
            if let id = targetTaskId, let idx = morningTasks.firstIndex(where: { $0.id == id }) {
                completeMorningTask(morningTasks[idx])
            } else if let idx = morningTasks.firstIndex(where: { $0.isStretchingRoutine }) {
                completeMorningTask(morningTasks[idx])
            }
        } else {
            if let id = targetTaskId, let idx = nightTasks.firstIndex(where: { $0.id == id }) {
                nightTasks[idx].isCompleted = true
                recordTaskCompletion(period: .night, taskId: id, taskTitle: nightTasks[idx].title)
                saveNightTasks()
            } else if let idx = nightTasks.firstIndex(where: { $0.isStretchingRoutine }) {
                nightTasks[idx].isCompleted = true
                recordTaskCompletion(period: .night, taskId: nightTasks[idx].id, taskTitle: nightTasks[idx].title)
                saveNightTasks()
            }
        }
    }
    
    public func exitStretchingRoutine(savePartial: Bool = true) {
        if savePartial, let session = activeStretchingSession {
            updateStretchingSessionInHistory(session)
        }
        showStretchingRoutineScreen = false
    }
    
    private func updateStretchingSessionInHistory(_ session: StretchingRoutineSession) {
        if let idx = stretchingRoutineSessions.firstIndex(where: { $0.id == session.id }) {
            stretchingRoutineSessions[idx] = session
        } else {
            stretchingRoutineSessions.append(session)
        }
        saveStretchingRoutineSessions()
    }
    
    public func resetStretchingExercisesToDefault() {
        stretchingExercises = StretchingExercise.defaultExercises
        saveStretchingExercises()
    }
    
    // MARK: - Bodyweight Exercise Routine Management
    public func loadBodyweightRoutineData() {
        if FileManager.default.fileExists(atPath: bodyweightExercisesURL.path) {
            do {
                let data = try Data(contentsOf: bodyweightExercisesURL)
                let loaded = try JSONDecoder().decode([BodyweightExercise].self, from: data)
                bodyweightExercises = loaded.isEmpty ? BodyweightExercise.defaultExercises : loaded
            } catch {
                print("Failed to load bodyweight exercises: \(error)")
                bodyweightExercises = BodyweightExercise.defaultExercises
            }
        } else {
            bodyweightExercises = BodyweightExercise.defaultExercises
            saveBodyweightExercises()
        }
        
        if FileManager.default.fileExists(atPath: bodyweightRoutineSessionsURL.path) {
            do {
                let data = try Data(contentsOf: bodyweightRoutineSessionsURL)
                bodyweightRoutineSessions = try JSONDecoder().decode([BodyweightRoutineSession].self, from: data)
            } catch {
                print("Failed to load bodyweight routine sessions: \(error)")
                bodyweightRoutineSessions = []
            }
        }
    }
    
    public func saveBodyweightExercises() {
        do {
            let data = try JSONEncoder().encode(bodyweightExercises)
            try data.write(to: bodyweightExercisesURL)
        } catch {
            print("Failed to save bodyweight exercises: \(error)")
        }
    }
    
    public func saveBodyweightRoutineSessions() {
        do {
            let data = try JSONEncoder().encode(bodyweightRoutineSessions)
            try data.write(to: bodyweightRoutineSessionsURL)
        } catch {
            print("Failed to save bodyweight routine sessions: \(error)")
        }
    }
    
    public func openExerciseRoutine(for taskId: UUID? = nil) {
        exerciseRoutineSourceTaskId = taskId
        let newSession = BodyweightRoutineSession(date: Date(), startTime: Date())
        activeBodyweightSession = newSession
        showExerciseRoutineScreen = true
    }
    
    public func completeExerciseRoutine() {
        guard var session = activeBodyweightSession else { return }
        session.isCompleted = true
        session.endTime = Date()
        activeBodyweightSession = session
        bodyweightRoutineSessions.append(session)
        saveBodyweightRoutineSessions()
        
        if let targetId = exerciseRoutineSourceTaskId, let idx = morningTasks.firstIndex(where: { $0.id == targetId }) {
            completeMorningTask(morningTasks[idx])
        } else if let idx = morningTasks.firstIndex(where: { $0.isExerciseRoutine }) {
            completeMorningTask(morningTasks[idx])
        }
        showExerciseRoutineScreen = false
    }
    
    public func exitExerciseRoutine() {
        showExerciseRoutineScreen = false
    }
    
    // MARK: - Medication Management
    public func loadMedications() {
        if FileManager.default.fileExists(atPath: medicationsURL.path) {
            do {
                let data = try Data(contentsOf: medicationsURL)
                let loaded = try JSONDecoder().decode([MedicationItem].self, from: data)
                medications = loaded.isEmpty ? MedicationItem.defaultMedications : loaded
            } catch {
                print("Failed to load medications: \(error)")
                medications = MedicationItem.defaultMedications
            }
        } else {
            medications = MedicationItem.defaultMedications
            saveMedications()
        }
    }
    
    public func saveMedications() {
        do {
            let data = try JSONEncoder().encode(medications)
            try data.write(to: medicationsURL)
        } catch {
            print("Failed to save medications: \(error)")
        }
    }
    
    public func toggleMedication(id: UUID) {
        if let index = medications.firstIndex(where: { $0.id == id }) {
            medications[index].isCompleted.toggle()
            saveMedications()
        }
    }
    
    public func addMedication(_ item: MedicationItem) {
        medications.append(item)
        saveMedications()
    }
    
    public func deleteMedication(id: UUID) {
        medications.removeAll { $0.id == id }
        saveMedications()
    }
    
    public func resetMedications() {
        for i in 0..<medications.count {
            medications[i].isCompleted = false
        }
        saveMedications()
    }
    
    public func startMedsTimer() {
        let now = Date().timeIntervalSince1970
        UserDefaults.standard.set(now, forKey: "medsTakenTimestamp")
        medsTakenTimestamp = Date()
        
        let todayKey = todayDateKey
        Task {
            let log = MedicationLogCreate(
                name: "Omeprazole",
                period: "morning",
                date: todayKey,
                taken_at: Date(),
                is_omeprazole: true,
                notes: "Logged from Morning Routine"
            )
            _ = await DashboardPersistenceService.shared.logMedication(log: log)
        }
    }
    
    public func clearMedsTimer() {
        UserDefaults.standard.set(0.0, forKey: "medsTakenTimestamp")
        medsTakenTimestamp = nil
    }
    
    public func startRoutine(period: HabitPeriod) {
        // If an active session already matches this period, keep it running
        if let current = activeRoutineSession, current.period == period {
            return
        }
        
        let session = RoutineSession(period: period, startTime: Date())
        activeRoutineSession = session
        lastMilestoneTime = Date()
        
        // Asynchronously start live timer on API if key exists
        if !timekeepingApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let key = timekeepingApiKey
            Task {
                let remoteId = await TimekeepingService.shared.startLiveTimer(
                    title: "\(period.rawValue) Routine",
                    category: "\(period.rawValue) Routine",
                    apiKey: key
                )
                if let remoteId = remoteId {
                    await MainActor.run {
                        if var active = self.activeRoutineSession, active.id == session.id {
                            active.remoteEntryId = remoteId
                            self.activeRoutineSession = active
                        }
                    }
                }
            }
        }
    }
    
    public func stopRoutine() {
        guard var session = activeRoutineSession else { return }
        session.endTime = Date()
        session.isCompleted = true
        
        routineSessions.insert(session, at: 0)
        saveRoutineSessions()
        
        lastRoutineSummaryToShow = session
        showRoutineResults = true
        activeRoutineSession = nil
        lastMilestoneTime = nil
        
        // Sync to remote API in background
        if !timekeepingApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let key = timekeepingApiKey
            let finishedSession = session
            Task {
                if let remoteId = finishedSession.remoteEntryId {
                    let breakdownText = finishedSession.taskRecords
                        .sorted(by: { $0.durationSeconds > $1.durationSeconds })
                        .map { "\($0.title): \(Int(round($0.durationSeconds)))s" }
                        .joined(separator: ", ")
                    _ = await TimekeepingService.shared.stopLiveTimer(
                        entryId: remoteId,
                        notes: "Completed \(finishedSession.period.rawValue) routine in \(Int(round(finishedSession.totalDurationSeconds)))s. Tasks: \(breakdownText)",
                        tags: "routine,appletv,\(finishedSession.period.rawValue.lowercased()),completed",
                        apiKey: key
                    )
                } else {
                    _ = await TimekeepingService.shared.logCompletedSession(
                        finishedSession,
                        apiKey: key
                    )
                }
                await self.fetchCloudData()
            }
        }
    }
    
    public func recordTaskCompletion(period: HabitPeriod, taskId: UUID, taskTitle: String) {
        guard var session = activeRoutineSession, session.period == period else { return }
        
        let now = Date()
        let startRef = lastMilestoneTime ?? session.startTime
        let duration = max(3.0, now.timeIntervalSince(startRef))
        lastMilestoneTime = now
        
        let record = RoutineTaskRecord(
            taskId: taskId,
            title: taskTitle,
            completedAt: now,
            durationSeconds: duration
        )
        
        session.taskRecords.removeAll(where: { $0.taskId == taskId })
        session.taskRecords.append(record)
        activeRoutineSession = session
    }
    
    public func recordTaskUncompleted(period: HabitPeriod, taskId: UUID) {
        guard var session = activeRoutineSession, session.period == period else { return }
        session.taskRecords.removeAll(where: { $0.taskId == taskId })
        activeRoutineSession = session
    }
    
    public func recordedDuration(for taskId: UUID) -> TimeInterval? {
        // First check current active routine session
        if let current = activeRoutineSession?.taskRecords.first(where: { $0.taskId == taskId }) {
            return current.durationSeconds
        }
        // Fallback: check most recent routine session from today
        let calendar = Calendar.current
        for session in routineSessions {
            if calendar.isDateInToday(session.startTime),
               let match = session.taskRecords.first(where: { $0.taskId == taskId }) {
                return match.durationSeconds
            }
        }
        return nil
    }
    
    public func deleteRoutineSession(id: UUID) {
        routineSessions.removeAll(where: { $0.id == id })
        if lastRoutineSummaryToShow?.id == id {
            lastRoutineSummaryToShow = routineSessions.first
        }
        saveRoutineSessions()
    }
    
    // MARK: - Morning Routine & Launchpad
    public var isMorningRoutineComplete: Bool {
        guard !morningTasks.isEmpty else { return false }
        let allHabitsDone = morningTasks.allSatisfy { $0.isCompleted }
        let noSprintsCompleted = todayWorkSessions.isEmpty && activeWorkSession == nil
        return allHabitsDone && noSprintsCompleted
    }
    
    public func launchFirstSprint() {
        let uncompleted = dailyTasks.filter { !$0.isCompleted }
        if let firstTask = uncompleted.first {
            startWorkSession(
                title: firstTask.title,
                project: "Daily Task",
                runwayBucket: nil,
                linkedTaskId: firstTask.id
            )
        } else {
            startWorkSession(
                title: RunwayBucket.grounding.rawValue,
                project: RunwayBucket.grounding.rawValue,
                runwayBucket: .grounding,
                linkedTaskId: nil
            )
        }
        showWorkFocusScreen = true
    }
    
    public func startOvertimeSprint() {
        isOvertimeSprint = true
        startWorkSession(
            title: "Overtime Sprint",
            project: "Overtime",
            runwayBucket: nil,
            linkedTaskId: nil
        )
    }
    
    // MARK: - Work / Focus Session Tracking
    public func startWorkSession(
        title: String = "Work Sprint",
        project: String = "Work",
        runwayBucket: RunwayBucket? = nil,
        linkedTaskId: UUID? = nil
    ) {
        if activeWorkSession != nil {
            showWorkFocusScreen = true
            return
        }
        
        let session = WorkSession(
            title: title,
            project: project,
            startTime: Date(),
            runwayBucket: runwayBucket,
            linkedTaskId: linkedTaskId
        )
        activeWorkSession = session
        showWorkFocusScreen = true
        
        let key = timekeepingApiKey
        if !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Task {
                var notes = "Started from Apple TV Dashboard"
                if let bucket = runwayBucket {
                    notes += " [Runway: \(bucket.rawValue)]"
                }
                let remoteId = await TimekeepingService.shared.startLiveTimer(
                    title: title,
                    project: project,
                    category: runwayBucket?.rawValue ?? "Focus",
                    notes: notes,
                    tags: "work,focus,appletv\(runwayBucket != nil ? ",\(runwayBucket!.rawValue)" : "")",
                    apiKey: key
                )
                if let remoteId = remoteId {
                    await MainActor.run {
                        if var active = self.activeWorkSession, active.id == session.id {
                            active.remoteEntryId = remoteId
                            self.activeWorkSession = active
                        }
                    }
                }
            }
        }
    }
    
    public func stopWorkSession(exitReason: SessionExitReason = .completed, notes: String? = nil) {
        isOvertimeSprint = false
        guard var session = activeWorkSession else { return }
        session.endTime = Date()
        session.isCompleted = true
        session.exitReason = exitReason
        
        // Auto-complete linked daily task if sprint was marked completed
        if exitReason == .completed, let taskId = session.linkedTaskId {
            if let index = dailyTasks.firstIndex(where: { $0.id == taskId }), !dailyTasks[index].isCompleted {
                dailyTasks[index].isCompleted = true
                saveDailyTasks()
            }
        }
        
        activeWorkSession = nil
        
        // Check if an entry for this session was somehow already placed in workSessions
        if let existingIdx = workSessions.firstIndex(where: {
            ($0.remoteEntryId != nil && session.remoteEntryId != nil && $0.remoteEntryId == session.remoteEntryId) ||
            ($0.id == session.id) ||
            (abs($0.startTime.timeIntervalSince(session.startTime)) < 45 && $0.title == session.title)
        }) {
            workSessions[existingIdx].endTime = session.endTime
            workSessions[existingIdx].isCompleted = true
            workSessions[existingIdx].exitReason = exitReason
            if workSessions[existingIdx].remoteEntryId == nil {
                workSessions[existingIdx].remoteEntryId = session.remoteEntryId
            }
        } else {
            workSessions.insert(session, at: 0)
        }
        
        deduplicateWorkSessions()
        saveWorkSessions()
        
        let key = timekeepingApiKey
        if !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let finished = session
            Task {
                let mins = round((finished.durationSeconds / 60.0) * 10) / 10.0
                var sessionNotes = notes ?? "Focus sprint on Apple TV: \(mins)m"
                sessionNotes += " [Exit: \(exitReason.rawValue)]"
                if let bucket = finished.runwayBucket {
                    sessionNotes += " [Runway: \(bucket.rawValue)]"
                }
                if let remoteId = finished.remoteEntryId {
                    let sanitizedExitTag = exitReason.rawValue.lowercased().replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "/", with: "_")
                    _ = await TimekeepingService.shared.stopLiveTimer(
                        entryId: remoteId,
                        notes: sessionNotes,
                        tags: "work,focus,appletv,\(sanitizedExitTag)",
                        apiKey: key
                    )
                }
                await self.fetchCloudData()
            }
        }
    }
    
    public func deleteWorkSession(id: UUID) {
        if let session = workSessions.first(where: { $0.id == id }), let remoteId = session.remoteEntryId {
            let key = timekeepingApiKey
            if !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Task {
                    _ = await TimekeepingService.shared.deleteEntry(entryId: remoteId, apiKey: key)
                }
            }
        }
        workSessions.removeAll(where: { $0.id == id })
        saveWorkSessions()
    }
    
    public func deduplicateWorkSessions() {
        var seenRemoteIds = Set<Int>()
        var cleaned: [WorkSession] = []
        
        let sorted = workSessions.sorted { $0.startTime > $1.startTime }
        
        for session in sorted {
            // If activeWorkSession is currently running, don't keep duplicate in workSessions
            if let active = activeWorkSession {
                if let rId = session.remoteEntryId, let activeRId = active.remoteEntryId, rId == activeRId {
                    continue
                }
                if abs(session.startTime.timeIntervalSince(active.startTime)) < 60 && session.title == active.title {
                    continue
                }
            }
            
            // Deduplicate by remoteEntryId
            if let rId = session.remoteEntryId {
                if seenRemoteIds.contains(rId) {
                    continue
                }
                seenRemoteIds.insert(rId)
            }
            
            // Deduplicate by proximity (< 45s) and identical title
            let isDuplicate = cleaned.contains { existing in
                if let r1 = existing.remoteEntryId, let r2 = session.remoteEntryId, r1 == r2 {
                    return true
                }
                return abs(existing.startTime.timeIntervalSince(session.startTime)) < 45 && existing.title == session.title
            }
            
            if !isDuplicate {
                cleaned.append(session)
            }
        }
        
        if cleaned.count != workSessions.count {
            workSessions = cleaned
            saveWorkSessions()
        }
    }
    
    private func saveWorkSessions() {
        do {
            let data = try JSONEncoder().encode(workSessions)
            try data.write(to: workSessionsURL)
        } catch {
            print("Failed to save work sessions: \(error.localizedDescription)")
        }
    }
    
    private func loadWorkSessions() {
        if FileManager.default.fileExists(atPath: workSessionsURL.path) {
            do {
                let data = try Data(contentsOf: workSessionsURL)
                workSessions = try JSONDecoder().decode([WorkSession].self, from: data)
                deduplicateWorkSessions()
            } catch {
                print("Failed to load work sessions: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Date Parsing Helper
    private static let isoFormatterFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private static let isoFormatterStandard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    public static func parseISO8601Date(_ string: String) -> Date? {
        if let date = isoFormatterFractional.date(from: string) {
            return date
        }
        return isoFormatterStandard.date(from: string)
    }
    
    // MARK: - Merge Cloud Entries into Local State
    public func mergeCloudEntries(_ entries: [TimeEntryResponse]) {
        var updatedWorkSessions = self.workSessions
        var hasWorkChanges = false
        
        var updatedRoutineSessions = self.routineSessions
        var hasRoutineChanges = false
        
        // Sort ascending by start_time so older entries process first
        let sortedEntries = entries.sorted { e1, e2 in
            (AppState.parseISO8601Date(e1.start_time) ?? Date.distantPast) < (AppState.parseISO8601Date(e2.start_time) ?? Date.distantPast)
        }
        
        for (i, entry) in sortedEntries.enumerated() {
            guard let startDate = AppState.parseISO8601Date(entry.start_time) else { continue }
            var endDate = entry.end_time.flatMap { AppState.parseISO8601Date($0) }
            
            // If end_time is missing but entry is completed or superseded
            if endDate == nil {
                if let durationMins = entry.duration_minutes, durationMins > 0 {
                    endDate = startDate.addingTimeInterval(durationMins * 60)
                } else if i + 1 < sortedEntries.count, let nextStart = AppState.parseISO8601Date(sortedEntries[i + 1].start_time) {
                    // A later entry exists, so this one wasn't kept active
                    endDate = min(nextStart, startDate.addingTimeInterval(25 * 60))
                }
            }
            
            let isHabitRoutine = (entry.project?.lowercased() == "habits") ||
                                 (entry.category?.lowercased().contains("routine") ?? false) ||
                                 (entry.tags?.lowercased().contains("routine") ?? false)
            
            if isHabitRoutine {
                let existingIndex = updatedRoutineSessions.firstIndex { routine in
                    if let remoteId = routine.remoteEntryId, remoteId == entry.id { return true }
                    return abs(routine.startTime.timeIntervalSince(startDate)) < 15
                }
                
                let period: HabitPeriod = (entry.title.lowercased().contains("night") || (entry.category?.lowercased().contains("night") ?? false)) ? .night : .morning
                
                if let index = existingIndex {
                    var routine = updatedRoutineSessions[index]
                    var changed = false
                    if routine.remoteEntryId == nil {
                        routine.remoteEntryId = entry.id
                        changed = true
                    }
                    if routine.endTime == nil && endDate != nil {
                        routine.endTime = endDate
                        routine.isCompleted = true
                        changed = true
                    }
                    if changed {
                        updatedRoutineSessions[index] = routine
                        hasRoutineChanges = true
                    }
                } else {
                    var newRoutine = RoutineSession(
                        id: UUID(),
                        period: period,
                        startTime: startDate,
                        endTime: endDate,
                        taskRecords: [],
                        isCompleted: entry.status == "completed" || endDate != nil
                    )
                    newRoutine.remoteEntryId = entry.id
                    updatedRoutineSessions.append(newRoutine)
                    hasRoutineChanges = true
                }
            } else {
                // Focus / Work Session
                
                // Guard 1: Check if this entry matches the currently ACTIVE work session!
                if let active = self.activeWorkSession {
                    let matchesActiveId = (active.remoteEntryId != nil && active.remoteEntryId == entry.id)
                    let matchesActiveTimeAndTitle = abs(active.startTime.timeIntervalSince(startDate)) < 60 && active.title == entry.title
                    
                    if matchesActiveId || matchesActiveTimeAndTitle {
                        if self.activeWorkSession?.remoteEntryId == nil {
                            self.activeWorkSession?.remoteEntryId = entry.id
                        }
                        // Active sprint is already displayed via activeWorkSession, NEVER duplicate it in workSessions!
                        continue
                    }
                }
                
                // Guard 2: If activeWorkSession is nil, and this is an in-progress sprint started recently (< 2 hours ago), adopt it as active
                if self.activeWorkSession == nil && (entry.status == "in_progress" || endDate == nil) && abs(startDate.timeIntervalSinceNow) < 2 * 3600 {
                    var runway: RunwayBucket? = nil
                    let combinedInfo = "\(entry.title) \(entry.category ?? "") \(entry.notes ?? "") \(entry.tags ?? "")"
                    if combinedInfo.contains("Analog / Grounding") || combinedInfo.contains("Grounding") {
                        runway = .grounding
                    } else if combinedInfo.contains("Reading / Absorption") || combinedInfo.contains("Absorption") {
                        runway = .absorption
                    } else if combinedInfo.contains("Technical Hands-on") || combinedInfo.contains("Technical") {
                        runway = .technical
                    }
                    
                    self.activeWorkSession = WorkSession(
                        id: UUID(),
                        title: entry.title,
                        project: entry.project ?? "Work",
                        startTime: startDate,
                        endTime: nil,
                        remoteEntryId: entry.id,
                        isCompleted: false,
                        exitReason: nil,
                        runwayBucket: runway,
                        linkedTaskId: nil
                    )
                    continue
                }
                
                let existingIndex = updatedWorkSessions.firstIndex { session in
                    if let remoteId = session.remoteEntryId, remoteId == entry.id { return true }
                    return abs(session.startTime.timeIntervalSince(startDate)) < 45 && session.title == entry.title
                }
                
                // Determine RunwayBucket
                var runway: RunwayBucket? = nil
                let combinedInfo = "\(entry.title) \(entry.category ?? "") \(entry.notes ?? "") \(entry.tags ?? "")"
                if combinedInfo.contains("Analog / Grounding") || combinedInfo.contains("Grounding") {
                    runway = .grounding
                } else if combinedInfo.contains("Reading / Absorption") || combinedInfo.contains("Absorption") {
                    runway = .absorption
                } else if combinedInfo.contains("Technical Hands-on") || combinedInfo.contains("Technical") {
                    runway = .technical
                }
                
                // Determine ExitReason
                var exitReason: SessionExitReason? = nil
                if combinedInfo.contains("Completed") || combinedInfo.contains("completed") {
                    exitReason = .completed
                } else if combinedInfo.contains("Interrupted") || combinedInfo.contains("interrupted") {
                    exitReason = .interrupted
                } else if combinedInfo.contains("Headache") || combinedInfo.contains("Fatigue") || combinedInfo.contains("headache") || combinedInfo.contains("fatigue") {
                    exitReason = .fatigueHeadache
                }
                
                let isCompleted = (entry.status == "completed") || (endDate != nil)
                
                if let index = existingIndex {
                    var session = updatedWorkSessions[index]
                    var changed = false
                    if session.remoteEntryId == nil {
                        session.remoteEntryId = entry.id
                        changed = true
                    }
                    if session.endTime == nil && endDate != nil {
                        session.endTime = endDate
                        session.isCompleted = isCompleted
                        changed = true
                    }
                    if session.exitReason == nil && exitReason != nil {
                        session.exitReason = exitReason
                        changed = true
                    }
                    if session.runwayBucket == nil && runway != nil {
                        session.runwayBucket = runway
                        changed = true
                    }
                    if changed {
                        updatedWorkSessions[index] = session
                        hasWorkChanges = true
                    }
                } else {
                    let newSession = WorkSession(
                        id: UUID(),
                        title: entry.title,
                        project: entry.project ?? "Work",
                        startTime: startDate,
                        endTime: endDate,
                        remoteEntryId: entry.id,
                        isCompleted: isCompleted,
                        exitReason: exitReason,
                        runwayBucket: runway,
                        linkedTaskId: nil
                    )
                    updatedWorkSessions.append(newSession)
                    hasWorkChanges = true
                }
            }
        }
        
        if hasWorkChanges {
            updatedWorkSessions.sort { $0.startTime > $1.startTime }
            self.workSessions = updatedWorkSessions
            self.deduplicateWorkSessions()
            saveWorkSessions()
        }
        
        if hasRoutineChanges {
            updatedRoutineSessions.sort { $0.startTime > $1.startTime }
            self.routineSessions = updatedRoutineSessions
            saveRoutineSessions()
        }
    }
    
    // MARK: - Cloud Data Fetching
    public func fetchCloudData() async {
        guard !isCloudSyncing else { return }
        let key = timekeepingApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        
        await MainActor.run { isCloudSyncing = true }
        
        async let statsTask = TimekeepingService.shared.fetchStats(apiKey: key)
        async let entriesTask = TimekeepingService.shared.fetchRecentEntries(apiKey: key, limit: 100)
        
        let stats = await statsTask
        let entries = await entriesTask
        
        await MainActor.run {
            if let stats = stats {
                self.cloudStats = stats
            }
            if let entries = entries {
                self.cloudEntries = entries
                self.mergeCloudEntries(entries)
            }
            self.isCloudSyncing = false
        }
    }

    
    // MARK: - Weather API Fetching
    public func fetchWeather() async {
        guard !isWeatherLoading else { return }
        
        await MainActor.run {
            self.isWeatherLoading = true
        }
        
        let lat: Double
        let lon: Double
        if let loc = locationManager.location {
            lat = loc.coordinate.latitude
            lon = loc.coordinate.longitude
        } else {
            // Fallback to New York coordinates
            lat = 40.7128
            lon = -74.0060
        }
        
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=precipitation,weather_code&hourly=precipitation_probability,uv_index&timezone=auto&forecast_days=1"
        
        guard let url = URL(string: urlString) else {
            await MainActor.run { self.isWeatherLoading = false }
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            
            // Extract current hour index to get current hour's precipitation probability
            let hourFormatter = DateFormatter()
            hourFormatter.dateFormat = "yyyy-MM-dd'T'HH:00"
            hourFormatter.timeZone = TimeZone.current
            let currentHourStr = hourFormatter.string(from: Date())
            
            var currentHourIndex = 0
            if let index = response.hourly.time.firstIndex(of: currentHourStr) {
                currentHourIndex = index
            }
            
            let rainProb = response.hourly.precipitationProbability.indices.contains(currentHourIndex) 
                ? response.hourly.precipitationProbability[currentHourIndex] 
                : 0
            
            let isRaining = response.current.precipitation > 0
            
            // Max UV Index of the day
            let maxUV = response.hourly.uvIndex.max() ?? 0.0
            
            // Textual weather code interpretation
            let desc = wmoCodeToString(response.current.weatherCode)
            
            await MainActor.run {
                self.weather = WeatherSummary(
                    rainProbability: rainProb,
                    isRaining: isRaining,
                    uvIndex: maxUV,
                    conditionDescription: desc
                )
                self.isWeatherLoading = false
            }
        } catch {
            print("Failed to fetch weather: \(error.localizedDescription)")
            await MainActor.run {
                self.isWeatherLoading = false
            }
        }
    }
    
    private func wmoCodeToString(_ code: Int) -> String {
        switch code {
        case 0: return "Clear"
        case 1, 2, 3: return "Partly Cloudy"
        case 45, 48: return "Foggy"
        case 51, 53, 55: return "Drizzle"
        case 61, 63, 65: return "Raining"
        case 66, 67: return "Freezing Rain"
        case 71, 73, 75: return "Snowing"
        case 77: return "Snow Grains"
        case 80, 81, 82: return "Rain Showers"
        case 85, 86: return "Snow Showers"
        case 95, 96, 99: return "Thunderstorm"
        default: return "Cloudy"
        }
    }
    
    // MARK: - Backend Server Synchronization (Tailscale 100.113.33.28:8080)
    
    public func syncStateWithServer() async {
        guard !isServerSyncing else { return }
        isServerSyncing = true
        defer { isServerSyncing = false }
        
        let payload = DashboardSyncPayload(
            morning_tasks: morningTasks,
            night_tasks: nightTasks,
            daily_tasks: dailyTasks,
            medications: medications,
            work_sessions: workSessions,
            foot_sessions: footRoutineSessions,
            stretching_sessions: stretchingRoutineSessions,
            bodyweight_sessions: bodyweightRoutineSessions,
            routine_sessions: routineSessions,
            client_version: "StupidDashBoard-tvOS-26.2"
        )
        
        let success = await DashboardPersistenceService.shared.syncState(payload: payload)
        await MainActor.run {
            self.isServerReachable = success
            if success {
                self.lastServerSyncDate = Date()
            }
        }
    }
    
    public func fetchServerState() async {
        let isHealthy = (try? await DashboardPersistenceService.shared.testConnection()) ?? false
        await MainActor.run {
            self.isServerReachable = isHealthy
        }
        guard isHealthy else { return }
        
        if let snapshot = await DashboardPersistenceService.shared.fetchSnapshot(date: todayDateKey) {
            await MainActor.run {
                self.isSyncingFromServer = true
                defer { self.isSyncingFromServer = false }
                
                // Reconcile morning tasks
                if let remoteMorning = snapshot.morning_tasks, !remoteMorning.isEmpty {
                    for remoteTask in remoteMorning {
                        if let idx = self.morningTasks.firstIndex(where: { $0.id == remoteTask.id }) {
                            if remoteTask.isCompleted && !self.morningTasks[idx].isCompleted {
                                self.morningTasks[idx].isCompleted = true
                            }
                        }
                    }
                    if self.morningTasks.isEmpty {
                        self.morningTasks = remoteMorning
                    }
                    self.saveMorningTasks()
                }
                
                // Reconcile night tasks
                if let remoteNight = snapshot.night_tasks, !remoteNight.isEmpty {
                    for remoteTask in remoteNight {
                        if let idx = self.nightTasks.firstIndex(where: { $0.id == remoteTask.id }) {
                            if remoteTask.isCompleted && !self.nightTasks[idx].isCompleted {
                                self.nightTasks[idx].isCompleted = true
                            }
                        }
                    }
                    if self.nightTasks.isEmpty {
                        self.nightTasks = remoteNight
                    }
                    self.saveNightTasks()
                }
                
                // Reconcile daily tasks
                if let remoteDaily = snapshot.daily_tasks, !remoteDaily.isEmpty {
                    for remoteTask in remoteDaily {
                        if let idx = self.dailyTasks.firstIndex(where: { $0.id == remoteTask.id }) {
                            if remoteTask.isCompleted && !self.dailyTasks[idx].isCompleted {
                                self.dailyTasks[idx].isCompleted = true
                            }
                        } else {
                            self.dailyTasks.append(remoteTask)
                        }
                    }
                    self.saveDailyTasks()
                }
                
                self.lastServerSyncDate = Date()
            }
        }
        
        // Reconcile Omeprazole medication status
        if let status = await DashboardPersistenceService.shared.fetchOmeprazoleStatus(date: todayDateKey) {
            await MainActor.run {
                if let takenAtStr = status.taken_at {
                    let iso = ISO8601DateFormatter()
                    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    let parsedDate = iso.date(from: takenAtStr) ?? ISO8601DateFormatter().date(from: takenAtStr)
                    if let takenDate = parsedDate {
                        if self.medsTakenTimestamp == nil {
                            self.medsTakenTimestamp = takenDate
                            UserDefaults.standard.set(takenDate.timeIntervalSince1970, forKey: "medsTakenTimestamp")
                        }
                    }
                }
            }
        }
    }
}
