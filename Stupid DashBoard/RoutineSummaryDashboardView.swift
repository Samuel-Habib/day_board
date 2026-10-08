import SwiftUI

public struct WorkFocusView: View {
    @Bindable var appState: AppState
    public let onDismiss: () -> Void
    
    public enum SprintSelectionMode: String, CaseIterable, Identifiable {
        case directTask = "Direct Task"
        case runwayMode = "Runway Mode"
        
        public var id: String { rawValue }
    }
    
    @State private var selectionMode: SprintSelectionMode = .directTask
    @State private var selectedTaskId: UUID? = nil
    @State private var selectedRunwayBucket: RunwayBucket = .grounding
    @State private var showEarlyStopDialog: Bool = false
    
    private var uncompletedTasks: [DailyTask] {
        appState.dailyTasks.filter { !$0.isCompleted }
    }
    
    private var currentSprintTitle: String {
        switch selectionMode {
        case .directTask:
            if let id = selectedTaskId, let task = uncompletedTasks.first(where: { $0.id == id }) {
                return task.title
            } else if let first = uncompletedTasks.first {
                return first.title
            }
            return "Task Sprint"
        case .runwayMode:
            return selectedRunwayBucket.rawValue
        }
    }
    
    private func bucketIcon(_ bucket: RunwayBucket) -> String {
        switch bucket {
        case .grounding:
            return "pencil.and.outline"
        case .absorption:
            return "book.fill"
        case .technical:
            return "hammer.fill"
        }
    }
    
