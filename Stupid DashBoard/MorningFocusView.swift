import SwiftUI

public struct MorningFocusView: View {
    @Bindable var appState: AppState
    public let onOpenMeds: () -> Void
    
    // Focus Control for Apple TV Siri Remote
    private enum FocusButton: Hashable {
        case modeSelect(MorningRoutineMode)
        case primaryAction
        case secondaryAction
        case exitDashboard
        case bathroomSubtask(String)
        case completionDone
        case completionRunway
        case dismissOmeprazole
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
            // Obsidian Deep Midnight Backdrop
            Color(red: 0.05, green: 0.05, blue: 0.07)
                .ignoresSafeArea()
            
            // Mode-specific Ambient Aura
            RadialGradient(
                gradient: Gradient(colors: [
                    modeAmbientAuraColor.opacity(0.34),
                    Color(white: 0.05).opacity(0.15),
                    Color(red: 0.03, green: 0.03, blue: 0.04)
                ]),
                center: .topLeading,
                startRadius: 80,
                endRadius: 960
            )
            .ignoresSafeArea()
            
            if let task = currentTask {
                VStack(spacing: 0) {
                    // Top Header Bar
                    topHeaderBar
                        .padding(.horizontal, 60)
                        .padding(.top, 32)
                        .padding(.bottom, 16)
                    
                    // Persistent Omeprazole Timer Banner across all steps
                    if appState.isMedsTimerActive {
                        omeprazoleTimerBanner
                            .padding(.horizontal, 60)
                            .padding(.bottom, 12)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Single Focused Card (Center Stage)
                    Spacer()
                    
                    singleFocusCard(task: task)
                        .id(task.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    
                    Spacer()
                    
                    // Bottom Navigation & Remote Hints
                    bottomFooterHint
                        .padding(.bottom, 28)
                }
            } else {
                // All Morning Protocol Completed Celebration
                allCompletedCelebrationView
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: currentTask?.id)
        .animation(.easeInOut(duration: 0.3), value: appState.currentMorningMode)
        .animation(.easeInOut(duration: 0.3), value: appState.isMedsTimerActive)
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
    
    // MARK: - Ambient Aura Color
    private var modeAmbientAuraColor: Color {
        switch appState.currentMorningMode {
        case .full:
            return Color(red: 0.45, green: 0.25, blue: 0.05) // Warm Sunrise Amber
        case .express:
            return Color(red: 0.0, green: 0.30, blue: 0.45)  // Focused Cyan/Blue
        case .hitByTruck:
            return Color(red: 0.45, green: 0.12, blue: 0.18) // Emergency Triage Coral
        }
    }
    
    // MARK: - Top Header Bar
    private var topHeaderBar: some View {
        VStack(spacing: 18) {
            // Top Row: Clock, Step/Fuse HUD, Weather & Exit
            HStack(alignment: .center, spacing: 30) {
                // Live Clock & Date
                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.currentTime)
                        .font(.system(size: 70, weight: .bold, design: .default))
                        .tracking(-1.5)
                        .foregroundColor(.white)
                    
                    Text(appState.currentDateString)
                        .font(.title3)
                        .foregroundColor(Color.white.opacity(0.75))
                }
                
                Spacer()
                
                // Watchdog Launch Fuse HUD
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(modeAccentColor(appState.currentMorningMode))
                            .frame(width: 8, height: 8)
                        
                        Text(fuseStatusText.uppercased())
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .tracking(2.0)
                            .foregroundColor(modeAccentColor(appState.currentMorningMode))
                    }
                    
                    Text("STEP \(currentIndex + 1) OF \(totalTasksCount)")
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    
                    // Segmented Step Indicator
                    HStack(spacing: 6) {
                        ForEach(0..<totalTasksCount, id: \.self) { i in
                            Capsule()
                                .fill(
                                    i < currentIndex ? Color.green :
                                    (i == currentIndex ? modeAccentColor(appState.currentMorningMode) : Color.white.opacity(0.18))
                                )
                                .frame(width: i == currentIndex ? 26 : 10, height: 6)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.04))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(modeAccentColor(appState.currentMorningMode).opacity(0.25), lineWidth: 1)
                )
                
                Spacer()
                
                // Weather Summary & Dashboard Bypass
                HStack(spacing: 20) {
                    HStack(spacing: 12) {
                        Text(weatherEmoji(isRaining: appState.weather.isRaining, desc: appState.weather.conditionDescription))
                            .font(.system(size: 30))
                        
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
                            .foregroundColor(Color.white.opacity(0.65))
                            .padding(10)
                    }
                    .buttonStyle(.bordered)
                    .focused($focusedButton, equals: .exitDashboard)
                }
            }
            
