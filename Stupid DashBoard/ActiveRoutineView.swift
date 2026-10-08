import SwiftUI

public struct ActiveRoutineView: View {
    @Bindable var appState: AppState
    let onMinimize: () -> Void
    let onStop: () -> Void
    
    private var session: RoutineSession? {
        appState.activeRoutineSession
    }
    
    private var period: HabitPeriod {
        session?.period ?? .morning
    }
    
    private var activeTasks: [MorningTask] {
        appState.morningTasks
    }
    
    private var activeNightTasks: [NightTask] {
        appState.nightTasks
    }
    
    // Elapsed time for the whole routine
    private var totalElapsedString: String {
        guard let s = session else { return "00:00" }
        let total = max(0, Int(appState.currentDate.timeIntervalSince(s.startTime)))
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    // First uncompleted task as the current focus
    private var currentFocusTaskTitle: String? {
        if period == .morning {
            return appState.morningTasks.first(where: { !$0.isCompleted })?.title
        } else {
            return appState.nightTasks.first(where: { !$0.isCompleted })?.title
        }
    }
    
    private var currentFocusTaskId: UUID? {
        if period == .morning {
            return appState.morningTasks.first(where: { !$0.isCompleted })?.id
        } else {
            return appState.nightTasks.first(where: { !$0.isCompleted })?.id
        }
    }
    
    // Elapsed time for current task
    private var currentTaskElapsedString: String {
        guard let milestone = appState.lastMilestoneTime else { return "00:00" }
        let elapsed = max(0, Int(appState.currentDate.timeIntervalSince(milestone)))
        let mins = elapsed / 60
        let secs = elapsed % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private var completedCount: Int {
        if period == .morning {
            return appState.morningTasks.filter({ $0.isCompleted }).count
        } else {
            return appState.nightTasks.filter({ $0.isCompleted }).count
        }
    }
    
    private var totalCount: Int {
        if period == .morning {
            return appState.morningTasks.count
        } else {
            return appState.nightTasks.count
        }
    }
    
    public init(appState: AppState, onMinimize: @escaping () -> Void, onStop: @escaping () -> Void) {
        self.appState = appState
        self.onMinimize = onMinimize
        self.onStop = onStop
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Header: Giant Live Routine Stopwatch & Time Status
            HStack(alignment: .center, spacing: 40) {
                // Giant Routine Stopwatch
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: period == .morning ? "sun.max.fill" : "moon.stars.fill")
                            .foregroundColor(period == .morning ? .yellow : .cyan)
                            .font(.title2)
                        
                        Text("\(period.rawValue.uppercased()) ROUTINE")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.white.opacity(0.75))
                            .tracking(2)
                    }
                    
                    Text(totalElapsedString)
                        .font(.system(size: 116, weight: .black, design: .monospaced))
                        .tracking(-2)
                        .foregroundColor(period == .morning ? Color(red: 1.0, green: 0.75, blue: 0.2) : Color(red: 0.4, green: 0.7, blue: 1.0))
                    
                    if let s = session {
                        Text("Started at \(formatTime(s.startTime))  •  \(completedCount) of \(totalCount) habits completed")
                            .font(.title3)
                            .foregroundColor(Color.white.opacity(0.80))
                    }
                }
                
                Spacer()
                
                // Right Side: Current Clock & Controls
                VStack(alignment: .trailing, spacing: 16) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(appState.currentTime)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        Text(appState.currentDateString)
                            .font(.title3)
                            .foregroundColor(Color.white.opacity(0.80))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(14)
                    