    private func startSprint() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch selectionMode {
            case .directTask:
                if let task = uncompletedTasks.first(where: { $0.id == selectedTaskId }) ?? uncompletedTasks.first {
                    appState.startWorkSession(
                        title: task.title,
                        project: "Daily Task",
                        runwayBucket: nil,
                        linkedTaskId: task.id
                    )
                } else {
                    appState.startWorkSession(
                        title: selectedRunwayBucket.rawValue,
                        project: selectedRunwayBucket.rawValue,
                        runwayBucket: selectedRunwayBucket,
                        linkedTaskId: nil
                    )
                }
            case .runwayMode:
                appState.startWorkSession(
                    title: selectedRunwayBucket.rawValue,
                    project: selectedRunwayBucket.rawValue,
                    runwayBucket: selectedRunwayBucket,
                    linkedTaskId: nil
                )
            }
        }
    }
    
    private func handleStopSprint() {
        guard let active = appState.activeWorkSession else { return }
        if active.durationSeconds >= 20 * 60 {
            withAnimation(.easeInOut(duration: 0.3)) {
                appState.stopWorkSession(exitReason: .completed)
            }
        } else {
            showEarlyStopDialog = true
        }
    }
    
    public init(appState: AppState, onDismiss: @escaping () -> Void) {
        self.appState = appState
        self.onDismiss = onDismiss
    }
    
    // Timeline calculation
    private var timelineStartHour: Double {
        let sessionHours = appState.todayWorkSessions.map { $0.startTime.hourFloat }
        let activeH = appState.activeWorkSession.map { $0.startTime.hourFloat }
        let allHours = sessionHours + (activeH != nil ? [activeH!] : [])
        let earlyHour = allHours.min() ?? 8.0
        return min(8.0, floor(earlyHour))
    }
    
    private var timelineEndHour: Double {
        let sessionHours = appState.todayWorkSessions.map { ($0.endTime ?? $0.startTime).hourFloat }
        let activeH = appState.activeWorkSession.map { $0.startTime.hourFloat }
        let nowH = appState.currentDate.hourFloat
        let allHours = sessionHours + (activeH != nil ? [activeH!] : []) + [nowH]
        let lateHour = allHours.max() ?? 22.0
        return max(22.0, ceil(lateHour))
    }
    
    private var totalTimelineHours: Double {
        max(1.0, timelineEndHour - timelineStartHour)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            HStack(alignment: .center, spacing: 24) {
                Button(action: onDismiss) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                        Text("Dashboard")
                            .foregroundColor(.white)
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                }
                .buttonStyle(.bordered)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 10) {
                        Image(systemName: "timer")
                            .foregroundColor(.indigo)
                            .font(.title)
                        
                        Text("WORK & FOCUS")
                            .font(.system(size: 38, weight: .black))
                            .foregroundColor(.white)
                            .tracking(1)
                    }
                    
                    Text("Focus timer & visual day timeline")
                        .font(.headline)
                        .foregroundColor(Color.white.opacity(0.75))
                }
                
                Spacer()
                
                // Live Clock & Date Badge
                HStack(spacing: 16) {
                    Text(appState.currentDateString)
                        .font(.headline)
                        .foregroundColor(Color.white.opacity(0.80))
                    
                    Text(appState.currentTime)
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.black)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
            }
            .padding(.bottom, 24)
            
            // Main Two Columns
            HStack(alignment: .top, spacing: 40) {
                // Left Column: Timer & Controls
                timerColumn
                    .frame(width: 720)
                    .focusSection()
                
                // Right Column: Calendar Day Timeline
                timelineColumn
                    .frame(maxWidth: .infinity)
                    .focusSection()
            }
        }
        .padding(.horizontal, 60)
        .padding(.top, 40)
        .padding(.bottom, 40)
        .onExitCommand(perform: onDismiss)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            if let preset = appState.presetRunwayBucketForDesk {
                selectionMode = .runwayMode
                selectedRunwayBucket = preset
                appState.presetRunwayBucketForDesk = nil
            } else if uncompletedTasks.isEmpty {
                selectionMode = .runwayMode
            } else if selectedTaskId == nil {
                selectedTaskId = uncompletedTasks.first?.id
            }
            Task {
                await appState.fetchCloudData()
            }
        }
        .confirmationDialog(
            "Why is this sprint stopping?",
            isPresented: $showEarlyStopDialog,
            titleVisibility: .visible
        ) {
            Button("Completed Early") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    appState.stopWorkSession(exitReason: .completed)
                }
            }
            Button("Interrupted") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    appState.stopWorkSession(exitReason: .interrupted)
                }
            }
            Button("Headache / Rest") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    appState.stopWorkSession(exitReason: .fatigueHeadache)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This sprint was under 20 minutes.")
        }
    }
    
    // MARK: - Timer Column (Left)
    private var timerColumn: some View {
        VStack(spacing: 20) {
            // Main Focus Timer Card
            VStack(spacing: 20) {
                if let active = appState.activeWorkSession {
                    // Active Status Header
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 10, height: 10)
                            Text("ACTIVE SPRINT")
                                .font(.caption)
                                .fontWeight(.heavy)
                                .foregroundColor(.orange)
                                .tracking(1.5)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(8)
                        
                        if let bucket = active.runwayBucket {
                            HStack(spacing: 6) {
                                Image(systemName: bucketIcon(bucket))
                                Text(bucket.rawValue)
                            }
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.indigo)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.indigo.opacity(0.15))
                            .cornerRadius(8)
                        } else if active.linkedTaskId != nil {
                            HStack(spacing: 6) {
                                Image(systemName: "checklist")
                                Text("Task Sprint")
                            }
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.teal)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.teal.opacity(0.15))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        Text("Started at \(formatTime(active.startTime))")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.75))
                    }
                    
                    Text(active.title.uppercased())
                        .font(.system(size: 34, weight: .black))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if appState.isOvertimeSprint {
                        let cap = appState.overtimeCapSeconds
                        let elapsed = active.durationSeconds
                        let remaining = max(0, Int(cap - elapsed))
                        let remMins = remaining / 60
                        let remSecs = remaining % 60
                        HStack(spacing: 8) {
                            Image(systemName: "clock.badge.exclamationmark")
                                .foregroundColor(.orange)
                            Text("OVERTIME HARD CAP: \(String(format: "%02d:%02d", remMins, remSecs)) REMAINING")
                                .font(.caption)
                                .fontWeight(.black)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.18))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                        )
                    }
                    
                    // Giant Timer
                    Text(formatWorkElapsed(active))
                        .font(.system(size: 96, weight: .black, design: .monospaced))
                        .foregroundColor(.orange)
                        .padding(.vertical, 10)
                    
                    // Stop Button
                    Button(action: {
                        handleStopSprint()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "stop.fill")
                            Text("Stop & Save Sprint")
                        }
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    // Idle State
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.white.opacity(0.40))
                                .frame(width: 8, height: 8)
                            Text("READY TO FOCUS")
                                .font(.caption)
                                .fontWeight(.heavy)
                                .foregroundColor(Color.white.opacity(0.75))
                                .tracking(1.5)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(8)
                        
                        Spacer()
                    }
                    
                    // Mode Switcher: Direct Task vs Runway Mode
                    HStack(spacing: 14) {
                        Button(action: {
                            selectionMode = .directTask
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checklist")
                                Text("Direct Task")
                                    .foregroundColor(.white)
                            }
                            .font(.headline)
                            .fontWeight(selectionMode == .directTask ? .bold : .medium)
                        }
                        .buttonStyle(.bordered)
                        .tint(selectionMode == .directTask ? .indigo : .gray)
                        
                        Button(action: {
                            selectionMode = .runwayMode
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "airplane.takeoff")
                                Text("Runway Mode")
                                    .foregroundColor(.white)
                            }
                            .font(.headline)
                            .fontWeight(selectionMode == .runwayMode ? .bold : .medium)
                        }
                        .buttonStyle(.bordered)
                        .tint(selectionMode == .runwayMode ? .indigo : .gray)
                    }
                    
                    // Mode Selectors
                    if selectionMode == .directTask {
                        if uncompletedTasks.isEmpty {
                            VStack(spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("All daily tasks completed")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.white.opacity(0.80))
                                }
                                Text("Switch to Runway Mode for open-ended blocks.")
                                    .font(.caption)
                                    .foregroundColor(Color.white.opacity(0.70))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(12)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SELECT ACTIVE TASK")
                                    .font(.caption2)
                                    .fontWeight(.heavy)
                                    .foregroundColor(Color.white.opacity(0.75))
                                    .tracking(1)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(uncompletedTasks) { task in
                                            let isSelected = (selectedTaskId == task.id) || (selectedTaskId == nil && task.id == uncompletedTasks.first?.id)
                                            Button(action: {
                                                selectedTaskId = task.id
                                            }) {
                                                HStack(spacing: 8) {
                                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                        .foregroundColor(isSelected ? .indigo : Color.white.opacity(0.40))
                                                    Text(task.title)
                                                        .foregroundColor(.white)
                                                        .fontWeight(isSelected ? .bold : .regular)
                                                        .lineLimit(1)
                                                }
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                            }
                                            .buttonStyle(.bordered)
                                            .tint(isSelected ? .indigo : .gray)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SELECT RUNWAY BUCKET")
                                .font(.caption2)
                                .fontWeight(.heavy)
                                .foregroundColor(Color.white.opacity(0.75))
                                .tracking(1)
                            
                            HStack(spacing: 10) {
                                ForEach(RunwayBucket.allCases) { bucket in
                                    let isSelected = selectedRunwayBucket == bucket
                                    Button(action: {
                                        selectedRunwayBucket = bucket
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: bucketIcon(bucket))
                                            Text(bucket.rawValue)
                                                .fontWeight(isSelected ? .bold : .medium)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(isSelected ? .indigo : .gray)
                                }
                            }
                        }
                    }
                    
                    // Inactive Timer
                    Text("00:00")
                        .font(.system(size: 96, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.35))
                        .padding(.vertical, 10)
                    
                    // Start Button
                    Button(action: {
                        startSprint()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                            Text("Start \(currentSprintTitle)")
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
            }
            .padding(24)
            .background(Color.white.opacity(0.04))
            .cornerRadius(20)
            
            // Today's Stats Row
            HStack(spacing: 16) {
                statCard(
                    title: "TOTAL FOCUS TODAY",
                    value: formatDuration(appState.todayWorkDurationSeconds),
                    color: .indigo
                )
                
                statCard(
                    title: "SPRINTS DONE",
                    value: "\(appState.todayWorkSessions.count)",
                    color: .green
                )
                
                let longest = appState.todayWorkSessions.map(\.durationSeconds).max() ?? 0
                statCard(
                    title: "LONGEST SPRINT",
                    value: longest > 0 ? formatDuration(longest) : "--",
                    color: .orange
                )
            }
            
            // Today's Session History List
            VStack(alignment: .leading, spacing: 10) {
                Text("TODAY'S COMPLETED SPRINTS")
                    .font(.caption)
                    .fontWeight(.heavy)
                    .foregroundColor(Color.white.opacity(0.75))
                    .tracking(1.2)
                
                if appState.todayWorkSessions.isEmpty {
                    Text("No work sessions logged yet today. Press start above to begin your first sprint.")
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.75))
                        .padding(.vertical, 8)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(appState.todayWorkSessions) { session in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(session.title)
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        HStack(spacing: 8) {
                                            Text("\(formatTime(session.startTime)) – \(formatTime(session.endTime ?? session.startTime))")
                                                .font(.caption2)
                                                .foregroundColor(Color.white.opacity(0.75))
                                            
                                            if let reason = session.exitReason {
                                                Text(reason.rawValue)
                                                    .font(.system(size: 10, weight: .heavy))
                                                    .foregroundColor(reason == .completed ? .green : .orange)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background((reason == .completed ? Color.green : Color.orange).opacity(0.15))
                                                    .cornerRadius(4)
                                            }
                                            
                                            if let bucket = session.runwayBucket {
                                                Text(bucket.rawValue)
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.indigo)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.indigo.opacity(0.15))
                                                    .cornerRadius(4)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Text(formatDuration(session.durationSeconds))
                                        .font(.system(.subheadline, design: .monospaced))
                                        .fontWeight(.heavy)
                                        .foregroundColor(.indigo)
                                    
                                    Button(role: .destructive, action: {
                                        withAnimation {
                                            appState.deleteWorkSession(id: session.id)
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.borderless)
                                    .foregroundColor(Color.white.opacity(0.60))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.03))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .frame(maxHeight: 180)
                }
            }
            .padding(18)
            .background(Color.white.opacity(0.03))
            .cornerRadius(16)
            
            Spacer()
        }
    }
    
    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .fontWeight(.heavy)
                .foregroundColor(Color.white.opacity(0.75))
                .tracking(1)
            
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.04))
        .cornerRadius(14)
    }
    
    // MARK: - Timeline Block Layout Model
    struct TimelineBlock: Identifiable {
        let id: UUID
        let title: String
        let startTime: Date
        let endTime: Date
        let durationSeconds: TimeInterval
        let isActive: Bool
        let runwayBucket: RunwayBucket?
        let exitReason: SessionExitReason?
        let remoteEntryId: Int?
        let visualTopH: Double
        let visualBottomH: Double
        var col: Int = 0
        var numCols: Int = 1
    }
    
    private func computeTimelineBlocks(startH: Double, endH: Double, hourHeight: CGFloat) -> [TimelineBlock] {
        var raw: [TimelineBlock] = []
        let minBlockHeight: CGFloat = 38.0
        let minDurationHours: Double = Double(minBlockHeight / hourHeight)
        
        for session in appState.todayWorkSessions {
            // Guard against active sprint collision
            if let active = appState.activeWorkSession {
                if let rId = session.remoteEntryId, let activeRId = active.remoteEntryId, rId == activeRId {
                    continue
                }
                if abs(session.startTime.timeIntervalSince(active.startTime)) < 60 && session.title == active.title {
                    continue
                }
            }
            
            // Guard against duplicate completed blocks
            let isDuplicate = raw.contains { existing in
                if let r1 = existing.remoteEntryId, let r2 = session.remoteEntryId, r1 == r2 { return true }
                return abs(existing.startTime.timeIntervalSince(session.startTime)) < 45 && existing.title == session.title
            }
            if isDuplicate {
                continue
            }
            
            let sH = session.startTime.hourFloat
            let rawEnd = session.endTime ?? session.startTime.addingTimeInterval(max(60, session.durationSeconds))
            let rawEH = max(sH + 0.02, rawEnd.hourFloat)
            let visualEH = max(rawEH, sH + minDurationHours)
            
            raw.append(TimelineBlock(
                id: session.id,
                title: session.title,
                startTime: session.startTime,
                endTime: rawEnd,
                durationSeconds: session.durationSeconds,
                isActive: false,
                runwayBucket: session.runwayBucket,
                exitReason: session.exitReason,
                remoteEntryId: session.remoteEntryId,
                visualTopH: sH,
                visualBottomH: visualEH
            ))
        }
        
        if let active = appState.activeWorkSession {
            let now = appState.currentDate
            let sH = active.startTime.hourFloat
            let rawEH = max(sH + 0.02, now.hourFloat)
            let visualEH = max(rawEH, sH + minDurationHours)
            
            raw.append(TimelineBlock(
                id: active.id,
                title: active.title,
                startTime: active.startTime,
                endTime: now,
                durationSeconds: active.durationSeconds,
                isActive: true,
                runwayBucket: active.runwayBucket,
                exitReason: nil,
                remoteEntryId: active.remoteEntryId,
                visualTopH: sH,
                visualBottomH: visualEH
            ))
        }
        
        guard !raw.isEmpty else { return [] }
        
        // Sort by visualTopH ascending, visualBottomH descending
        raw.sort {
            if abs($0.visualTopH - $1.visualTopH) > 0.001 {
                return $0.visualTopH < $1.visualTopH
            }
            return $0.visualBottomH > $1.visualBottomH
        }
        
        // Assign each block to the lowest column index where it doesn't collide visually
        var columnEndTimes: [Double] = []
        var assigned: [TimelineBlock] = []
        
        for var block in raw {
            var placed = false
            for i in 0..<columnEndTimes.count {
                if columnEndTimes[i] <= block.visualTopH + 0.015 {
                    block.col = i
                    columnEndTimes[i] = block.visualBottomH
                    placed = true
                    break
                }
            }
            if !placed {
                block.col = columnEndTimes.count
                columnEndTimes.append(block.visualBottomH)
            }
            assigned.append(block)
        }
        
        // Compute total columns for overlapping visual clusters
        var result = assigned
        for i in 0..<result.count {
            let b1 = result[i]
            var maxCol = b1.col
            for j in 0..<result.count {
                let b2 = result[j]
                if max(b1.visualTopH, b2.visualTopH) < min(b1.visualBottomH, b2.visualBottomH) - 0.015 {
                    maxCol = max(maxCol, b2.col)
                }
            }
            result[i].numCols = max(1, maxCol + 1)
        }
        
        // Smooth clusters so mutually overlapping neighbors share equal column count
        for _ in 0..<3 {
            for i in 0..<result.count {
                for j in (i + 1)..<result.count {
                    if max(result[i].visualTopH, result[j].visualTopH) < min(result[i].visualBottomH, result[j].visualBottomH) - 0.015 {
                        let sharedMax = max(result[i].numCols, result[j].numCols)
                        result[i].numCols = sharedMax
                        result[j].numCols = sharedMax
                    }
                }
            }
        }
        
        return result
    }
    
    // MARK: - Idle Gap Visualization Model & Shape (Phase 3)
    struct DiagonalHatchPattern: Shape {
        var spacing: CGFloat = 14
        
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let start = -rect.height
            let end = rect.width + rect.height
            var x = start
            while x <= end {
                path.move(to: CGPoint(x: rect.minX + x, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.minX + x + rect.height, y: rect.maxY))
                x += spacing
            }
            return path
        }
    }
    
    struct TimelineIdleGap: Identifiable {
        let id = UUID()
        let startH: Double
        let endH: Double
        let durationSeconds: TimeInterval
    }
    
    private func computeIdleGaps(startH: Double, endH: Double) -> [TimelineIdleGap] {
        // 1. Gather all busy intervals from today's work sessions
        var busyIntervals: [(startH: Double, endH: Double)] = []
        
        for session in appState.todayWorkSessions {
            if let active = appState.activeWorkSession {
                if let rId = session.remoteEntryId, let activeRId = active.remoteEntryId, rId == activeRId {
                    continue
                }
                if abs(session.startTime.timeIntervalSince(active.startTime)) < 60 && session.title == active.title {
                    continue
                }
            }
            
            let sH = session.startTime.hourFloat
            let rawEnd = session.endTime ?? session.startTime.addingTimeInterval(max(60, session.durationSeconds))
            let eH = max(sH + 0.02, rawEnd.hourFloat)
            busyIntervals.append((startH: sH, endH: eH))
        }
        
        if let active = appState.activeWorkSession {
            let sH = active.startTime.hourFloat
            let nowH = max(sH + 0.02, appState.currentDate.hourFloat)
            busyIntervals.append((startH: sH, endH: nowH))
        }
        
        guard !busyIntervals.isEmpty else { return [] }
        
        busyIntervals.sort { $0.startH < $1.startH }
        
        // Merge overlapping or near-contiguous intervals (within 3 minutes / 0.05h)
        var merged: [(startH: Double, endH: Double)] = []
        for interval in busyIntervals {
            if let last = merged.last {
                if interval.startH <= last.endH + 0.05 {
                    merged[merged.count - 1].endH = max(last.endH, interval.endH)
                } else {
                    merged.append(interval)
                }
            } else {
                merged.append(interval)
            }
        }
        
        var gaps: [TimelineIdleGap] = []
        let minGapHours: Double = 0.75 // 45 minutes
        
        // Gaps between consecutive merged intervals
        if merged.count >= 2 {
            for i in 0..<(merged.count - 1) {
                let gapStart = merged[i].endH
                let gapEnd = merged[i + 1].startH
                let durationHours = gapEnd - gapStart
                if durationHours >= minGapHours {
                    gaps.append(TimelineIdleGap(
                        startH: gapStart,
                        endH: gapEnd,
                        durationSeconds: durationHours * 3600
                    ))
                }
            }
        }
        
        // Gap after the last completed session until current time (if no active session running)
        if let lastMerged = merged.last {
            let nowH = appState.currentDate.hourFloat
            let capEnd = min(endH, nowH)
            if appState.activeWorkSession == nil && capEnd - lastMerged.endH >= minGapHours {
                let durationHours = capEnd - lastMerged.endH
                gaps.append(TimelineIdleGap(
                    startH: lastMerged.endH,
                    endH: capEnd,
                    durationSeconds: durationHours * 3600
                ))
            }
        }
        
        return gaps
    }
    
    // MARK: - Day Calendar Timeline Column (Right)
    private var timelineColumn: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DAY TIMELINE")
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(Color.white.opacity(0.80))
                        .tracking(1.2)
                    
                    Text("Visual 24-hour map of your work hours today")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.65))
                }
                
                Spacer()
                
                HStack(spacing: 14) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.indigo)
                            .frame(width: 8, height: 8)
                        Text("Completed")
                            .font(.caption2)
                            .foregroundColor(Color.white.opacity(0.75))
                    }
                    
                    if appState.activeWorkSession != nil {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                            Text("Active")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                            .foregroundColor(Color.white.opacity(0.40))
                            .background(Color.white.opacity(0.08))
                            .frame(width: 10, height: 10)
                        Text("Idle (≥45m)")
                            .font(.caption2)
                            .foregroundColor(Color.white.opacity(0.75))
                    }
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("Now: \(formatTime24(appState.currentDate))")
                            .font(.system(.caption2, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal, 4)
            
            // Timeline Box
            let timelineHeight: CGFloat = 680
            let startH = timelineStartHour
            let endH = timelineEndHour
            let totalHours = max(1.0, endH - startH)
            let hourHeight = timelineHeight / CGFloat(totalHours)
            let leftGutterWidth: CGFloat = 52
            let contentLeft: CGFloat = 66
            let blocks = computeTimelineBlocks(startH: startH, endH: endH, hourHeight: hourHeight)
            let idleGaps = computeIdleGaps(startH: startH, endH: endH)
            
            GeometryReader { geo in
                let availableWidth = max(200, geo.size.width - contentLeft - 8)
                
                ZStack(alignment: .topLeading) {
                    // Layer 1: 24-Hour Grid Lines & Labels
                    ForEach(Int(startH)...Int(endH), id: \.self) { hour in
                        let y = CGFloat(Double(hour) - startH) * hourHeight
                        
                        HStack(spacing: 10) {
                            Text(formatHour24(hour))
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.65))
                                .frame(width: leftGutterWidth, alignment: .trailing)
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 1)
                        }
                        .offset(y: y - 8)
                    }
                    
                    // Empty state if no blocks exist
                    if blocks.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 36))
                                .foregroundColor(Color.white.opacity(0.35))
                            Text("No work blocks logged today yet")
                                .font(.headline)
                                .foregroundColor(Color.white.opacity(0.75))
                            Text("Start a sprint on the left to map your work hours")
                                .font(.caption)
                                .foregroundColor(Color.white.opacity(0.55))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(x: contentLeft / 2)
                    }
                    
                    // Layer 1.5: Idle Gaps (>= 45 min)
                    ForEach(idleGaps) { gap in
                        if gap.endH > startH && gap.startH < endH {
                            let clampedStart = max(startH, gap.startH)
                            let clampedEnd = min(endH, gap.endH)
                            let gapY = CGFloat(clampedStart - startH) * hourHeight
                            let gapH = CGFloat(clampedEnd - clampedStart) * hourHeight
                            
                            idleGapView(gap: gap)
                                .frame(width: availableWidth, height: gapH)
                                .offset(x: contentLeft, y: gapY)
                        }
                    }
                    
                    // Layer 2: Side-by-Side Non-Overlapping Work Blocks
                    ForEach(blocks) { block in
                        if block.visualBottomH > startH && block.visualTopH < endH {
                            let clampedStart = max(startH, block.visualTopH)
                            let clampedEnd = min(endH, block.visualBottomH)
                            let blockY = CGFloat(clampedStart - startH) * hourHeight
                            let blockH = max(38.0, CGFloat(clampedEnd - clampedStart) * hourHeight)
                            
                            let totalCols = CGFloat(block.numCols)
                            let gapBetweenCols: CGFloat = 6
                            let colWidth = max(60, (availableWidth - (totalCols - 1) * gapBetweenCols) / totalCols)
                            let blockX = contentLeft + CGFloat(block.col) * (colWidth + gapBetweenCols)
                            
                            workBlockView(block: block)
                                .frame(width: colWidth, height: blockH)
                                .offset(x: blockX, y: blockY)
                        }
                    }
                    
                    // Layer 3: Live "NOW" Line
                    let nowH = appState.currentDate.hourFloat
                    if nowH >= startH && nowH <= endH {
                        let nowY = CGFloat(nowH - startH) * hourHeight
                        
                        HStack(spacing: 0) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            
                            Rectangle()
                                .fill(Color.red.opacity(0.9))
                                .frame(height: 2)
                        }
                        .offset(x: contentLeft - 4, y: nowY - 4)
                    }
                }
            }
            .frame(height: timelineHeight)
            .padding(16)
            .background(Color.white.opacity(0.025))
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Idle Gap View (Layer 1.5)
    private func idleGapView(gap: TimelineIdleGap) -> some View {
        ZStack {
            // Subtle background fill
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.04))
            
            // Diagonal hatched lines
            DiagonalHatchPattern(spacing: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Dashed border
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundColor(Color.white.opacity(0.18))
            
            // Centered badge
            HStack(spacing: 6) {
                Image(systemName: "pause.circle")
                    .font(.system(size: 10, weight: .semibold))
                Text("Idle / Open: \(formatCompactDuration(gap.durationSeconds))")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            .foregroundColor(Color.white.opacity(0.85))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.65))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
        }
        .clipped()
    }
    
    private func workBlockView(block: TimelineBlock) -> some View {
        HStack(spacing: 8) {
            // Accent color bar on left edge
            RoundedRectangle(cornerRadius: 2)
                .fill(block.isActive ? Color.orange : Color.indigo)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                // Top row: Title + active badge or bucket icon
                HStack(spacing: 6) {
                    Text(block.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if block.isActive {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 5, height: 5)
                            Text("ACTIVE")
                                .font(.system(size: 9, weight: .black))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(3)
                    }
                    
                    if let bucket = block.runwayBucket {
                        Image(systemName: bucketIcon(bucket))
                            .font(.system(size: 11))
                            .foregroundColor(.indigo)
                    }
                    
                    Spacer(minLength: 0)
                }
                
                // Bottom row: 24-Hour Range & Duration
                HStack(spacing: 5) {
                    Text("\(formatTime24(block.startTime))–\(formatTime24(block.endTime))")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.75))
                        .lineLimit(1)
                    
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(Color.white.opacity(0.40))
                    
                    Text(formatCompactDuration(block.durationSeconds))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(block.isActive ? .orange : .indigo)
                        .lineLimit(1)
                }
            }
            .padding(.trailing, 4)
        }
        .padding(.leading, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            block.isActive
                ? LinearGradient(colors: [Color.orange.opacity(0.24), Color.orange.opacity(0.10)], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(colors: [Color.indigo.opacity(0.30), Color.blue.opacity(0.12)], startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(block.isActive ? Color.orange.opacity(0.7) : Color.indigo.opacity(0.35), lineWidth: 1)
        )
        .clipped()
    }
    
    // MARK: - Formatters
    private func formatHour24(_ hour: Int) -> String {
        let h = (hour % 24 + 24) % 24
        return String(format: "%02d:00", h)
    }
    
    private func formatTime24(_ date: Date) -> String {
        let cal = Calendar.current
        let h = cal.component(.hour, from: date)
        let m = cal.component(.minute, from: date)
        return String(format: "%02d:%02d", h, m)
    }
    
    private func formatTime(_ date: Date) -> String {
        return formatTime24(date)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(round(seconds)))
        let hrs = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        if hrs > 0 {
            return "\(hrs)h \(mins)m"
        } else if mins > 0 {
            return "\(mins)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
    
    private func formatCompactDuration(_ seconds: TimeInterval) -> String {
        let total = max(1, Int(round(seconds)))
        let hrs = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        if hrs > 0 {
            return "\(hrs)h \(mins)m"
        } else if mins > 0 {
            return "\(mins)m"
        } else {
            return "\(secs)s"
        }
    }
    
    private func formatWorkElapsed(_ session: WorkSession) -> String {
        let elapsed = max(0, Int(appState.currentDate.timeIntervalSince(session.startTime)))
        let hrs = elapsed / 3600
        let mins = (elapsed % 3600) / 60
        let secs = elapsed % 60
        if hrs > 0 {
            return String(format: "%02d:%02d:%02d", hrs, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }
}

// Backward compatibility aliases
public typealias RoutineSummaryDashboardView = WorkFocusView
public typealias RoutineResultsDashboardView = WorkFocusView

extension Date {
    public var hourFloat: Double {
        let cal = Calendar.current
        let h = Double(cal.component(.hour, from: self))
        let m = Double(cal.component(.minute, from: self))
        let s = Double(cal.component(.second, from: self))
        return h + (m / 60.0) + (s / 3600.0)
    }
}
