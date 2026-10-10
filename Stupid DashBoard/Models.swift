import Foundation

public enum RoutineType: String, Codable, CaseIterable, Identifiable {
    case foot = "Foot"
    case stretching = "Stretching"
    case exercise = "Exercise"
    case meds = "Meds"
    case bathroom = "Bathroom"
    case neck = "Neck"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .foot:
            return "shoeprints.fill"
        case .stretching:
            return "figure.flexibility"
        case .exercise:
            return "figure.strengthtraining.traditional"
        case .meds:
            return "pills.fill"
        case .bathroom:
            return "shower.fill"
        case .neck:
            return "figure.stand.line.dotted.figure.stand"
        }
    }
}

public enum MorningRoutineMode: String, Codable, CaseIterable, Identifiable {
    case full = "Full Protocol"
    case express = "Express Launch"
    case hitByTruck = "Hit by a Truck"
    
    public var id: String { rawValue }
    
    public var estimatedMinutes: Int {
        switch self {
        case .full: return 55
        case .express: return 20
        case .hitByTruck: return 15
        }
    }
    
    public var iconName: String {
        switch self {
        case .full: return "figure.run"
        case .express: return "bolt.fill"
        case .hitByTruck: return "cross.case.fill"
        }
    }
    
    public var shortLabel: String {
        switch self {
        case .full: return "Full (55m)"
        case .express: return "Express (20m)"
        case .hitByTruck: return "Hit by a Truck (15m)"
        }
    }
}

public enum TriageTaskType: String, Codable, CaseIterable, Identifiable {
    case electrolyteHydration = "Electrolyte Saline"
    case breathingReset = "CO₂ Breath Reset"
    case temperatureContrast = "Cold/Heat & Teeth"
    case jawRelease = "Jaw & Suboccipital"
    case medsSafety = "Meds Triage"
    
    public var id: String { rawValue }
}

public struct MorningTask: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var subtitle: String?
    public var isCompleted: Bool
    public var routineType: RoutineType?
    public var targetDeadlineTime: String? // legacy wall-clock display e.g. "8:25 AM"
    public var durationMinutes: Int?       // relative allotted duration e.g. 10
    public var subtasks: [String]?         // e.g. ["Shave", "Shower", "Cleanse", "Sunscreen"]
    public var activeStartedAt: Date?      // exact timestamp this step became active
    public var triageType: TriageTaskType? // triage task indicator for Mode 3
    
    public init(
        id: UUID = UUID(),
        title: String,
        subtitle: String? = nil,
        isCompleted: Bool = false,
        routineType: RoutineType? = nil,
        targetDeadlineTime: String? = nil,
        durationMinutes: Int? = nil,
        subtasks: [String]? = nil,
        activeStartedAt: Date? = nil,
        triageType: TriageTaskType? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.isCompleted = isCompleted
        self.routineType = routineType
        self.targetDeadlineTime = targetDeadlineTime
        self.durationMinutes = durationMinutes
        self.subtasks = subtasks
        self.activeStartedAt = activeStartedAt
        self.triageType = triageType
    }
    
    // Custom Decodable to maintain full backwards compatibility with older JSON files
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        self.isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        self.routineType = try container.decodeIfPresent(RoutineType.self, forKey: .routineType)
        self.targetDeadlineTime = try container.decodeIfPresent(String.self, forKey: .targetDeadlineTime)
        self.durationMinutes = try container.decodeIfPresent(Int.self, forKey: .durationMinutes)
        self.subtasks = try container.decodeIfPresent([String].self, forKey: .subtasks)
        self.activeStartedAt = try container.decodeIfPresent(Date.self, forKey: .activeStartedAt)
        self.triageType = try container.decodeIfPresent(TriageTaskType.self, forKey: .triageType)
    }
    
    public var isFootRoutine: Bool {
        routineType == .foot || title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Foot") == .orderedSame
    }
    
    public var isNeckRoutine: Bool {
        routineType == .neck || title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Neck") == .orderedSame
    }
    
    public var isStretchingRoutine: Bool {
        routineType == .stretching ||
        title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Stretch") == .orderedSame ||
        title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Stretching") == .orderedSame ||
        title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Stretches") == .orderedSame
    }
    
    public var isExerciseRoutine: Bool {
        routineType == .exercise ||
        title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Exercise") == .orderedSame ||
        title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Pushups") == .orderedSame ||
        title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Workout") == .orderedSame ||
        title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Bodyweight") == .orderedSame
    }
    
    public var isMedsTask: Bool {
        if routineType == .meds { return true }
        if triageType == .medsSafety { return true }
        let lower = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return lower.contains("med") || lower.contains("omeprazole") || lower.contains("prilosec") || lower.contains("pill")
    }
    
    public var isBathroomTask: Bool {
        routineType == .bathroom ||
        title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Bathroom") == .orderedSame ||
        title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Shower") == .orderedSame
    }
    
    public var iconName: String {
        if let triage = triageType {
            switch triage {
            case .electrolyteHydration: return "drop.fill"
            case .breathingReset: return "wind"
            case .temperatureContrast: return "thermometer.snowflake"
            case .jawRelease: return "hand.raised.fill"
            case .medsSafety: return "pills.fill"
            }
        }
        if isFootRoutine { return "shoeprints.fill" }
        if isStretchingRoutine { return "figure.flexibility" }
        if isExerciseRoutine { return "figure.strengthtraining.traditional" }
        if isMedsTask { return "pills.fill" }
        if isBathroomTask { return "shower.fill" }
        let lower = title.lowercased()
        if lower.contains("teeth") { return "mouth.fill" }
        if lower.contains("pack") { return "backpack.fill" }
        if lower.contains("breakfast") || lower.contains("eat") { return "fork.knife" }
        return "checkmark.circle"
    }
    
    /// Calculates the Date for today based on targetDeadlineTime string (e.g. "8:25 AM")
    public func deadlineDate(for referenceDate: Date = Date()) -> Date? {
        guard let timeStr = targetDeadlineTime?.trimmingCharacters(in: .whitespacesAndNewlines), !timeStr.isEmpty else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        
        guard let parsedTime = formatter.date(from: timeStr) else {
            return nil
        }
        
        let cal = Calendar.current
        let timeComponents = cal.dateComponents([.hour, .minute], from: parsedTime)
        var refComponents = cal.dateComponents([.year, .month, .day], from: referenceDate)
        refComponents.hour = timeComponents.hour
        refComponents.minute = timeComponents.minute
        refComponents.second = 0
        
        return cal.date(from: refComponents)
    }
}