                    HStack(spacing: 16) {
                        Button(action: onMinimize) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.down.right.and.arrow.up.left")
                                Text("Dashboard")
                                    .foregroundColor(.white)
                            }
                            .font(.headline)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: onStop) {
                            HStack(spacing: 8) {
                                Image(systemName: "stop.fill")
                                Text("Finish Routine")
                                    .foregroundColor(.white)
                            }
                            .font(.headline)
                            .fontWeight(.bold)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
            }
            .padding(.bottom, 24)
            
            // Current Focus Task Spotlight Banner
            if let focusTitle = currentFocusTaskTitle, let focusId = currentFocusTaskId {
                HStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill((period == .morning ? Color.yellow : Color.cyan).opacity(0.2))
                            .frame(width: 58, height: 58)
                        Image(systemName: "timer")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(period == .morning ? .yellow : .cyan)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CURRENT TASK")
                            .font(.caption)
                            .fontWeight(.heavy)
                            .foregroundColor(Color.white.opacity(0.75))
                            .tracking(1.5)
                        
                        Text(focusTitle.uppercased())
                            .font(.title)
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("TIME ON THIS TASK")
                            .font(.caption)
                            .fontWeight(.heavy)
                            .foregroundColor(Color.white.opacity(0.75))
                            .tracking(1)
                        
                        Text(currentTaskElapsedString)
                            .font(.system(size: 34, weight: .black, design: .monospaced))
                            .foregroundColor(period == .morning ? .yellow : .cyan)
                    }
                    
                    Button(action: {
                        if period == .morning {
                            if let task = appState.morningTasks.first(where: { $0.id == focusId }) {
                                appState.toggleMorningTask(task)
                                appState.recordTaskCompletion(period: .morning, taskId: task.id, taskTitle: task.title)
                            }
                        } else {
                            if let task = appState.nightTasks.first(where: { $0.id == focusId }) {
                                appState.toggleNightTask(task)
                                appState.recordTaskCompletion(period: .night, taskId: task.id, taskTitle: task.title)
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                            Text("Complete & Next")
                                .foregroundColor(.white)
                        }
                        .font(.headline)
                        .fontWeight(.bold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.04))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke((period == .morning ? Color.yellow : Color.cyan).opacity(0.35), lineWidth: 1.5)
                )
                .padding(.bottom, 24)
            } else {
                // All Tasks Completed Banner
                HStack(spacing: 20) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ALL ROUTINE TASKS FINISHED!")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundColor(.green)
                        Text("Click Finish Routine to view your time breakdown summary.")
                            .font(.body)
                            .foregroundColor(Color.white.opacity(0.75))
                    }
                    
                    Spacer()
                    
                    Button(action: onStop) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.bar.xaxis")
                            Text("View Time Breakdown")
                                .foregroundColor(.white)
                        }
                        .font(.headline)
                        .fontWeight(.bold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.green.opacity(0.12))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.green.opacity(0.4), lineWidth: 1.5)
                )
                .padding(.bottom, 24)
            }
            
            // The Habit Cards Grid
            ScrollView(.vertical, showsIndicators: false) {
                if period == .morning {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 24), count: 4), spacing: 24) {
                        ForEach(Array(appState.morningTasks.enumerated()), id: \.element.id) { index, task in
                            routineTaskCard(
                                index: index + 1,
                                title: task.title,
                                isCompleted: task.isCompleted,
                                isCurrent: currentFocusTaskId == task.id,
                                duration: appState.recordedDuration(for: task.id)
                            ) {
                                let willBeCompleted = !task.isCompleted
                                appState.toggleMorningTask(task)
                                if willBeCompleted {
                                    appState.recordTaskCompletion(period: .morning, taskId: task.id, taskTitle: task.title)
                                } else {
                                    appState.recordTaskUncompleted(period: .morning, taskId: task.id)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 24), count: 4), spacing: 24) {
                        ForEach(Array(appState.nightTasks.enumerated()), id: \.element.id) { index, task in
                            routineTaskCard(
                                index: index + 1,
                                title: task.title,
                                isCompleted: task.isCompleted,
                                isCurrent: currentFocusTaskId == task.id,
                                duration: appState.recordedDuration(for: task.id)
                            ) {
                                let willBeCompleted = !task.isCompleted
                                appState.toggleNightTask(task)
                                if willBeCompleted {
                                    appState.recordTaskCompletion(period: .night, taskId: task.id, taskTitle: task.title)
                                } else {
                                    appState.recordTaskUncompleted(period: .night, taskId: task.id)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(.horizontal, 60)
        .padding(.top, 40)
        .padding(.bottom, 50)
        .onExitCommand(perform: onMinimize)
    }
    
    // MARK: - Routine Task Card Component
    private func routineTaskCard(
        index: Int,
        title: String,
        isCompleted: Bool,
        isCurrent: Bool,
        duration: TimeInterval?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack {
                    Text("#\(index)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(isCurrent ? (period == .morning ? .yellow : .cyan) : Color.white.opacity(0.60))
                    
                    Spacer()
                    
                    if isCurrent && !isCompleted {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(period == .morning ? Color.yellow : Color.cyan)
                                .frame(width: 8, height: 8)
                            Text("CURRENT")
                                .font(.caption2)
                                .fontWeight(.heavy)
                                .foregroundColor(period == .morning ? .yellow : .cyan)
                        }
                    }
                }
                
                Spacer()
                
                Text(title.uppercased())
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundColor(isCompleted ? Color.white.opacity(0.55) : Color.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 34))
                    
                    if let dur = duration {
                        Text(formatDuration(dur))
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.heavy)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.18))
                            .cornerRadius(6)
                    }
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(Color.white.opacity(0.40))
                        .font(.system(size: 34))
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 165)
            .padding(14)
        }
        .buttonStyle(.card)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isCurrent && !isCompleted ? (period == .morning ? Color.yellow : Color.cyan) : Color.clear, lineWidth: 3)
        )
        .opacity(isCompleted ? 0.6 : 1.0)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = max(1, Int(round(seconds)))
        let mins = total / 60
        let secs = total % 60
        if mins > 0 {
            return "\(mins)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
