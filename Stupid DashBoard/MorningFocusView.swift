import SwiftUI

public struct MorningFocusView: View {
    @Bindable var appState: AppState
    public let onOpenMeds: () -> Void
    
    // Focus Control for Apple TV Siri Remote
    private enum FocusButton: Hashable {
        case primaryAction
        case secondaryAction
        case exitDashboard
        case bathroomSubtask(String)
        case completionDone
    }
    @FocusState private var focusedButton: FocusButton?
    
    // Bathroom interactive sub-items state
    @State private var completedSubtasks: Set<String> = []
    
    // Total count of morning tasks
    private var totalTasksCount: Int {
        appState.morningTasks.count
    }
    
    // Current active task
    private var currentTask: MorningTask? {
        appState.currentMorningTask
    }
    
    // Current active index
    private var currentIndex: Int {
        appState.currentMorningTaskIndex
    }
    
    public init(appState: AppState, onOpenMeds: @escaping () -> Void) {
        self.appState = appState
        self.onOpenMeds = onOpenMeds
    }
    
    public var body: some View {
        ZStack {
            // Obsidian Backdrop
            Color(red: 0.05, green: 0.05, blue: 0.07)
                .ignoresSafeArea()
            
            // Warm Sunrise Ambient Aura in top-left
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.40, green: 0.22, blue: 0.05).opacity(0.32),
                    Color(white: 0.05).opacity(0.15),
                    Color(red: 0.03, green: 0.03, blue: 0.04)
                ]),
                center: .topLeading,
                startRadius: 80,
                endRadius: 900
            )
            .ignoresSafeArea()
            
            if let task = currentTask {
                VStack(spacing: 0) {
                    // Top Header Bar
                    topHeaderBar
                        .padding(.horizontal, 60)
                        .padding(.top, 40)
                        .padding(.bottom, 24)
                    
                    // Single Focused Card (Center Stage)
                    Spacer()
                    
                    singleFocusCard(task: task)
                        .id(task.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    
                    Spacer()
                    
                    // Bottom Navigation Hint
                    bottomFooterHint
                        .padding(.bottom, 36)
                }
            } else {
                // All Morning Habits Completed Celebration
                allCompletedCelebrationView
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: currentTask?.id)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedButton = .primaryAction
            }
        }
        .onExitCommand {
            // Allow user to temporarily bypass to normal dashboard if needed
            withAnimation(.easeInOut(duration: 0.3)) {
                appState.isMorningFocusBypassed = true
            }
        }
    }
    
    // MARK: - Top Header Bar
    private var topHeaderBar: some View {
        HStack(alignment: .center, spacing: 30) {
            // Live Clock & Date
            VStack(alignment: .leading, spacing: 4) {
                Text(appState.currentTime)
                    .font(.system(size: 80, weight: .bold, design: .default))
                    .tracking(-1.5)
                    .foregroundColor(.white)
                
                Text(appState.currentDateString)
                    .font(.title3)
                    .foregroundColor(Color.white.opacity(0.75))
            }
            
            Spacer()
            
            // Progress Indicator (Zero Spoilers: Shows sequence number without future card names)
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.78, blue: 0.2))
                        .frame(width: 8, height: 8)
                    
                    Text("MORNING FOCUS")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .tracking(2.5)
                        .foregroundColor(Color(red: 1.0, green: 0.78, blue: 0.2))
                }
                
                Text("STEP \(currentIndex + 1) OF \(totalTasksCount)")
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                
                // Segmented Step Indicator
                HStack(spacing: 6) {
                    ForEach(0..<totalTasksCount, id: \.self) { i in
                        Capsule()
                            .fill(
                                i < currentIndex ? Color.green :
                                (i == currentIndex ? Color(red: 1.0, green: 0.78, blue: 0.2) : Color.white.opacity(0.18))
                            )
                            .frame(width: i == currentIndex ? 24 : 10, height: 6)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.04))
            .cornerRadius(16)
            
            Spacer()
            
            // Weather Summary & Dashboard Bypass
            HStack(spacing: 20) {
                HStack(spacing: 12) {
                    Text(weatherEmoji(isRaining: appState.weather.isRaining, desc: appState.weather.conditionDescription))
                        .font(.system(size: 32))
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(appState.weather.conditionDescription)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("UV \(Int(round(appState.weather.uvIndex))) • Rain \(appState.weather.rainProbability)%")
                            .font(.caption2)
                            .foregroundColor(Color.white.opacity(0.70))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.04))
                .cornerRadius(14)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        appState.isMorningFocusBypassed = true
                    }
                }) {
                    Image(systemName: "square.grid.2x2")
                        .font(.title3)
                        .foregroundColor(Color.white.opacity(0.60))
                        .padding(10)
                }
                .buttonStyle(.bordered)
                .focused($focusedButton, equals: .exitDashboard)
            }
        }
    }
    
    // MARK: - Single Focus Card
    private func singleFocusCard(task: MorningTask) -> some View {
        let deadlineInfo = computeDeadlineInfo(for: task)
        
        return VStack(spacing: 28) {
            // Task Header: Icon + Title + Subtitle
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(taskAccentColor(task).opacity(0.18))
                        .frame(width: 86, height: 86)
                    
                    Image(systemName: task.iconName)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(taskAccentColor(task))
                }
                
                Text(task.title.uppercased())
                    .font(.system(size: 52, weight: .black))
                    .tracking(1.5)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                if let subtitle = task.subtitle {
                    Text(subtitle)
                        .font(.title3)
                        .foregroundColor(Color.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                }
            }
            
            // Deadline & Countdown Stage Banner
            if let deadlineStr = task.targetDeadlineTime {
                HStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TARGET DEADLINE")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(Color.white.opacity(0.60))
                        
                        Text(deadlineStr)
                            .font(.system(size: 34, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    
                    Divider()
                        .frame(height: 48)
                        .background(Color.white.opacity(0.15))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(deadlineInfo.isOverdue ? "STATUS: OVERDUE" : "TIME REMAINING")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(deadlineInfo.isOverdue ? Color(red: 1.0, green: 0.35, blue: 0.35) : taskAccentColor(task))
                        
                        Text(deadlineInfo.countdownText)
                            .font(.system(size: 34, weight: .black, design: .monospaced))
                            .foregroundColor(deadlineInfo.isOverdue ? Color(red: 1.0, green: 0.35, blue: 0.35) : taskAccentColor(task))
                    }
                    
                    Spacer()
                    
                    // Visual progress gauge
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("\(task.durationMinutes ?? 10)m window")
                            .font(.caption2)
                            .foregroundColor(Color.white.opacity(0.55))
                        
                        ProgressView(value: deadlineInfo.progress)
                            .progressViewStyle(.linear)
                            .tint(deadlineInfo.isOverdue ? Color.red : taskAccentColor(task))
                            .frame(width: 160)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 18)
                .background(Color.white.opacity(0.04))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            deadlineInfo.isOverdue ?
                                Color.red.opacity(0.40) :
                                taskAccentColor(task).opacity(0.30),
                            lineWidth: 1.5
                        )
                )
            }
            
            // Special Interactive Content
            if task.isBathroomTask {
                bathroomSubtasksRow(task: task)
            } else if task.isMedsTask {
                medsPreviewRow
            } else if task.isStretchingRoutine {
                guidedProtocolPreviewRow(tags: ["Low Lunge", "Wall Figure-4", "Puppy Pose", "Side Bend"])
            } else if task.isExerciseRoutine {
                guidedProtocolPreviewRow(tags: ["Pushups", "Air Squats", "Forearm Plank"])
            } else if task.isFootRoutine {
                guidedProtocolPreviewRow(tags: ["Plantar Fascia", "Straight Calf", "Bent Calf", "Calf Raises"])
            }
            
            // Primary Action Buttons
            actionButtons(task: task)
        }
        .padding(48)
        .frame(maxWidth: 1040)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.12), Color(white: 0.07)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(
                    LinearGradient(
                        colors: [
                            taskAccentColor(task).opacity(0.5),
                            taskAccentColor(task).opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: taskAccentColor(task).opacity(0.12), radius: 40, x: 0, y: 12)
    }
    
    // MARK: - Bathroom Subtasks Row
    private func bathroomSubtasksRow(task: MorningTask) -> some View {
        let subtasks = task.subtasks ?? ["Shave", "Shower", "Cleanse", "Sunscreen"]
        
        return HStack(spacing: 16) {
            ForEach(subtasks, id: \.self) { item in
                let isDone = completedSubtasks.contains(item)
                Button(action: {
                    if isDone {
                        completedSubtasks.remove(item)
                    } else {
                        completedSubtasks.insert(item)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isDone ? .green : Color.white.opacity(0.50))
                            .font(.headline)
                        
                        Text(item)
                            .font(.headline)
                            .foregroundColor(isDone ? Color.white.opacity(0.60) : .white)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(isDone ? Color.green.opacity(0.12) : Color.white.opacity(0.06))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .focused($focusedButton, equals: .bathroomSubtask(item))
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Meds Preview Row
    private var medsPreviewRow: some View {
        HStack(spacing: 14) {
            ForEach(appState.medications.filter { $0.period == .morning }.prefix(4)) { med in
                HStack(spacing: 6) {
                    Image(systemName: med.isCompleted ? "checkmark.circle.fill" : "pills")
                        .foregroundColor(med.isCompleted ? .green : .cyan)
                        .font(.caption)
                    
                    Text(med.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(med.isCompleted ? Color.white.opacity(0.60) : .white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.06))
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Guided Protocol Preview Row
    private func guidedProtocolPreviewRow(tags: [String]) -> some View {
        HStack(spacing: 12) {
            Text("PROTOCOL:")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.50))
            
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.0, green: 0.92, blue: 1.0))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.0, green: 0.92, blue: 1.0).opacity(0.12))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Action Buttons
    @ViewBuilder
    private func actionButtons(task: MorningTask) -> some View {
        HStack(spacing: 24) {
            if task.isFootRoutine {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        appState.openFootRoutine(for: task.id, period: .morning)
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                        Text("Start Foot Rehab Protocol")
                    }
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .focused($focusedButton, equals: .primaryAction)
                
                Button(action: {
                    completeTaskAndAdvance(task)
                }) {
                    Text("Skip & Mark Complete")
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.65))
                }
                .buttonStyle(.bordered)
                .focused($focusedButton, equals: .secondaryAction)
                
            } else if task.isStretchingRoutine {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        appState.openStretchingRoutine(for: task.id, period: .morning)
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                        Text("Start Guided Stretches (10m)")
                    }
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .focused($focusedButton, equals: .primaryAction)
                
                Button(action: {
                    completeTaskAndAdvance(task)
                }) {
                    Text("Skip & Mark Complete")
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.65))
                }
                .buttonStyle(.bordered)
                .focused($focusedButton, equals: .secondaryAction)
                
            } else if task.isExerciseRoutine {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        appState.openExerciseRoutine(for: task.id)
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                        Text("Start Pushups & Workout (15m)")
                    }
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.0, green: 0.92, blue: 1.0))
                .focused($focusedButton, equals: .primaryAction)
                
                Button(action: {
                    completeTaskAndAdvance(task)
                }) {
                    Text("Skip & Mark Complete")
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.65))
                }
                .buttonStyle(.bordered)
                .focused($focusedButton, equals: .secondaryAction)
                
            } else if task.isMedsTask {
                Button(action: onOpenMeds) {
                    HStack(spacing: 12) {
                        Image(systemName: "pills.fill")
                        Text("Open Medication Checklist")
                    }
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .focused($focusedButton, equals: .primaryAction)
                
                Button(action: {
                    completeTaskAndAdvance(task)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                        Text("All Meds Taken")
                    }
                    .font(.body)
                    .foregroundColor(.white)
                }
                .buttonStyle(.bordered)
                .focused($focusedButton, equals: .secondaryAction)
                
            } else {
                // Standard task (Teeth, Bathroom, Pack, Breakfast)
                Button(action: {
                    completeTaskAndAdvance(task)
                }) {
                    HStack(spacing: 14) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete & Next Task")
                    }
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.horizontal, 38)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(taskAccentColor(task))
                .focused($focusedButton, equals: .primaryAction)
                .onPlayPauseCommand {
                    completeTaskAndAdvance(task)
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Task Advancement
    private func completeTaskAndAdvance(_ task: MorningTask) {
        withAnimation(.easeInOut(duration: 0.35)) {
            appState.completeMorningTask(task)
            completedSubtasks.removeAll()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedButton = .primaryAction
        }
    }
    
    // MARK: - Bottom Footer Hint
    private var bottomFooterHint: some View {
        HStack(spacing: 24) {
            HStack(spacing: 8) {
                Image(systemName: "playpause.fill")
                    .foregroundColor(Color.white.opacity(0.60))
                Text("Play/Pause: Complete & Advance")
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.60))
            }
            
            Text("•")
                .foregroundColor(Color.white.opacity(0.30))
            
            HStack(spacing: 8) {
                Image(systemName: "arrow.backward")
                    .foregroundColor(Color.white.opacity(0.60))
                Text("Back Button: Dashboard")
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.60))
            }
        }
    }
    
    // MARK: - All Completed Celebration View
    private var allCompletedCelebrationView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 96))
                .foregroundColor(.green)
            
            VStack(spacing: 10) {
                Text("MORNING ROUTINE COMPLETE!")
                    .font(.system(size: 48, weight: .black))
                    .tracking(2)
                    .foregroundColor(.white)
                
                Text("You've finished all \(totalTasksCount) habits with zero hesitation.")
                    .font(.title3)
                    .foregroundColor(Color.white.opacity(0.80))
            }
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    appState.isMorningFocusBypassed = true
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Enter Ambient Dashboard")
                }
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .focused($focusedButton, equals: .completionDone)
            
            Spacer()
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedButton = .completionDone
            }
        }
    }
    
    // MARK: - Deadline Calculation Helpers
    private struct DeadlineInfo {
        let isOverdue: Bool
        let countdownText: String
        let progress: Double
    }
    
    private func computeDeadlineInfo(for task: MorningTask) -> DeadlineInfo {
        guard let deadline = task.deadlineDate(for: appState.currentDate) else {
            return DeadlineInfo(isOverdue: false, countdownText: "--:--", progress: 0.0)
        }
        
        let now = appState.currentDate
        let diff = deadline.timeIntervalSince(now)
        let durationSecs = TimeInterval((task.durationMinutes ?? 10) * 60)
        
        if diff >= 0 {
            let total = Int(diff)
            let mins = total / 60
            let secs = total % 60
            let text = String(format: "%02d:%02d REMAINING", mins, secs)
            let elapsed = max(0, durationSecs - diff)
            let prog = min(1.0, max(0.0, elapsed / durationSecs))
            return DeadlineInfo(isOverdue: false, countdownText: text, progress: prog)
        } else {
            let overdue = Int(abs(diff))
            let mins = overdue / 60
            let secs = overdue % 60
            let text = String(format: "+%02d:%02d OVERDUE", mins, secs)
            return DeadlineInfo(isOverdue: true, countdownText: text, progress: 1.0)
        }
    }
    
    private func taskAccentColor(_ task: MorningTask) -> Color {
        if task.isFootRoutine { return Color.cyan }
        if task.isStretchingRoutine { return Color(red: 0.0, green: 0.92, blue: 1.0) }
        if task.isExerciseRoutine { return Color(red: 0.0, green: 0.92, blue: 1.0) }
        if task.isMedsTask { return Color.cyan }
        if task.isBathroomTask { return Color(red: 0.3, green: 0.75, blue: 1.0) }
        return Color(red: 1.0, green: 0.78, blue: 0.2) // Morning Sun Gold
    }
    
    private func weatherEmoji(isRaining: Bool, desc: String) -> String {
        if isRaining { return "🌧️" }
        let lower = desc.lowercased()
        if lower.contains("thunder") { return "⛈️" }
        if lower.contains("snow") { return "🌨️" }
        if lower.contains("fog") || lower.contains("mist") { return "🌫️" }
        if lower.contains("cloud") || lower.contains("overcast") { return "☁️" }
        return "☀️"
    }
}