public struct NightTask: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var isCompleted: Bool
    public var routineType: RoutineType?
    
    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false, routineType: RoutineType? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.routineType = routineType
    }
    
    public var isFootRoutine: Bool {
        routineType == .foot || title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Foot") == .orderedSame
    }
    
    public var isStretchingRoutine: Bool {
        routineType == .stretching ||
        title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Stretch") == .orderedSame ||
        title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Stretching") == .orderedSame ||
        title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Exercise") == .orderedSame ||
        title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("Stretches") == .orderedSame
    }
    
    public var isMedsTask: Bool {
        let lower = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return lower.contains("med") || lower.contains("omeprazole") || lower.contains("prilosec") || lower.contains("pill")
    }
}

// MARK: - Medication Item Model

public struct MedicationItem: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var notes: String
    public var period: HabitPeriod
    public var isCompleted: Bool
    public var isOmeprazole: Bool
    public var order: Int
    
    public init(
        id: UUID = UUID(),
        name: String,
        notes: String = "",
        period: HabitPeriod = .morning,
        isCompleted: Bool = false,
        isOmeprazole: Bool = false,
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.period = period
        self.isCompleted = isCompleted
        self.isOmeprazole = isOmeprazole
        self.order = order
    }
    
    public static var defaultMedications: [MedicationItem] {
        [
            MedicationItem(
                name: "Omeprazole (Prilosec)",
                notes: "Take on empty stomach 30–60 min before food",
                period: .morning,
                isCompleted: false,
                isOmeprazole: true,
                order: 0
            ),
            MedicationItem(
                name: "Vitamin D3",
                notes: "Morning with water or meal",
                period: .morning,
                isCompleted: false,
                isOmeprazole: false,
                order: 1
            ),
            MedicationItem(
                name: "Multivitamin",
                notes: "Daily essential micronutrients",
                period: .morning,
                isCompleted: false,
                isOmeprazole: false,
                order: 2
            ),
            MedicationItem(
                name: "Magnesium Glycinate",
                notes: "Take 30–60 min before bed for muscle relaxation",
                period: .night,
                isCompleted: false,
                isOmeprazole: false,
                order: 0
            ),
            MedicationItem(
                name: "Melatonin",
                notes: "Nightly sleep cycle support",
                period: .night,
                isCompleted: false,
                isOmeprazole: false,
                order: 1
            )
        ]
    }
}

