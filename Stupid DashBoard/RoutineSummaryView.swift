import SwiftUI

public struct RoutineSummaryView: View {
    public let session: RoutineSession
    public let onDismiss: () -> Void
    
    // Sort tasks from longest to shortest
    private var sortedRecords: [RoutineTaskRecord] {
        session.taskRecords.sorted(by: { $0.durationSeconds > $1.durationSeconds })
    }
    
    private var maxTaskDuration: TimeInterval {
        sortedRecords.first?.durationSeconds ?? 1.0
    }
    
    private var totalTrackedSeconds: TimeInterval {
        session.taskRecords.reduce(0) { $0 + $1.durationSeconds }
    }
    
    private var untrackedSeconds: TimeInterval {
        max(0, session.totalDurationSeconds - totalTrackedSeconds)
    }
    
    public init(session: RoutineSession, onDismiss: @escaping () -> Void) {
        self.session = session
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            // Dark Blur Background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: session.period == .morning ? "sun.max.fill" : "moon.stars.fill")
                            .foregroundColor(session.period == .morning ? .yellow : .cyan)
                            .font(.system(size: 36, weight: .bold))
                        
                        Text("\(session.period.rawValue.uppercased()) ROUTINE BREAKDOWN")
                            .font(.system(size: 38, weight: .heavy, design: .default))
                            .foregroundColor(.white)
                            .tracking(1)
                    }
                    
                    Text("\(formatTimeOnly(session.startTime))  →  \(formatTimeOnly(session.endTime ?? Date()))")
                        .font(.title3)
                        .foregroundColor(Color.white.opacity(0.75))
                }
                .padding(.top, 10)
                
                // Top Metric Cards Row
                HStack(spacing: 24) {
                    // Total Duration
                    metricCard(
                        title: "TOTAL ROUTINE TIME",
                        value: formatDuration(session.totalDurationSeconds),
                        icon: "stopwatch.fill",
                        color: session.period == .morning ? .orange : .indigo
                    )
                    
                    // Tasks Finished
                    metricCard(
                        title: "TASKS LOGGED",
                        value: "\(session.taskRecords.count)",
                        icon: "checklist.checked",
                        color: .green
                    )
                    
                    // Most Time Spent On
                    if let longest = session.longestTask {
                        let pct = Int(round((longest.durationSeconds / max(1, session.totalDurationSeconds)) * 100))
                        metricCard(
                            title: "MOST TIME SPENT ON",
                            value: "\(longest.title.uppercased())",
                            subtitle: "\(formatDuration(longest.durationSeconds)) (\(pct)%)",
                            icon: "flame.fill",
                            color: .red
                        )
                    } else {
                        metricCard(
                            title: "MOST TIME SPENT ON",
                            value: "None",
                            icon: "hourglass",
                            color: Color.white.opacity(0.40)
                        )
                    }
                }
                .frame(maxWidth: 1100)
                
                // Visual Progress / Bar Breakdown
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("WHERE YOUR TIME WENT")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.white.opacity(0.80))
                        
                        Spacer()
                        
                        Text("Ranked longest to shortest")
                            .font(.subheadline)
                            .foregroundColor(Color.white.opacity(0.65))
                    }
                    .padding(.horizontal, 4)
                    
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 12) {
                            if sortedRecords.isEmpty {
                                Text("No individual tasks were checked off during this routine.")
                                    .font(.title3)
                                    .foregroundColor(Color.white.opacity(0.75))
                                    .padding(.vertical, 40)
                                    .frame(maxWidth: .infinity)
                            } else {
                                ForEach(Array(sortedRecords.enumerated()), id: \.element.id) { index, record in
                                    taskBreakdownRow(rank: index + 1, record: record)
                                }
                                
                                if untrackedSeconds > 15 {
                                    transitionTimeRow(seconds: untrackedSeconds)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                    }
                    .frame(maxHeight: 340)
                }
                .padding(24)
                .background(Color.white.opacity(0.04))
                .cornerRadius(20)
                .frame(maxWidth: 1100)
                
                // Dismiss Button & Sync Status
                HStack(spacing: 30) {
                    Button(action: onDismiss) {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark")
                            Text("Done")
                                .foregroundColor(.white)
                        }
                        .font(.headline)
                        .frame(minWidth: 220)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom, 10)
            }
            .padding(40)
        }
    }
    
    // MARK: - Metric Card Component
    private func metricCard(title: String, value: String, subtitle: String? = nil, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color.white.opacity(0.75))
                .tracking(1)
            
            Text(value)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(color.opacity(0.3), lineWidth: 1.5)
        )
    }
    
    // MARK: - Task Breakdown Row Component
    private func taskBreakdownRow(rank: Int, record: RoutineTaskRecord) -> some View {
        let totalRoutine = max(1.0, session.totalDurationSeconds)
        let percentOfTotal = record.durationSeconds / totalRoutine
        let relativeRatio = record.durationSeconds / max(1.0, maxTaskDuration)
        let pctInt = Int(round(percentOfTotal * 100))
        
        let barColor: Color = {
            switch rank {
            case 1: return .red
            case 2: return .orange
            case 3: return .yellow
            case 4: return .cyan
            default: return .blue
            }
        }()
        
        return HStack(spacing: 16) {
            // Rank Badge
            Text("#\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.white.opacity(0.70))
                .frame(width: 38, alignment: .leading)
            
            // Task Title
            Text(record.title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 170, alignment: .leading)
                .lineLimit(1)
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 18)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [barColor.opacity(0.8), barColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(18, geo.size.width * CGFloat(relativeRatio)), height: 18)
                }
            }
            .frame(height: 18)
            
            // Percentage
            Text("\(pctInt)%")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.white.opacity(0.75))
                .frame(width: 55, alignment: .trailing)
            
            // Duration
            Text(formatDuration(record.durationSeconds))
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.heavy)
                .foregroundColor(.white)
                .frame(width: 110, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(Color.white.opacity(0.02))
        .cornerRadius(12)
    }
    
    // MARK: - Transition / Wrap-up Row
    private func transitionTimeRow(seconds: TimeInterval) -> some View {
        let totalRoutine = max(1.0, session.totalDurationSeconds)
        let percentOfTotal = seconds / totalRoutine
        let pctInt = Int(round(percentOfTotal * 100))
        
        return HStack(spacing: 16) {
            Image(systemName: "arrow.triangle.swap")
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.60))
                .frame(width: 38, alignment: .leading)
            
            Text("Transitions / Wrap-up")
                .font(.body)
                .foregroundColor(Color.white.opacity(0.75))
                .frame(width: 170, alignment: .leading)
                .lineLimit(1)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 14)
                    
                    Capsule()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: max(14, geo.size.width * CGFloat(seconds / max(1.0, maxTaskDuration))), height: 14)
                }
            }
            .frame(height: 14)
            
            Text("\(pctInt)%")
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.65))
                .frame(width: 55, alignment: .trailing)
            
            Text(formatDuration(seconds))
                .font(.system(.body, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.75))
                .frame(width: 110, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 14)
    }
    
    // MARK: - Formatters
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(round(seconds)))
        let mins = total / 60
        let secs = total % 60
        if mins > 0 {
            return "\(mins)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
    
    private func formatTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