            // Mode Switcher Bar (Apple TV Segmented Capsule Selector)
            modeSwitcherBar
        }
    }
    
    // MARK: - Mode Switcher Bar
    private var modeSwitcherBar: some View {
        HStack(spacing: 16) {
            ForEach(MorningRoutineMode.allCases) { mode in
                let isCurrent = appState.currentMorningMode == mode
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        appState.switchMorningMode(to: mode)
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: mode.iconName)
                            .font(.headline)
                        
                        Text(mode.rawValue)
                            .font(.headline)
                            .fontWeight(isCurrent ? .bold : .medium)
                        
                        Text("(\(mode.estimatedMinutes)m)")
                            .font(.subheadline)
                            .foregroundColor(isCurrent ? .white : Color.white.opacity(0.50))
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(
                        isCurrent ?
                            modeAccentColor(mode).opacity(0.24) :
                            Color.white.opacity(0.05)
                    )
                    .foregroundColor(isCurrent ? .white : Color.white.opacity(0.65))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isCurrent ? modeAccentColor(mode) : Color.white.opacity(0.12),
                                lineWidth: isCurrent ? 2 : 1
                            )
                    )
                }
                .buttonStyle(.plain)
                .focused($focusedButton, equals: .modeSelect(mode))
            }
        }
        .padding(.horizontal, 8)
    }
    
    // Total Fuse Status Text
    private var fuseStatusText: String {
        let remainingSecs = appState.modeTotalRemainingSeconds()
        let absSecs = Int(abs(remainingSecs))
        let mins = absSecs / 60
        let secs = absSecs % 60
        if remainingSecs >= 0 {
            return String(format: "FUSE: %02d:%02d REMAINING OF %02d:00", mins, secs, appState.currentMorningMode.estimatedMinutes)
        } else {
            return String(format: "FUSE: +%02d:%02d OVERTIME", mins, secs)
        }
    }
    
    // MARK: - Omeprazole Timer Persistent Banner
    private var omeprazoleTimerBanner: some View {
        let isWaitPhase = appState.isOmeprazoleWaitPhase
        let isWindowOpen = appState.isOmeprazoleEatingWindow
        
        let bannerAccent: Color = isWaitPhase ?
            Color(red: 1.0, green: 0.65, blue: 0.15) : // Warm Amber
            (isWindowOpen ? Color.green : Color.white.opacity(0.60))
        
        let iconName = isWaitPhase ? "hourglass.bottomhalf.filled" : (isWindowOpen ? "fork.knife" : "checkmark.seal.fill")
        
        let waitSecs = appState.omeprazoleWaitSecondsRemaining
        let waitMins = waitSecs / 60
        let waitRemainder = waitSecs % 60
        let countdownStr = String(format: "%02d:%02d", waitMins, waitRemainder)
        
        return HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(bannerAccent.opacity(0.20))
                    .frame(width: 48, height: 48)
                Image(systemName: iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(bannerAccent)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    if isWaitPhase {
                        Text("OMEPRAZOLE 30M LOCKOUT")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(bannerAccent)
                        
                        Text("\(countdownStr) REMAINING BEFORE FOOD")
                            .font(.system(size: 20, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                    } else if isWindowOpen {
                        Text("EATING WINDOW OPEN")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(bannerAccent)
                        
                        Text("\(appState.omeprazoleEatingWindowMinutesRemaining)M REMAINING TO FUEL")
                            .font(.system(size: 20, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                    } else {
                        Text("OMEPRAZOLE WINDOW CLOSED")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(Color.white.opacity(0.70))
                    }
                }
                
                HStack(spacing: 14) {
                    if let eatAfter = appState.eatAfterDate {
                        Text("Eat after: \(formatTime(eatAfter))")
                            .foregroundColor(Color.white.opacity(0.85))
                    }
                    if let eatBefore = appState.eatBeforeDate {
                        Text("•")
                            .foregroundColor(Color.white.opacity(0.35))
                        Text("Window closes: \(formatTime(eatBefore))")
                            .foregroundColor(Color.white.opacity(0.85))
                    }
                    if let taken = appState.medsTakenTimestamp {
                        Text("•")
                            .foregroundColor(Color.white.opacity(0.35))
                        Text("Taken at \(formatTime(taken))")
                            .foregroundColor(Color.white.opacity(0.60))
                    }
                }
                .font(.caption)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    appState.clearMedsTimer()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                    Text("Dismiss")
                }
                .font(.caption)
                .foregroundColor(Color.white.opacity(0.75))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .focused($focusedButton, equals: .dismissOmeprazole)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(bannerAccent.opacity(0.12))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(bannerAccent.opacity(0.38), lineWidth: 1.5)
        )
    }
    
    // MARK: - Single Focus Card
    private func singleFocusCard(task: MorningTask) -> some View {
        VStack(spacing: 24) {
            // Task Header: Icon + Title + Subtitle
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(taskAccentColor(task).opacity(0.18))
                        .frame(width: 82, height: 82)
                    
                    Image(systemName: task.iconName)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(taskAccentColor(task))
                }
                
                Text(task.title.uppercased())
                    .font(.system(size: 48, weight: .black))
                    .tracking(1.5)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                if let subtitle = task.subtitle {
                    Text(subtitle)
                        .font(.title3)
                        .foregroundColor(Color.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
            
            // Watchdog Relative Launch Countdown Stage Banner
            watchdogCountdownStageBanner(task: task)
            
            // Special Interactive / Triage Protocol Content
            if let triage = task.triageType {
                switch triage {
                case .breathingReset:
                    BreathingResetIllustrationView(onComplete: {
                        completeTaskAndAdvance(task)
                    })
                    .padding(.horizontal, 8)
                case .jawRelease:
                    JawSuboccipitalIllustrationView(onComplete: {
                        completeTaskAndAdvance(task)
                    })
                    .padding(.horizontal, 8)
                case .electrolyteHydration:
                    triageElectrolyteCard
                case .temperatureContrast:
                    triageTemperatureCard
                case .medsSafety:
                    triageMedsSafetyCard
                }
            } else if task.isBathroomTask {
                bathroomSubtasksRow(task: task)
            } else if task.isMedsTask {
                medsPreviewRow
            } else if task.isStretchingRoutine {
                guidedProtocolPreviewRow(tags: ["Low Lunge", "Wall Figure-4", "Puppy Pose", "Side Bend"])
            } else if task.isExerciseRoutine {
                guidedProtocolPreviewRow(tags: ["Pushups", "Air Squats", "Forearm Plank"])
            } else if task.isFootRoutine {
                guidedProtocolPreviewRow(tags: ["Plantar Fascia", "Straight Calf", "Bent Calf", "Calf Raises"])
            } else if task.title.localizedCaseInsensitiveContains("breakfast") {
                breakfastOmeprazoleCard
            }
            
            // Mode 2 Behavioral Safety Net Badge
            if appState.currentMorningMode == .express {
                HStack(spacing: 8) {
                    Image(systemName: "sun.haze.fill")
                        .foregroundColor(.orange)
                    Text("BEHAVIORAL SAFETY NET: Mobility & Foot Rehab relocated to 2:00 PM Afternoon Recharge on dashboard.")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.white.opacity(0.75))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(10)
            }
            
            // Primary Action Buttons
            actionButtons(task: task)
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 36)
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
                            taskAccentColor(task).opacity(0.45),
                            taskAccentColor(task).opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: taskAccentColor(task).opacity(0.10), radius: 36, x: 0, y: 12)
    }
    
    // MARK: - Watchdog Countdown Stage Banner
    private func watchdogCountdownStageBanner(task: MorningTask) -> some View {
        let remainingSecs = appState.activeTaskRemainingSeconds()
        let isOvertime = remainingSecs < 0
        let absSecs = Int(abs(remainingSecs))
        let mins = absSecs / 60
        let secs = absSecs % 60
        let allottedMinutes = task.durationMinutes ?? 5
        let allottedSecs = Double(allottedMinutes * 60)
        let elapsedSecs = allottedSecs - remainingSecs
        let progress = min(1.0, max(0.0, elapsedSecs / allottedSecs))
        
        let bannerColor: Color = isOvertime ?
            Color(red: 1.0, green: 0.65, blue: 0.15) : // Warm Amber (Never harsh red)
            taskAccentColor(task)
        
        return HStack(spacing: 28) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ALLOTTED WINDOW")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(Color.white.opacity(0.60))
                
                Text("\(allottedMinutes) MINUTES")
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Divider()
                .frame(height: 44)
                .background(Color.white.opacity(0.15))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(isOvertime ? "STATUS: OVERTIME" : "WATCHDOG LAUNCH FUSE")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(bannerColor)
                
                Text(isOvertime ? String(format: "+%02d:%02d OVERTIME", mins, secs) : String(format: "%02d:%02d REMAINING", mins, secs))
                    .font(.system(size: 32, weight: .black, design: .monospaced))
                    .foregroundColor(bannerColor)
            }
            
            Spacer()
            
            // Visual progress gauge
            VStack(alignment: .trailing, spacing: 6) {
                Text(isOvertime ? "Running over timeline" : "\(Int(progress * 100))% elapsed")
                    .font(.caption2)
                    .foregroundColor(Color.white.opacity(0.55))
                
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(bannerColor)
                    .frame(width: 160)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.04))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(bannerColor.opacity(0.35), lineWidth: 1.5)
        )
    }
    
    // MARK: - Breakfast Omeprazole Lockout / Eating Window Card
    @ViewBuilder
    private var breakfastOmeprazoleCard: some View {
        let isWaitPhase = appState.isOmeprazoleWaitPhase
        let isWindowOpen = appState.isOmeprazoleEatingWindow
        
        let waitSecs = appState.omeprazoleWaitSecondsRemaining
        let waitMins = waitSecs / 60
        let waitRemainder = waitSecs % 60
        let countdownStr = String(format: "%02d:%02d", waitMins, waitRemainder)
        
        if appState.isMedsTimerActive {
            if isWaitPhase {
                VStack(spacing: 12) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 1.0, green: 0.65, blue: 0.15).opacity(0.20))
                                .frame(width: 48, height: 48)
                            Image(systemName: "hourglass.bottomhalf.filled")
                                .foregroundColor(Color(red: 1.0, green: 0.65, blue: 0.15))
                                .font(.title3)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("OMEPRAZOLE 30-MINUTE LOCKOUT ACTIVE")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .tracking(1.5)
                                .foregroundColor(Color(red: 1.0, green: 0.65, blue: 0.15))
                            
                            Text("\(countdownStr) BEFORE EATING WINDOW OPENS")
                                .font(.system(size: 20, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(Color(red: 1.0, green: 0.65, blue: 0.15))
                            .font(.caption)
                        if let eatAfter = appState.eatAfterDate {
                            Text("Window opens at \(formatTime(eatAfter)). Wait for acid suppression to peak before consuming food.")
                                .font(.caption)
                                .foregroundColor(Color.white.opacity(0.85))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(red: 1.0, green: 0.65, blue: 0.15).opacity(0.12))
                    .cornerRadius(10)
                }
                .padding(18)
                .background(Color(red: 1.0, green: 0.65, blue: 0.15).opacity(0.08))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(red: 1.0, green: 0.65, blue: 0.15).opacity(0.35), lineWidth: 1.5)
                )
            } else if isWindowOpen {
                VStack(spacing: 12) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.20))
                                .frame(width: 48, height: 48)
                            Image(systemName: "fork.knife")
                                .foregroundColor(.green)
                                .font(.title3)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("OPTIMAL EATING WINDOW OPEN")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .tracking(1.5)
                                .foregroundColor(.green)
                            
                            Text("\(appState.omeprazoleEatingWindowMinutesRemaining)M REMAINING TO FUEL")
                                .font(.system(size: 20, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        if let eatBefore = appState.eatBeforeDate {
                            Text("Optimal PPI absorption achieved. Eating window closes at \(formatTime(eatBefore)). Enjoy breakfast!")
                                .font(.caption)
                                .foregroundColor(Color.white.opacity(0.85))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(10)
                }
                .padding(18)
                .background(Color.green.opacity(0.08))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.green.opacity(0.35), lineWidth: 1.5)
                )
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white.opacity(0.60))
                    Text("Omeprazole eating window completed.")
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.70))
                    Spacer()
                }
                .padding(14)
                .background(Color.white.opacity(0.05))
                .cornerRadius(14)
            }
        } else {
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.cyan)
                Text("Breakfast & Morning Hydration • Omeprazole requires a 30m fasting wait if taken today.")
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.80))
                Spacer()
            }
            .padding(14)
            .background(Color.white.opacity(0.05))
            .cornerRadius(14)
        }
    }
    
    // MARK: - Triage Electrolyte Card (Mode 3, Step 1)
    private var triageElectrolyteCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.20))
                        .frame(width: 44, height: 44)
                    Image(systemName: "drop.fill")
                        .foregroundColor(.cyan)
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("16–20 OZ SALINE / ELECTROLYTE REHYDRATION")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Drink 1 full tall glass of water + 1 electrolyte packet (LMNT / LiquidIV) or 1/4 tsp salt.")
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.75))
                }
                Spacer()
            }
            
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.cyan)
                    .font(.caption)
                Text("Why: Overnight hypovolemia reduces cerebral perfusion. Electrolytes expand plasma volume without causing cellular swelling.")
                    .font(.caption)
                    .foregroundColor(Color.cyan.opacity(0.90))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.cyan.opacity(0.10))
            .cornerRadius(10)
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Triage Temperature Contrast Card (Mode 3, Step 3)
    private var triageTemperatureCard: some View {
        HStack(spacing: 20) {
            // Cold Vasoconstriction on Temples
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "snowflake")
                        .foregroundColor(.cyan)
                    Text("TEMPLES: COLD")
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundColor(.cyan)
                }
                Text("Hold ice pack or cold washcloth against temples / forehead while brushing teeth. Constricts throbbing temporal arteries.")
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.75))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cyan.opacity(0.10))
            .cornerRadius(14)
            
            // Warm Vasodilation on Neck
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("NECK / TRAPS: WARM")
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundColor(.orange)
                }
                Text("Warm shower stream or heating pad directed at base of skull & upper traps. Relaxes tight occipital muscle guarding.")
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.75))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.10))
            .cornerRadius(14)
        }
    }
    
    // MARK: - Triage Meds Safety Card (Mode 3, Step 5)
    private var triageMedsSafetyCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("EMPTY STOMACH SAFETY ALERT")
                        .font(.headline)
                        .fontWeight(.black)
                        .foregroundColor(.yellow)
                    Text("AVOID Ibuprofen (Advil/Motrin) and Aleve on an empty stomach to prevent gastric mucosal damage.")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                Spacer()
            }
            
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Acetaminophen (Tylenol) 500-1000mg")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Text("•")
                    .foregroundColor(Color.white.opacity(0.40))
                
                HStack(spacing: 8) {
                    Image(systemName: "pills.fill")
                        .foregroundColor(.cyan)
                    Text("Omeprazole (acid control)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Text("•")
                    .foregroundColor(Color.white.opacity(0.40))
                
                HStack(spacing: 8) {
                    Image(systemName: "cup.and.saucer.fill")
                        .foregroundColor(.orange)
                    Text("Small espresso OK (vasoconstriction)")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.80))
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))
            .cornerRadius(10)
        }
        .padding(16)
        .background(Color.yellow.opacity(0.12))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.yellow.opacity(0.40), lineWidth: 1.5)
        )
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
        VStack(spacing: 10) {
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
            
            if appState.isMedsTimerActive {
                HStack(spacing: 8) {
                    Image(systemName: "hourglass.bottomhalf.filled")
                        .foregroundColor(Color(red: 1.0, green: 0.65, blue: 0.15))
                    let waitSecs = appState.omeprazoleWaitSecondsRemaining
                    let countdownStr = String(format: "%02d:%02d", waitSecs / 60, waitSecs % 60)
                    Text("Omeprazole logged • 30m eating lock active (\(countdownStr) remaining)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 1.0, green: 0.65, blue: 0.15))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(red: 1.0, green: 0.65, blue: 0.15).opacity(0.12))
                .cornerRadius(8)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "pills.fill")
                        .foregroundColor(.cyan)
                    Text("Taking Omeprazole with water arms a 30m eating lockout timer before breakfast")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.70))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
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
                // Standard task or Triage step
                Button(action: {
                    completeTaskAndAdvance(task)
                }) {
                    HStack(spacing: 14) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete & Next Step")
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
        .padding(.top, 4)
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
                Text("Play/Pause: Complete Step")
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
        VStack(spacing: 28) {
            Spacer()
            
            if appState.currentMorningMode == .hitByTruck {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 92))
                    .foregroundColor(Color(red: 1.0, green: 0.45, blue: 0.35))
                
                VStack(spacing: 10) {
                    Text("PHYSIOLOGICAL TRIAGE COMPLETE")
                        .font(.system(size: 44, weight: .black))
                        .tracking(2)
                        .foregroundColor(.white)
                    
                    Text("CO₂ cleared • Hydration restored • Cranial tension relaxed.")
                        .font(.title3)
                        .foregroundColor(Color.white.opacity(0.85))
                    
                    Text("Desk landing is ready in Runway Grounding (20 min low-cognitive review).")
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.65))
                }
                
                // Show Omeprazole lockout on celebration if still active
                celebrationOmeprazoleStatus
                
                HStack(spacing: 24) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            appState.launchGentleRunwayGrounding()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "pencil.and.outline")
                            Text("Launch Gentle Runway (20m)")
                        }
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 1.0, green: 0.45, blue: 0.35))
                    .focused($focusedButton, equals: .completionRunway)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            appState.isMorningFocusBypassed = true
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Enter Dashboard")
                        }
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.bordered)
                    .focused($focusedButton, equals: .completionDone)
                }
                
            } else {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 92))
                    .foregroundColor(.green)
                
                VStack(spacing: 10) {
                    Text("MORNING PROTOCOL COMPLETE!")
                        .font(.system(size: 48, weight: .black))
                        .tracking(2)
                        .foregroundColor(.white)
                    
                    Text("You've finished all \(totalTasksCount) habits with zero friction.")
                        .font(.title3)
                        .foregroundColor(Color.white.opacity(0.80))
                }
                
                // Show Omeprazole lockout on celebration if still active
                celebrationOmeprazoleStatus
                
                HStack(spacing: 24) {
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
                        .padding(.horizontal, 36)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .focused($focusedButton, equals: .completionDone)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            appState.isMorningFocusBypassed = true
                            appState.showWorkFocusScreen = true
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "timer")
                            Text("Start Work Sprint")
                        }
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.bordered)
                    .focused($focusedButton, equals: .completionRunway)
                }
            }
            
            Spacer()
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if appState.currentMorningMode == .hitByTruck {
                    focusedButton = .completionRunway
                } else {
                    focusedButton = .completionDone
                }
            }
        }
    }
    
    // MARK: - Celebration Omeprazole Status Banner
    @ViewBuilder
    private var celebrationOmeprazoleStatus: some View {
        if appState.isMedsTimerActive {
            let isWait = appState.isOmeprazoleWaitPhase
            let isWindowOpen = appState.isOmeprazoleEatingWindow
            let waitSecs = appState.omeprazoleWaitSecondsRemaining
            let countdownStr = String(format: "%02d:%02d", waitSecs / 60, waitSecs % 60)
            
            HStack(spacing: 14) {
                Image(systemName: isWait ? "hourglass.bottomhalf.filled" : (isWindowOpen ? "fork.knife" : "checkmark.circle.fill"))
                    .foregroundColor(isWait ? Color(red: 1.0, green: 0.65, blue: 0.15) : (isWindowOpen ? .green : .white))
                    .font(.title3)
                
                if isWait {
                    Text("Omeprazole Lockout: \(countdownStr) remaining before eating breakfast (Opens at \(formatTime(appState.eatAfterDate!)))")
                        .font(.headline)
                        .foregroundColor(.white)
                } else if isWindowOpen {
                    Text("Eating Window Open: Optimal absorption achieved! (\(appState.omeprazoleEatingWindowMinutesRemaining)m remaining)")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.08))
            .cornerRadius(14)
        }
    }
    
    // MARK: - Color & Style Helpers
    private func modeAccentColor(_ mode: MorningRoutineMode) -> Color {
        switch mode {
        case .full:
            return Color(red: 1.0, green: 0.78, blue: 0.2) // Morning Sun Gold
        case .express:
            return Color.cyan // Cyan
        case .hitByTruck:
            return Color(red: 1.0, green: 0.45, blue: 0.35) // Recovery Coral
        }
    }
    
    private func taskAccentColor(_ task: MorningTask) -> Color {
        if let triage = task.triageType {
            switch triage {
            case .electrolyteHydration: return Color.cyan
            case .breathingReset: return Color(red: 0.0, green: 0.92, blue: 1.0)
            case .temperatureContrast: return Color.orange
            case .jawRelease: return Color(red: 0.2, green: 0.85, blue: 0.9)
            case .medsSafety: return Color(red: 1.0, green: 0.45, blue: 0.35)
            }
        }
        if task.isFootRoutine { return Color.cyan }
        if task.isStretchingRoutine { return Color(red: 0.0, green: 0.92, blue: 1.0) }
        if task.isExerciseRoutine { return Color(red: 0.0, green: 0.92, blue: 1.0) }
        if task.isMedsTask { return Color.cyan }
        if task.isBathroomTask { return Color(red: 0.3, green: 0.75, blue: 1.0) }
        return modeAccentColor(appState.currentMorningMode)
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
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