// MARK: - Exercise & Stretching Routine Models

public struct StretchingExercise: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var instruction: String
    public var purpose: String?
    public var targetSeconds: Int?
    public var targetReps: Int?
    public var sets: Int
    public var order: Int
    public var isTimed: Bool
    public var isEnabled: Bool
    public var targetMuscles: String?
    
    public init(
        id: UUID = UUID(),
        name: String,
        instruction: String,
        purpose: String? = nil,
        targetSeconds: Int? = 45,
        targetReps: Int? = nil,
        sets: Int = 2,
        order: Int = 0,
        isTimed: Bool = true,
        isEnabled: Bool = true,
        targetMuscles: String? = nil
    ) {
        self.id = id
        self.name = name
        self.instruction = instruction
        self.purpose = purpose
        self.targetSeconds = targetSeconds
        self.targetReps = targetReps
        self.sets = sets
        self.order = order
        self.isTimed = isTimed
        self.isEnabled = isEnabled
        self.targetMuscles = targetMuscles
    }
    
    public static var defaultExercises: [StretchingExercise] {
        [
            StretchingExercise(
                name: "Low Lunge with Hands Inside",
                instruction: "Step your front foot forward, back knee resting on the mat. Place both hands flat inside the front foot and gently sink your hips down and forward.",
                purpose: "Deeply lengthens the psoas & hip flexors while opening the inner groin.",
                targetSeconds: 45,
                targetReps: nil,
                sets: 2,
                order: 0,
                isTimed: true,
                isEnabled: true,
                targetMuscles: "Hip Flexors, Psoas, Groin"
            ),
            StretchingExercise(
                name: "Wall Figure-4 Stretch",
                instruction: "Lie on your back with one foot planted on the wall, knee bent 90°. Cross the opposite ankle over your knee in a '4' shape and gently press the knee outward.",
                purpose: "Relieves lower back tension and deeply opens the glutes and piriformis with wall support.",
                targetSeconds: 45,
                targetReps: nil,
                sets: 2,
                order: 1,
                isTimed: true,
                isEnabled: true,
                targetMuscles: "Piriformis, Gluteus Medius, Outer Hip"
            ),
            StretchingExercise(
                name: "Puppy Pose",
                instruction: "Kneel with hips directly above your knees. Walk hands forward along the floor and melt your chest toward the mat, resting your forehead gently down.",
                purpose: "Decompresses the spine, expands the ribcage, and opens the thoracic vertebrae and shoulders.",
                targetSeconds: 45,
                targetReps: nil,
                sets: 2,
                order: 2,
                isTimed: true,
                isEnabled: true,
                targetMuscles: "Thoracic Spine, Lats, Shoulders"
            ),
            StretchingExercise(
                name: "Seated Side Bend Stretch",
                instruction: "Sit tall with legs comfortably crossed. Ground one hand beside your hip, sweep your opposite arm overhead and arc gently sideways toward the floor.",
                purpose: "Restores lateral torso mobility, opening the intercostals, obliques, and latissimus dorsi.",
                targetSeconds: 30,
                targetReps: nil,
                sets: 2,
                order: 3,
                isTimed: true,
                isEnabled: true,
                targetMuscles: "Obliques, Intercostals, Lats"
            )
        ]
    }
}

public struct StretchingRoutineSession: Identifiable, Codable, Equatable {
    public var id: UUID
    public var date: Date
    public var startTime: Date
    public var endTime: Date?
    public var completedExerciseIds: [UUID]
    public var currentExerciseIndex: Int
    public var currentSet: Int
    public var isCompleted: Bool
    
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        completedExerciseIds: [UUID] = [],
        currentExerciseIndex: Int = 0,
        currentSet: Int = 1,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.completedExerciseIds = completedExerciseIds
        self.currentExerciseIndex = currentExerciseIndex
        self.currentSet = currentSet
        self.isCompleted = isCompleted
    }
}

// MARK: - Foot Rehab Routine Models

public enum FootExerciseMediaType: String, Codable, CaseIterable, Identifiable {
    case animated = "Animated"
    case video = "Video"
    case instructionOnly = "Instruction Only"
    
    public var id: String { rawValue }
}

public struct FootExercise: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var instruction: String
    public var purpose: String?
    public var targetSeconds: Int?
    public var targetReps: Int?
    public var sets: Int
    public var order: Int
    public var mediaType: FootExerciseMediaType
    public var videoURLString: String?
    public var isTimed: Bool
    public var isEnabled: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        instruction: String,
        purpose: String? = nil,
        targetSeconds: Int? = 30,
        targetReps: Int? = nil,
        sets: Int = 1,
        order: Int = 0,
        mediaType: FootExerciseMediaType = .animated,
        videoURLString: String? = nil,
        isTimed: Bool = true,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.instruction = instruction
        self.purpose = purpose
        self.targetSeconds = targetSeconds
        self.targetReps = targetReps
        self.sets = sets
        self.order = order
        self.mediaType = mediaType
        self.videoURLString = videoURLString
        self.isTimed = isTimed
        self.isEnabled = isEnabled
    }
    
    public var videoURL: URL? {
        guard let s = videoURLString, let url = URL(string: s) else { return nil }
        return url
    }
    
    public static var defaultExercises: [FootExercise] {
        [
            FootExercise(
                name: "Plantar Fascia Stretch",
                instruction: "Sit, cross affected foot over opposite leg. Pull toes gently back toward your shin and hold.",
                purpose: "Gentle stretch of the plantar fascia before loading the foot.",
                targetSeconds: 30,
                targetReps: nil,
                sets: 1,
                order: 0,
                mediaType: .animated,
                videoURLString: nil,
                isTimed: true,
                isEnabled: true
            ),
            FootExercise(
                name: "Straight-Knee Calf Stretch",
                instruction: "Stand facing a wall with affected leg behind you. Keep back knee straight and heel on floor while leaning forward.",
                purpose: "Stretches the upper calf (gastrocnemius) to relieve plantar tension.",
                targetSeconds: 30,
                targetReps: nil,
                sets: 2,
                order: 1,
                mediaType: .animated,
                videoURLString: nil,
                isTimed: true,
                isEnabled: true
            ),
            FootExercise(
                name: "Bent-Knee Calf Stretch",
                instruction: "Same wall position. Slightly bend the rear knee while keeping the heel down firmly on the floor.",
                purpose: "Stretches the deeper calf (soleus) and Achilles tendon.",
                targetSeconds: 30,
                targetReps: nil,
                sets: 2,
                order: 2,
                mediaType: .animated,
                videoURLString: nil,
                isTimed: true,
                isEnabled: true
            ),
            FootExercise(
                name: "Calf Raises",
                instruction: "Rise slowly onto the balls of your feet, pause at the top, then lower under control.",
                purpose: "Strengthens the calf and intrinsic foot muscles with gradual loading.",
                targetSeconds: nil,
                targetReps: 12,
                sets: 2,
                order: 3,
                mediaType: .animated,
                videoURLString: nil,
                isTimed: false,
                isEnabled: true
            )
        ]
    }
}

public struct FootRoutineSession: Identifiable, Codable, Equatable {
    public var id: UUID
    public var date: Date
    public var startTime: Date
    public var endTime: Date?
    public var completedExerciseIds: [UUID]
    public var currentExerciseIndex: Int
    public var currentSet: Int
    public var isCompleted: Bool
    
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        completedExerciseIds: [UUID] = [],
        currentExerciseIndex: Int = 0,
        currentSet: Int = 1,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.completedExerciseIds = completedExerciseIds
        self.currentExerciseIndex = currentExerciseIndex
        self.currentSet = currentSet
        self.isCompleted = isCompleted
    }
}

public enum HabitPeriod: String, CaseIterable, Identifiable, Codable {
    case morning = "Morning"
    case night = "Night"
    
    public var id: String { rawValue }
}

public struct RoutineTaskRecord: Identifiable, Codable, Equatable {
    public var id: UUID
    public var taskId: UUID
    public var title: String
    public var completedAt: Date
    public var durationSeconds: TimeInterval
    
    public init(id: UUID = UUID(), taskId: UUID, title: String, completedAt: Date, durationSeconds: TimeInterval) {
        self.id = id
        self.taskId = taskId
        self.title = title
        self.completedAt = completedAt
        self.durationSeconds = durationSeconds
    }
}

public struct RoutineSession: Identifiable, Codable, Equatable {
    public var id: UUID
    public var period: HabitPeriod
    public var startTime: Date
    public var endTime: Date?
    public var taskRecords: [RoutineTaskRecord]
    public var isCompleted: Bool
    public var remoteEntryId: Int?
    public var isSyncedToRemote: Bool
    
    public init(
        id: UUID = UUID(),
        period: HabitPeriod,
        startTime: Date = Date(),
        endTime: Date? = nil,
        taskRecords: [RoutineTaskRecord] = [],
        isCompleted: Bool = false,
        remoteEntryId: Int? = nil,
        isSyncedToRemote: Bool = false
    ) {
        self.id = id
        self.period = period
        self.startTime = startTime
        self.endTime = endTime
        self.taskRecords = taskRecords
        self.isCompleted = isCompleted
        self.remoteEntryId = remoteEntryId
        self.isSyncedToRemote = isSyncedToRemote
    }
    
    public var totalDurationSeconds: TimeInterval {
        let end = endTime ?? Date()
        return max(0, end.timeIntervalSince(startTime))
    }
    
    public var longestTask: RoutineTaskRecord? {
        taskRecords.max(by: { $0.durationSeconds < $1.durationSeconds })
    }
}

public struct DailyTask: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var date: Date
    public var isCompleted: Bool
    
    public init(id: UUID = UUID(), title: String, date: Date = Date(), isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.date = date
        self.isCompleted = isCompleted
    }
}

public struct WeatherSummary: Codable, Equatable {
    public var rainProbability: Int
    public var isRaining: Bool
    public var uvIndex: Double
    public var conditionDescription: String
    
    public init(rainProbability: Int = 0, isRaining: Bool = false, uvIndex: Double = 0.0, conditionDescription: String = "Clear") {
        self.rainProbability = rainProbability
        self.isRaining = isRaining
        self.uvIndex = uvIndex
        self.conditionDescription = conditionDescription
    }
}

// Structures for decoding Open-Meteo API response
struct OpenMeteoResponse: Codable {
    let current: CurrentWeather
    let hourly: HourlyWeather
    
    struct CurrentWeather: Codable {
        let precipitation: Double
        let weatherCode: Int
        
        enum CodingKeys: String, CodingKey {
            case precipitation
            case weatherCode = "weather_code"
        }
    }
    
    struct HourlyWeather: Codable {
        let time: [String]
        let precipitationProbability: [Int]
        let uvIndex: [Double]
        
        enum CodingKeys: String, CodingKey {
            case time
            case precipitationProbability = "precipitation_probability"
            case uvIndex = "uv_index"
        }
    }
}

// MARK: - Timekeeping API Models

public struct TimeStatsResponse: Codable, Equatable {
    public let total_entries: Int
    public let total_duration_minutes: Double
    public let total_duration_hours: Double
    public let active_timers_count: Int
    public let projects: [String: Double]
    public let categories: [String: Double]
    
    public init(
        total_entries: Int = 0,
        total_duration_minutes: Double = 0,
        total_duration_hours: Double = 0,
        active_timers_count: Int = 0,
        projects: [String: Double] = [:],
        categories: [String: Double] = [:]
    ) {
        self.total_entries = total_entries
        self.total_duration_minutes = total_duration_minutes
        self.total_duration_hours = total_duration_hours
        self.active_timers_count = active_timers_count
        self.projects = projects
        self.categories = categories
    }
}

public struct TimeEntryResponse: Identifiable, Codable, Equatable {
    public let id: Int
    public let title: String
    public let project: String?
    public let category: String?
    public let start_time: String
    public let end_time: String?
    public let duration_minutes: Double?
    public let status: String?
    public let notes: String?
    public let tags: String?
    public let created_at: String?
    public let updated_at: String?
}

public enum SessionExitReason: String, Codable, CaseIterable, Identifiable {
    case completed = "Completed"
    case interrupted = "Interrupted"
    case fatigueHeadache = "Headache / Fatigue"
    
    public var id: String { rawValue }
}

public enum RunwayBucket: String, Codable, CaseIterable, Identifiable {
    case grounding = "Analog / Grounding"
    case absorption = "Reading / Absorption"
    case technical = "Technical Hands-on"
    
    public var id: String { rawValue }
}

public struct WorkSession: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var project: String
    public var startTime: Date
    public var endTime: Date?
    public var remoteEntryId: Int?
    public var isCompleted: Bool
    public var exitReason: SessionExitReason?
    public var runwayBucket: RunwayBucket?
    public var linkedTaskId: UUID?
    
    public init(
        id: UUID = UUID(),
        title: String = "Work Sprint",
        project: String = "Work",
        startTime: Date = Date(),
        endTime: Date? = nil,
        remoteEntryId: Int? = nil,
        isCompleted: Bool = false,
        exitReason: SessionExitReason? = nil,
        runwayBucket: RunwayBucket? = nil,
        linkedTaskId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.project = project
        self.startTime = startTime
        self.endTime = endTime
        self.remoteEntryId = remoteEntryId
        self.isCompleted = isCompleted
        self.exitReason = exitReason
        self.runwayBucket = runwayBucket
        self.linkedTaskId = linkedTaskId
    }
    
    public var durationSeconds: TimeInterval {
        let end = endTime ?? Date()
        return max(0, end.timeIntervalSince(startTime))
    }
}

// MARK: - Bodyweight Exercise Routine Models

public struct BodyweightExercise: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var instruction: String
    public var purpose: String?
    public var targetReps: Int?
    public var targetSeconds: Int?
    public var sets: Int
    public var restSeconds: Int
    public var order: Int
    public var isTimed: Bool
    public var isEnabled: Bool
    public var targetMuscles: String?
    
    public init(
        id: UUID = UUID(),
        name: String,
        instruction: String,
        purpose: String? = nil,
        targetReps: Int? = 15,
        targetSeconds: Int? = nil,
        sets: Int = 3,
        restSeconds: Int = 45,
        order: Int = 0,
        isTimed: Bool = false,
        isEnabled: Bool = true,
        targetMuscles: String? = nil
    ) {
        self.id = id
        self.name = name
        self.instruction = instruction
        self.purpose = purpose
        self.targetReps = targetReps
        self.targetSeconds = targetSeconds
        self.sets = sets
        self.restSeconds = restSeconds
        self.order = order
        self.isTimed = isTimed
        self.isEnabled = isEnabled
        self.targetMuscles = targetMuscles
    }
    
    public static var defaultExercises: [BodyweightExercise] {
        [
            BodyweightExercise(
                name: "Standard Pushups",
                instruction: "Plank position with hands slightly wider than shoulders. Lower chest to 90° elbow bend while bracing core, then press firmly up.",
                purpose: "Builds upper-body pushing power, pectoral strength, triceps, and anterior core stability.",
                targetReps: 15,
                targetSeconds: nil,
                sets: 3,
                restSeconds: 45,
                order: 0,
                isTimed: false,
                isEnabled: true,
                targetMuscles: "Chest, Triceps, Shoulders, Core"
            ),
            BodyweightExercise(
                name: "Bodyweight Air Squats",
                instruction: "Feet shoulder-width apart. Sit hips back and down below parallel, keeping chest proud and knees tracking outward over toes.",
                purpose: "Develops functional hip mobility, quadriceps, glutes, and foundational lower-body stamina.",
                targetReps: 20,
                targetSeconds: nil,
                sets: 3,
                restSeconds: 45,
                order: 1,
                isTimed: false,
                isEnabled: true,
                targetMuscles: "Quadriceps, Glutes, Hamstrings"
            ),
            BodyweightExercise(
                name: "Forearm Plank Hold",
                instruction: "Forearms flat on floor, elbows directly under shoulders. Lock glutes, brace abdominals rigid, and breathe evenly.",
                purpose: "Trains deep isometric transverse abdominal endurance and reinforces pelvic-spine alignment.",
                targetReps: nil,
                targetSeconds: 45,
                sets: 2,
                restSeconds: 30,
                order: 2,
                isTimed: true,
                isEnabled: true,
                targetMuscles: "Core, Abs, Lower Back"
            )
        ]
    }
}

public struct BodyweightRoutineSession: Identifiable, Codable, Equatable {
    public var id: UUID
    public var date: Date
    public var startTime: Date
    public var endTime: Date?
    public var completedExerciseIds: [UUID]
    public var currentExerciseIndex: Int
    public var currentSet: Int
    public var isCompleted: Bool
    
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        completedExerciseIds: [UUID] = [],
        currentExerciseIndex: Int = 0,
        currentSet: Int = 1,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.completedExerciseIds = completedExerciseIds
        self.currentExerciseIndex = currentExerciseIndex
        self.currentSet = currentSet
        self.isCompleted = isCompleted
    }
}

// MARK: - Dashboard Persistence API Models

public struct DashboardSyncPayload: Codable {
    public var date: String?
    public var morning_tasks: [MorningTask]?
    public var night_tasks: [NightTask]?
    public var daily_tasks: [DailyTask]?
    public var medications: [MedicationItem]?
    public var work_sessions: [WorkSession]?
    public var foot_sessions: [FootRoutineSession]?
    public var stretching_sessions: [StretchingRoutineSession]?
    public var bodyweight_sessions: [BodyweightRoutineSession]?
    public var routine_sessions: [RoutineSession]?
    public var client_version: String?
    
    public init(
        date: String? = nil,
        morning_tasks: [MorningTask]? = nil,
        night_tasks: [NightTask]? = nil,
        daily_tasks: [DailyTask]? = nil,
        medications: [MedicationItem]? = nil,
        work_sessions: [WorkSession]? = nil,
        foot_sessions: [FootRoutineSession]? = nil,
        stretching_sessions: [StretchingRoutineSession]? = nil,
        bodyweight_sessions: [BodyweightRoutineSession]? = nil,
        routine_sessions: [RoutineSession]? = nil,
        client_version: String? = "StupidDashBoard-tvOS-26.2"
    ) {
        self.date = date
        self.morning_tasks = morning_tasks
        self.night_tasks = night_tasks
        self.daily_tasks = daily_tasks
        self.medications = medications
        self.work_sessions = work_sessions
        self.foot_sessions = foot_sessions
        self.stretching_sessions = stretching_sessions
        self.bodyweight_sessions = bodyweight_sessions
        self.routine_sessions = routine_sessions
        self.client_version = client_version
    }
}

public struct DashboardSnapshotResponse: Codable {
    public var date: String?
    public var morning_tasks: [MorningTask]?
    public var night_tasks: [NightTask]?
    public var daily_tasks: [DailyTask]?
    public var medications: [MedicationItem]?
    public var work_sessions: [WorkSession]?
    public var foot_sessions: [FootRoutineSession]?
    public var stretching_sessions: [StretchingRoutineSession]?
    public var bodyweight_sessions: [BodyweightRoutineSession]?
    public var routine_sessions: [RoutineSession]?
    public var client_version: String?
}

public struct MorningRoutineUpdate: Codable {
    public var date: String?
    public var started_at: Date?
    public var completed_at: Date?
    public var is_completed: Bool?
    public var total_duration_seconds: Double?
    public var tasks_count: Int?
    public var completed_tasks_count: Int?
    public var start_delay_seconds: Double?
    public var total_overdue_seconds: Double?
    public var notes: String?
    
    public init(
        date: String? = nil,
        started_at: Date? = nil,
        completed_at: Date? = nil,
        is_completed: Bool? = nil,
        total_duration_seconds: Double? = nil,
        tasks_count: Int? = nil,
        completed_tasks_count: Int? = nil,
        start_delay_seconds: Double? = nil,
        total_overdue_seconds: Double? = nil,
        notes: String? = nil
    ) {
        self.date = date
        self.started_at = started_at
        self.completed_at = completed_at
        self.is_completed = is_completed
        self.total_duration_seconds = total_duration_seconds
        self.tasks_count = tasks_count
        self.completed_tasks_count = completed_tasks_count
        self.start_delay_seconds = start_delay_seconds
        self.total_overdue_seconds = total_overdue_seconds
        self.notes = notes
    }
}

public struct MorningRoutineResponse: Codable {
    public var id: String
    public var date: String
    public var started_at: String?
    public var completed_at: String?
    public var is_completed: Bool
    public var total_duration_seconds: Double
    public var tasks_count: Int
    public var completed_tasks_count: Int
    public var target_start_time: String
    public var target_end_time: String
    public var start_delay_seconds: Double
    public var total_overdue_seconds: Double
    public var friction_score: Double
    public var notes: String?
    public var created_at: String
    public var updated_at: String
}

public struct TaskEventCreate: Codable {
    public var task_id: String
    public var task_title: String
    public var routine_period: String
    public var date: String?
    public var routine_type: String?
    public var target_deadline_time: String?
    public var duration_minutes_allotted: Int?
    public var started_at: Date?
    public var completed_at: Date?
    public var actual_duration_seconds: Double
    public var is_completed: Bool
    public var is_overdue: Bool
    public var overdue_seconds: Double
    public var subtasks_completed: [String]?
    public var friction_notes: String?
    
    public init(
        task_id: String,
        task_title: String,
        routine_period: String = "morning",
        date: String? = nil,
        routine_type: String? = nil,
        target_deadline_time: String? = nil,
        duration_minutes_allotted: Int? = nil,
        started_at: Date? = nil,
        completed_at: Date? = nil,
        actual_duration_seconds: Double = 0.0,
        is_completed: Bool = true,
        is_overdue: Bool = false,
        overdue_seconds: Double = 0.0,
        subtasks_completed: [String]? = nil,
        friction_notes: String? = nil
    ) {
        self.task_id = task_id
        self.task_title = task_title
        self.routine_period = routine_period
        self.date = date
        self.routine_type = routine_type
        self.target_deadline_time = target_deadline_time
        self.duration_minutes_allotted = duration_minutes_allotted
        self.started_at = started_at
        self.completed_at = completed_at
        self.actual_duration_seconds = actual_duration_seconds
        self.is_completed = is_completed
        self.is_overdue = is_overdue
        self.overdue_seconds = overdue_seconds
        self.subtasks_completed = subtasks_completed
        self.friction_notes = friction_notes
    }
}

public struct MedicationLogCreate: Codable {
    public var name: String
    public var period: String
    public var date: String?
    public var medication_id: String?
    public var taken_at: Date?
    public var is_omeprazole: Bool
    public var notes: String?
    
    public init(
        name: String,
        period: String = "morning",
        date: String? = nil,
        medication_id: String? = nil,
        taken_at: Date? = nil,
        is_omeprazole: Bool = false,
        notes: String? = nil
    ) {
        self.name = name
        self.period = period
        self.date = date
        self.medication_id = medication_id
        self.taken_at = taken_at
        self.is_omeprazole = is_omeprazole
        self.notes = notes
    }
}

public struct EatingEventCreate: Codable {
    public var date: String?
    public var food_consumed_at: String?
    public var notes: String?
    
    public init(date: String? = nil, food_consumed_at: String? = nil, notes: String? = nil) {
        self.date = date
        self.food_consumed_at = food_consumed_at
        self.notes = notes
    }
}

public struct OmeprazoleServerStatus: Codable {
    public var status: String
    public var message: String
    public var taken_at: String?
    public var eating_window_opens_at: String?
    public var eating_window_closes_at: String?
    public var wait_seconds_remaining: Int
    public var window_seconds_remaining: Int?
    public var eating_window_open: Bool
    public var eating_window_closed: Bool
    public var food_consumed: Bool?
}

public struct WorkSessionCreate: Codable {
    public var id: String?
    public var title: String
    public var project: String
    public var date: String?
    public var started_at: String?
    public var ended_at: String?
    public var duration_seconds: Double
    public var is_completed: Bool
    public var exit_reason: String?
    public var runway_bucket: String?
    public var linked_task_id: String?
    public var is_overtime: Bool
    public var interruption_notes: String?
    public var remote_entry_id: Int?
    
    public init(
        id: String? = nil,
        title: String = "Deep Work",
        project: String = "Work",
        date: String? = nil,
        started_at: String? = nil,
        ended_at: String? = nil,
        duration_seconds: Double = 0.0,
        is_completed: Bool = true,
        exit_reason: String? = "Completed",
        runway_bucket: String? = "Technical Hands-on",
        linked_task_id: String? = nil,
        is_overtime: Bool = false,
        interruption_notes: String? = nil,
        remote_entry_id: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.project = project
        self.date = date
        self.started_at = started_at
        self.ended_at = ended_at
        self.duration_seconds = duration_seconds
        self.is_completed = is_completed
        self.exit_reason = exit_reason
        self.runway_bucket = runway_bucket
        self.linked_task_id = linked_task_id
        self.is_overtime = is_overtime
        self.interruption_notes = interruption_notes
        self.remote_entry_id = remote_entry_id
    }
}


