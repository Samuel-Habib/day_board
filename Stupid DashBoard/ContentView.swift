import SwiftUI
import Combine

public struct ContentView: View {
    @State private var appState = AppState()
    @State private var showSettings = false
    @State private var showAddDailyAlert = false
    @State private var newDailyTitle = ""
    @Environment(\.scenePhase) private var scenePhase
    
    // Omeprazole / Meds Timer State
    @AppStorage("medsTakenTimestamp") private var medsTakenTimestamp: Double = 0
    
    // Meds Checklist Modal Overlay State
    @State private var showMedsOverlay: Bool = false
    @State private var medsOverlayPeriod: HabitPeriod = .morning
    @State private var medsOverlayTaskId: UUID? = nil
    
    // Habit Period (Morning / Night)
    @State private var selectedHabitPeriod: HabitPeriod = .morning
    
    // Deliberate 10 PM Gate Focus
    private enum NightGateFocus: Hashable {
        case nightRoutine
        case overtime
    }
    @FocusState private var nightGateFocus: NightGateFocus?
    
    private let initialPreview10PM: Bool
    
    public init(preview10PM: Bool = false) {
        self.initialPreview10PM = preview10PM
    }
    
    public var body: some View {
        ZStack {
            if appState.is10PMNightModeActive {
                tenPMNightView
                    .transition(.opacity)
            } else if appState.showFootRoutineScreen {
                FootRoutineView(
                    appState: appState,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            appState.showFootRoutineScreen = false
                        }
                    }
                )
                .transition(.opacity)
            } else if appState.showStretchingRoutineScreen {
                StretchingRoutineView(
                    appState: appState,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            appState.showStretchingRoutineScreen = false
                        }
                    }
                )
                .transition(.opacity)
            } else if appState.showExerciseRoutineScreen {
                BodyweightExerciseRoutineView(
                    appState: appState,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            appState.showExerciseRoutineScreen = false
                        }
                    }
                )
                .transition(.opacity)
            } else if appState.showWorkFocusScreen || appState.showRoutineResults {
                WorkFocusView(
                    appState: appState,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            appState.showWorkFocusScreen = false
                            appState.showRoutineResults = false
                        }
                    }
                )
                .transition(.opacity)
            } else if appState.isMorningFocusActive {
                MorningFocusView(
                    appState: appState,
                    onOpenMeds: {
                        medsOverlayPeriod = .morning
                        medsOverlayTaskId = appState.currentMorningTask?.id
                        showMedsOverlay = true
                    }
                )
                .blur(radius: showMedsOverlay ? 24 : 0)
                .transition(.opacity)
                .overlay {
                    if showMedsOverlay {
                        medsOverlayView
                    }
                }
            } else {
                dashboardView
                    .blur(radius: showMedsOverlay ? 24 : 0)
                    .transition(.opacity)
                    .overlay {
                        if showMedsOverlay {
                            medsOverlayView
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.is10PMNightModeActive)
        .animation(.easeInOut(duration: 0.4), value: appState.showWorkFocusScreen)
        .animation(.easeInOut(duration: 0.4), value: appState.showFootRoutineScreen)
        .animation(.easeInOut(duration: 0.4), value: appState.showStretchingRoutineScreen)
        .animation(.easeInOut(duration: 0.4), value: appState.showExerciseRoutineScreen)
        .animation(.easeInOut(duration: 0.4), value: appState.isMorningFocusActive)
        .animation(.easeInOut(duration: 0.28), value: showMedsOverlay)
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(appState: appState)
                .preferredColorScheme(.dark)
        }
        .alert("New Task for Today", isPresented: $showAddDailyAlert) {
            TextField("Task title", text: $newDailyTitle)
            Button("Add") {
                appState.addDailyTask(title: newDailyTitle)
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Overtime Cap Reached (30m)", isPresented: $appState.showOvertimeShutdownAlert) {
            Button("Start Night Routine") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    appState.showWorkFocusScreen = false
                    appState.showRoutineResults = false
                    selectedHabitPeriod = .night
                }
            }
        } message: {
            Text("Your 30-minute overtime sprint has ended. It is time to wind down and begin your night routine.")
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            appState.updateClock()
            appState.checkDayChange()
            let hour = Calendar.current.component(.hour, from: appState.currentDate)
            selectedHabitPeriod = (hour >= 18 || hour < 5) ? .night : .morning
            if initialPreview10PM {
                appState.trigger10PMNightModePreview()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                UIApplication.shared.isIdleTimerDisabled = true
                appState.updateClock()
                appState.checkDayChange()
                Task {
                    await appState.fetchWeather()
                    await appState.fetchCloudData()
                }
            }
        }
        .onChange(of: appState.is10PMNightModeActive) { _, isActive in
            if isActive {
                showSettings = false
                showAddDailyAlert = false
                nightGateFocus = .nightRoutine
            }
        }
    }
    
    // MARK: - Meds Overlay View
    private var medsOverlayView: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showMedsOverlay = false
                    }
                    checkAndUpdateMedsHabitTask()
                }
            
            MedsChecklistModalView(
                appState: appState,
                period: medsOverlayPeriod,
                onDismiss: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showMedsOverlay = false
                    }
                    checkAndUpdateMedsHabitTask()
                },
                onMedsUpdated: {
                    checkAndUpdateMedsHabitTask()
                }
            )
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
    }
    
    // MARK: - Dashboard Main View
    private var dashboardView: some View {
        VStack(spacing: 0) {
            // Header: Time, Date & Weather
            HStack(alignment: .center, spacing: 40) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(appState.currentTime)
                        .font(.system(size: 110, weight: .bold, design: .default))
                        .tracking(-2)
                        .foregroundColor(.white)
                    Text(appState.currentDateString)
                        .font(.title2)
                        .foregroundColor(Color.white.opacity(0.80))
                }
                
                Spacer()
                
                // Weather summary on the right side of header
                HStack(spacing: 30) {
                    if appState.isWeatherLoading && appState.weather.conditionDescription == "Clear" && appState.weather.uvIndex == 0.0 {
                        ProgressView()
                            .scaleEffect(1.5)
                    } else {
                        VStack(alignment: .trailing, spacing: 10) {
                            HStack(spacing: 15) {
                                Text(weatherEmoji(isRaining: appState.weather.isRaining, desc: appState.weather.conditionDescription))
                                    .font(.system(size: 48))
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(appState.weather.conditionDescription)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    Text("Rain: \(appState.weather.rainProbability)%")
                                        .font(.body)
                                        .foregroundColor(Color.white.opacity(0.75))
                                }
                            }
                            
                            HStack(spacing: 10) {
                                Text("UV Index:")
                                    .font(.body)
                                    .foregroundColor(Color.white.opacity(0.75))
                                Text("\(Int(round(appState.weather.uvIndex))) (\(uvSeverityText(for: appState.weather.uvIndex)))")
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundColor(uvColor(for: appState.weather.uvIndex))
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.03))
                .cornerRadius(16)
            }
            .padding(.bottom, 28)
            
            // Resume Morning Routine Banner (if habits are incomplete and user bypassed focus)
            if appState.hasActiveMorningRoutine && appState.isMorningFocusBypassed {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        appState.isMorningFocusBypassed = false
                    }
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "sun.max.fill")
                            .font(.title2)
                            .foregroundColor(Color(red: 1.0, green: 0.78, blue: 0.2))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MORNING ROUTINE IN PROGRESS")
                                .font(.caption)
                                .fontWeight(.black)
                                .tracking(2)
                                .foregroundColor(Color(red: 1.0, green: 0.78, blue: 0.2))
                            
                            if let task = appState.currentMorningTask {
                                Text("Resume: \(task.title.uppercased())  •  Step \(appState.currentMorningTaskIndex + 1) of \(appState.morningTasks.count)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Text("Return to Focus")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title3)
                                .foregroundColor(Color(red: 1.0, green: 0.78, blue: 0.2))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color(red: 1.0, green: 0.78, blue: 0.2).opacity(0.14))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 1.0, green: 0.78, blue: 0.2).opacity(0.40), lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 22)
            }
            
            // 2:00 PM Afternoon Recharge Banner (Behavioral safety net for Express mode)
            if appState.hasRelocatedAfternoonRecharge {
                HStack(spacing: 20) {
                    Image(systemName: "sun.haze.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text("2:00 PM AFTERNOON RECHARGE")
                                .font(.caption)
                                .fontWeight(.black)
                                .tracking(1.5)
                                .foregroundColor(.orange)
                            Text("• Express Mode Relocated")
                                .font(.caption2)
                                .foregroundColor(Color.white.opacity(0.60))
                        }
                        Text("Mobility & Foot Rehab preserved for peak afternoon recovery")
                            .font(.subheadline)
                            .foregroundColor(Color.white.opacity(0.85))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            appState.openFootRoutine(period: .morning)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "shoeprints.fill")
                            Text("Foot Rehab (10m)")
                        }
                        .font(.subheadline)
                        .fontWeight(.bold)
                    }
                    .buttonStyle(.bordered)
                    .tint(.cyan)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            appState.openStretchingRoutine(period: .morning)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "figure.flexibility")
                            Text("Mobility (10m)")
                        }
                        .font(.subheadline)
                        .fontWeight(.bold)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color(red: 0.0, green: 0.92, blue: 1.0))
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.35), lineWidth: 1.5)
                )
                .padding(.bottom, 18)
            }
            
            // Omeprazole / Meds Timer Banner (shows countdown and 30m / 60m target times)
            if isMedsTimerActive {
                medsTimerBanner
                    .padding(.bottom, 24)
            }
            
            // Dashboard Main Columns
            HStack(alignment: .top, spacing: 50) {
                // Left Column: Habits (Morning / Night)
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 14) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedHabitPeriod = .morning
                            }
                        }) {
                            Image(systemName: "sun.max.fill")
                                .font(.title2)
                                .foregroundColor(selectedHabitPeriod == .morning ? .yellow : Color.white.opacity(0.40))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedHabitPeriod == .morning ? Color.white.opacity(0.18) : Color.clear)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedHabitPeriod = .night
                            }
                        }) {
                            Image(systemName: "moon.stars.fill")
                                .font(.title2)
                                .foregroundColor(selectedHabitPeriod == .night ? .cyan : Color.white.opacity(0.40))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedHabitPeriod == .night ? Color.white.opacity(0.18) : Color.clear)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.bordered)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 1, height: 28)
                            .padding(.horizontal, 4)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                appState.startRoutine(period: selectedHabitPeriod)
                            }
                        }) {
                            Image(systemName: "play.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                appState.stopRoutine()
                            }
                        }) {
                            Image(systemName: "stop.fill")
                                .font(.title2)
                                .foregroundColor(appState.activeRoutineSession != nil ? .red : Color.white.opacity(0.30))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .disabled(appState.activeRoutineSession == nil)
                        
                        if let active = appState.activeRoutineSession {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text(formatRoutineElapsed(active))
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.12))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                        
                    ScrollView(.vertical, showsIndicators: false) {
                        if selectedHabitPeriod == .morning {
                            if appState.morningTasks.isEmpty {
                                VStack(spacing: 12) {
                                    Text("No morning habits configured.")
                                        .font(.title3)
                                        .foregroundColor(Color.white.opacity(0.75))
                                }
                                .frame(maxWidth: .infinity, minHeight: 180)
                            } else {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 4), spacing: 20) {
                                    ForEach(appState.morningTasks) { task in
                                        Button(action: {
                                            if task.isFootRoutine {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    appState.openFootRoutine(for: task.id, period: .morning)
                                                }
                                            } else if task.isStretchingRoutine {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    appState.openStretchingRoutine(for: task.id, period: .morning)
                                                }
                                            } else if isMedsTask(task) {
                                                withAnimation(.easeInOut(duration: 0.25)) {
                                                    medsOverlayPeriod = .morning
                                                    medsOverlayTaskId = task.id
                                                    showMedsOverlay = true
                                                }
                                            } else {
                                                let willBeCompleted = !task.isCompleted
                                                appState.toggleMorningTask(task)
                                                if willBeCompleted {
                                                    appState.recordTaskCompletion(period: .morning, taskId: task.id, taskTitle: task.title)
                                                } else {
                                                    appState.recordTaskUncompleted(period: .morning, taskId: task.id)
                                                }
                                            }
                                        }) {
                                            VStack(spacing: 10) {
                                                Spacer()
                                                Text(task.title.uppercased())
                                                    .font(.title3)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(task.isCompleted ? Color.white.opacity(0.55) : Color.white)
                                                    .multilineTextAlignment(.center)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.75)
                                                    .padding(.horizontal, 8)
                                                
                                                if task.isCompleted {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.green)
                                                        .font(.system(size: 30))
                                                    
                                                    if let dur = appState.recordedDuration(for: task.id) {
                                                        Text(formatCompactDuration(dur))
                                                            .font(.caption2)
                                                            .fontWeight(.bold)
                                                            .foregroundColor(.green)
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Color.green.opacity(0.15))
                                                            .cornerRadius(6)
                                                    }
                                                } else if task.isFootRoutine {
                                                    VStack(spacing: 4) {
                                                        Image(systemName: "shoeprints.fill")
                                                            .foregroundColor(.cyan)
                                                            .font(.system(size: 26))
                                                        
                                                        Text("ROUTINE")
                                                            .font(.system(size: 10, weight: .black, design: .monospaced))
                                                            .foregroundColor(.cyan)
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Color.cyan.opacity(0.15))
                                                            .cornerRadius(4)
                                                    }
                                                } else if task.isStretchingRoutine {
                                                    VStack(spacing: 4) {
                                                        Image(systemName: "figure.flexibility")
                                                            .foregroundColor(.cyan)
                                                            .font(.system(size: 26))
                                                        
                                                        Text("STRETCH")
                                                            .font(.system(size: 10, weight: .black, design: .monospaced))
                                                            .foregroundColor(.cyan)
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Color.cyan.opacity(0.15))
                                                            .cornerRadius(4)
                                                    }
                                                } else if isMedsTask(task) {
                                                    VStack(spacing: 4) {
                                                        Image(systemName: "pills.fill")
                                                            .foregroundColor(.cyan)
                                                            .font(.system(size: 26))
                                                        
                                                        Text("MEDS")
                                                            .font(.system(size: 10, weight: .black, design: .monospaced))
                                                            .foregroundColor(.cyan)
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Color.cyan.opacity(0.15))
                                                            .cornerRadius(4)
                                                    }
                                                } else {
                                                    Image(systemName: "circle")
                                                        .foregroundColor(Color.white.opacity(0.40))
                                                        .font(.system(size: 32))
                                                }
                                                Spacer()
                                            }
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 155)
                                        }
                                        .buttonStyle(.card)
                                        .opacity(task.isCompleted ? 0.6 : 1.0)
                                        .onPlayPauseCommand {
                                            if task.isFootRoutine || task.isStretchingRoutine || isMedsTask(task) {
                                                let willBeCompleted = !task.isCompleted
                                                appState.toggleMorningTask(task)
                                                if willBeCompleted {
                                                    appState.recordTaskCompletion(period: .morning, taskId: task.id, taskTitle: task.title)
                                                    if isMedsTask(task) { startMedsTimer() }
                                                } else {
                                                    appState.recordTaskUncompleted(period: .morning, taskId: task.id)
                                                    if isMedsTask(task) { clearMedsTimer() }
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 4)
                            }
                        } else {
                            if appState.nightTasks.isEmpty {
                                VStack(spacing: 12) {
                                    Text("No night habits configured.")
                                        .font(.title3)
                                        .foregroundColor(Color.white.opacity(0.75))
                                }
                                .frame(maxWidth: .infinity, minHeight: 180)
                            } else {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 4), spacing: 20) {
                                    ForEach(appState.nightTasks) { task in
                                        Button(action: {
                                            if task.isFootRoutine {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    appState.openFootRoutine(for: task.id, period: .night)
                                                }
                                            } else if task.isStretchingRoutine {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    appState.openStretchingRoutine(for: task.id, period: .night)
                                                }
                                            } else if isMedsTask(task) {
                                                withAnimation(.easeInOut(duration: 0.25)) {
                                                    medsOverlayPeriod = .night
                                                    medsOverlayTaskId = task.id
                                                    showMedsOverlay = true
                                                }
                                            } else {
                                                let willBeCompleted = !task.isCompleted
                                                appState.toggleNightTask(task)
                                                if willBeCompleted {
                                                    appState.recordTaskCompletion(period: .night, taskId: task.id, taskTitle: task.title)
                                                } else {
                                                    appState.recordTaskUncompleted(period: .night, taskId: task.id)
                                                }
                                            }
                                        }) {
                                            VStack(spacing: 10) {
                                                Spacer()
                                                Text(task.title.uppercased())
                                                    .font(.title3)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(task.isCompleted ? Color.white.opacity(0.55) : Color.white)
                                                    .multilineTextAlignment(.center)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.75)
                                                    .padding(.horizontal, 8)
                                                
                                                if task.isCompleted {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.green)
                                                        .font(.system(size: 30))
                                                    
                                                    if let dur = appState.recordedDuration(for: task.id) {
                                                        Text(formatCompactDuration(dur))
                                                            .font(.caption2)
                                                            .fontWeight(.bold)
                                                            .foregroundColor(.green)
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Color.green.opacity(0.15))
                                                            .cornerRadius(6)
                                                    }
                                                } else if task.isFootRoutine {
                                                    VStack(spacing: 4) {
                                                        Image(systemName: "shoeprints.fill")
                                                            .foregroundColor(.cyan)
                                                            .font(.system(size: 26))
                                                        
                                                        Text("ROUTINE")
                                                            .font(.system(size: 10, weight: .black, design: .monospaced))
                                                            .foregroundColor(.cyan)
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Color.cyan.opacity(0.15))
                                                            .cornerRadius(4)
                                                    }
                                                } else if task.isStretchingRoutine {
                                                    VStack(spacing: 4) {
                                                        Image(systemName: "figure.flexibility")
                                                            .foregroundColor(.cyan)
                                                            .font(.system(size: 26))
                                                        
                                                        Text("STRETCH")
                                                            .font(.system(size: 10, weight: .black, design: .monospaced))
                                                            .foregroundColor(.cyan)
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Color.cyan.opacity(0.15))
                                                            .cornerRadius(4)
                                                    }
                                                } else if isMedsTask(task) {
                                                    VStack(spacing: 4) {
                                                        Image(systemName: "pills.fill")
                                                            .foregroundColor(.cyan)
                                                            .font(.system(size: 26))
                                                        
                                                        Text("MEDS")
                                                            .font(.system(size: 10, weight: .black, design: .monospaced))
                                                            .foregroundColor(.cyan)
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Color.cyan.opacity(0.15))
                                                            .cornerRadius(4)
                                                    }
                                                } else {
                                                    Image(systemName: "circle")
                                                        .foregroundColor(Color.white.opacity(0.40))
                                                        .font(.system(size: 32))
                                                }
                                                Spacer()
                                            }
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 155)
                                        }
                                        .buttonStyle(.card)
                                        .opacity(task.isCompleted ? 0.6 : 1.0)
                                        .onPlayPauseCommand {
                                            if task.isFootRoutine || task.isStretchingRoutine || isMedsTask(task) {
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
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .focusSection()
                
                // Right Column: Today's Tasks (Day-Specific Tasks)
                VStack(alignment: .leading, spacing: 16) {
                    if appState.isMorningRoutineComplete {
                        launchpadBanner
                    }
                    
                    HStack {
                        Text("TODAY'S TASKS")
                            .font(.headline)
                            .foregroundColor(Color.white.opacity(0.80))
                        Spacer()
                        Button(action: {
                            newDailyTitle = ""
                            showAddDailyAlert = true
                        }) {
                            Label("Add Task", systemImage: "plus")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal, 4)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 14) {
                            if appState.todayDailyTasks.isEmpty {
                                Button(action: {
                                    newDailyTitle = ""
                                    showAddDailyAlert = true
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(Color.white.opacity(0.60))
                                        Text("No tasks for today. Click to add one!")
                                            .font(.title3)
                                            .foregroundColor(Color.white.opacity(0.75))
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 16)
                                }
                                .buttonStyle(.bordered)
                            } else {
                                ForEach(appState.todayDailyTasks) { task in
                                    Button(action: {
                                        appState.toggleDailyTask(task)
                                    }) {
                                        HStack(spacing: 18) {
                                            Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                                                .font(.title2)
                                                .foregroundColor(task.isCompleted ? .green : Color.white.opacity(0.70))
                                            
                                            Text(task.title)
                                                .font(.title3)
                                                .strikethrough(task.isCompleted)
                                                .foregroundColor(task.isCompleted ? Color.white.opacity(0.55) : Color.white)
                                            
                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 16)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 4)
                    }
                    
                    Spacer()
                    
                    // Work & Focus Tracker Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("WORK & FOCUS", systemImage: "briefcase.fill")
                                .font(.caption)
                                .fontWeight(.heavy)
                                .foregroundColor(.indigo)
                                .tracking(1.2)
                            
                            Spacer()
                            
                            if appState.todayWorkDurationSeconds > 0 {
                                Text("Today: \(formatCompactDuration(appState.todayWorkDurationSeconds))")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.white.opacity(0.75))
                            }
                        }
                        
                        if let activeWork = appState.activeWorkSession {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    appState.showWorkFocusScreen = true
                                }
                            }) {
                                HStack(spacing: 14) {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 10, height: 10)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(activeWork.title.uppercased())
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        Text("Sprint active • Tap for full screen")
                                            .font(.caption2)
                                            .foregroundColor(Color.white.opacity(0.75))
                                    }
                                    
                                    Spacer()
                                    
                                    Text(formatWorkElapsed(activeWork))
                                        .font(.system(.title3, design: .monospaced))
                                        .fontWeight(.heavy)
                                        .foregroundColor(.orange)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(Color.white.opacity(0.60))
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.orange.opacity(0.12))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        } else {
                            HStack(spacing: 12) {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        appState.startWorkSession(title: "Work Sprint", project: "Work")
                                        appState.showWorkFocusScreen = true
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "play.fill")
                                        Text("Start Focus Sprint")
                                            .foregroundColor(.white)
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.indigo)
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        appState.showWorkFocusScreen = true
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "timer")
                                        Text("Focus & Timeline")
                                            .foregroundColor(.white)
                                    }
                                    .font(.subheadline)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(14)
                    .padding(.horizontal, 4)
                    
                    // Configuration, Focus & Night Mode Trigger Buttons
                    HStack(spacing: 14) {
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                appState.showWorkFocusScreen = true
                            }
                        }) {
                            Image(systemName: "timer")
                                .font(.title3)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                appState.lastDismissedNightCycle = ""
                                UserDefaults.standard.removeObject(forKey: "lastDismissedNightCycle")
                                appState.trigger10PMNightModePreview()
                                selectedHabitPeriod = .night
                            }
                        }) {
                            Image(systemName: appState.isTenPMOrLater ? "moon.stars.fill" : "moon.fill")
                                .font(.title3)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal, 4)
                }
                .frame(width: 550)
                .focusSection()
            }
        }
        .padding(.horizontal, 60)
        .padding(.top, 40)
        .padding(.bottom, 50)
    }
    
    // MARK: - Launchpad Banner (Phase 2: Morning-to-Work Bridge)
    private var launchpadBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Morning Routine Complete")
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                    
                    Text("Momentum is primed. Lock in your first block.")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.80))
                }
                
                Spacer()
            }
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    appState.launchFirstSprint()
                }
            }) {
                HStack(spacing: 10) {
                    Text("🚀")
                        .font(.title3)
                    Text("Launch Sprint 1")
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.indigo.opacity(0.32), Color.purple.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.indigo.opacity(0.6), lineWidth: 1.5)
        )
        .padding(.horizontal, 4)
    }
    
    // MARK: - Retro CRT Scanlines
    private struct CRTScanlinesView: View {
        var body: some View {
            Canvas { context, size in
                let lineSpacing: CGFloat = 4
                var y: CGFloat = 0
                while y < size.height {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1.5)
                    context.fill(Path(rect), with: .color(Color.black.opacity(0.18)))
                    y += lineSpacing
                }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Night Mode Dismissal Helper
    private func dismissNightMode() {
        withAnimation(.easeInOut(duration: 0.4)) {
            appState.dismiss10PMNightMode()
            selectedHabitPeriod = .night
        }
    }
    
    // MARK: - 10 PM Night Screen (Giant Retro Typography & Deliberate Gate)
    @ViewBuilder
    private var tenPMNightView: some View {
        ZStack {
            // Retro CRT TV Deep Midnight Blue Background
            Color(red: 0.01, green: 0.02, blue: 0.06)
                .ignoresSafeArea()
            
            // Tube Phosphor Radial Glow
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.06, green: 0.11, blue: 0.28),
                    Color(red: 0.02, green: 0.05, blue: 0.14),
                    Color(red: 0.01, green: 0.02, blue: 0.06)
                ]),
                center: .center,
                startRadius: 160,
                endRadius: 1050
            )
            .ignoresSafeArea()
            
            // Subtle CRT TV Scanlines
            CRTScanlinesView()
            
            VStack(spacing: 36) {
                Spacer()
                
                // Massive Typography Lockup (Tightened Line Spacing)
                HStack(alignment: .center, spacing: 45) {
                    // "10" on top of "PM" in massive bold RED (width-matched block, tight spacing)
                    VStack(alignment: .center, spacing: -85) {
                        Text("10")
                            .font(.system(size: 420, weight: .black, design: .default))
                            .tracking(-8)
                        Text("PM")
                            .font(.system(size: 320, weight: .black, design: .default))
                            .tracking(0)
                    }
                    .foregroundColor(Color(red: 1.0, green: 0.14, blue: 0.20))
                    .shadow(color: Color(red: 1.0, green: 0.14, blue: 0.20).opacity(0.5), radius: 45, x: 0, y: 0)
                    .shadow(color: Color.black.opacity(0.9), radius: 12, x: 6, y: 8)
                    
                    // 5 Lines in pure vibrant electric cyan-blue phosphor (high contrast, zero muddiness)
                    VStack(alignment: .leading, spacing: -22) {
                        Text("DO YOU")
                        Text("KNOW")
                        Text("WHAT YOU")
                        Text("ARE")
                        Text("DOING?")
                    }
                    .font(.system(size: 126, weight: .black, design: .default))
                    .foregroundColor(Color(red: 0.30, green: 0.75, blue: 1.0))
                    .tracking(2)
                    .shadow(color: Color.cyan.opacity(0.65), radius: 32, x: 0, y: 0)
                    .shadow(color: Color.black.opacity(0.6), radius: 8, x: 3, y: 4)
                }
                
                Spacer()
                
                // Deliberate Action Gate Buttons (Siri Remote Focusable)
                HStack(spacing: 36) {
                    Button(action: {
                        dismissNightMode()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "moon.stars.fill")
                                .font(.title3)
                            Text("Start Night Routine")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.12, green: 0.48, blue: 1.0))
                    .focused($nightGateFocus, equals: .nightRoutine)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            appState.dismiss10PMNightMode()
                            appState.startOvertimeSprint()
                            appState.showWorkFocusScreen = true
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "timer")
                                .font(.title3)
                            Text("Overtime Sprint (30m Cap)")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .focused($nightGateFocus, equals: .overtime)
                }
                .padding(.bottom, 60)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .defaultFocus($nightGateFocus, .nightRoutine)
        .onAppear {
            nightGateFocus = .nightRoutine
        }
    }
    
    // MARK: - Routine Formatters
    private func formatRoutineElapsed(_ session: RoutineSession) -> String {
        let elapsed = max(0, Int(appState.currentDate.timeIntervalSince(session.startTime)))
        let mins = elapsed / 60
        let secs = elapsed % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func formatCompactDuration(_ seconds: TimeInterval) -> String {
        let total = max(1, Int(round(seconds)))
        let mins = total / 60
        let secs = total % 60
        if mins > 0 {
            return "\(mins)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
    
    private func formatWorkElapsed(_ session: WorkSession) -> String {
        let elapsed = max(0, Int(appState.currentDate.timeIntervalSince(session.startTime)))
        let hours = elapsed / 3600
        let mins = (elapsed % 3600) / 60
        let secs = elapsed % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }
    
    // MARK: - Omeprazole / Meds Timer
    private var isMedsTimerActive: Bool {
        guard medsTakenTimestamp > 0 else { return false }
        // Keep active for up to 2 hours after meds were taken
        return appState.currentDate.timeIntervalSince1970 - medsTakenTimestamp < 2 * 3600
    }
    
    private var medsTakenDate: Date {
        Date(timeIntervalSince1970: medsTakenTimestamp)
    }
    
    private var eatAfterDate: Date {
        medsTakenDate.addingTimeInterval(30 * 60) // 30 minutes
    }
    
    private var eatBeforeDate: Date {
        medsTakenDate.addingTimeInterval(60 * 60) // 60 minutes (1 hour)
    }
    
    private func startMedsTimer() {
        medsTakenTimestamp = Date().timeIntervalSince1970
        appState.startMedsTimer()
        appState.updateClock()
    }
    
    private func clearMedsTimer() {
        medsTakenTimestamp = 0
        appState.clearMedsTimer()
    }
    
    private func isMedsTask(_ task: MorningTask) -> Bool {
        task.isMedsTask
    }
    
    private func isMedsTask(_ task: NightTask) -> Bool {
        task.isMedsTask
    }
    
    private func checkAndUpdateMedsHabitTask() {
        let periodMeds = appState.medications.filter { $0.period == medsOverlayPeriod }
        guard !periodMeds.isEmpty else { return }
        let allDone = periodMeds.allSatisfy { $0.isCompleted }
        
        if medsOverlayPeriod == .morning {
            if let id = medsOverlayTaskId, let idx = appState.morningTasks.firstIndex(where: { $0.id == id }) {
                let wasCompleted = appState.morningTasks[idx].isCompleted
                if allDone && !wasCompleted {
                    appState.morningTasks[idx].isCompleted = true
                    appState.recordTaskCompletion(period: .morning, taskId: id, taskTitle: appState.morningTasks[idx].title)
                    appState.saveMorningTasks()
                } else if !allDone && wasCompleted {
                    appState.morningTasks[idx].isCompleted = false
                    appState.recordTaskUncompleted(period: .morning, taskId: id)
                    appState.saveMorningTasks()
                }
            } else if let idx = appState.morningTasks.firstIndex(where: { isMedsTask($0) }) {
                let id = appState.morningTasks[idx].id
                let wasCompleted = appState.morningTasks[idx].isCompleted
                if allDone && !wasCompleted {
                    appState.morningTasks[idx].isCompleted = true
                    appState.recordTaskCompletion(period: .morning, taskId: id, taskTitle: appState.morningTasks[idx].title)
                    appState.saveMorningTasks()
                } else if !allDone && wasCompleted {
                    appState.morningTasks[idx].isCompleted = false
                    appState.recordTaskUncompleted(period: .morning, taskId: id)
                    appState.saveMorningTasks()
                }
            }
        } else {
            if let id = medsOverlayTaskId, let idx = appState.nightTasks.firstIndex(where: { $0.id == id }) {
                let wasCompleted = appState.nightTasks[idx].isCompleted
                if allDone && !wasCompleted {
                    appState.nightTasks[idx].isCompleted = true
                    appState.recordTaskCompletion(period: .night, taskId: id, taskTitle: appState.nightTasks[idx].title)
                    appState.saveNightTasks()
                } else if !allDone && wasCompleted {
                    appState.nightTasks[idx].isCompleted = false
                    appState.recordTaskUncompleted(period: .night, taskId: id)
                    appState.saveNightTasks()
                }
            } else if let idx = appState.nightTasks.firstIndex(where: { isMedsTask($0) }) {
                let id = appState.nightTasks[idx].id
                let wasCompleted = appState.nightTasks[idx].isCompleted
                if allDone && !wasCompleted {
                    appState.nightTasks[idx].isCompleted = true
                    appState.recordTaskCompletion(period: .night, taskId: id, taskTitle: appState.nightTasks[idx].title)
                    appState.saveNightTasks()
                } else if !allDone && wasCompleted {
                    appState.nightTasks[idx].isCompleted = false
                    appState.recordTaskUncompleted(period: .night, taskId: id)
                    appState.saveNightTasks()
                }
            }
        }
    }
    
    private func formatTargetTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    @ViewBuilder
    private var medsTimerBanner: some View {
        let now = appState.currentDate
        let isInWaitPhase = now < eatAfterDate
        let isInEatingWindow = now >= eatAfterDate && now <= eatBeforeDate
        
        let accentColor: Color = isInWaitPhase ? .orange : (isInEatingWindow ? .green : Color.white.opacity(0.60))
        let iconName: String = isInWaitPhase ? "hourglass.bottomhalf.filled" : (isInEatingWindow ? "fork.knife" : "checkmark.seal.fill")
        
        let waitSecondsRemaining = max(0, Int(eatAfterDate.timeIntervalSince(now)))
        let waitMinutes = waitSecondsRemaining / 60
        let waitSeconds = waitSecondsRemaining % 60
        let waitCountdownString = String(format: "%02d:%02d", waitMinutes, waitSeconds)
        
        let windowSecondsRemaining = max(0, Int(eatBeforeDate.timeIntervalSince(now)))
        let windowMinutes = max(1, (windowSecondsRemaining + 59) / 60)
        
        HStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.18))
                    .frame(width: 60, height: 60)
                Image(systemName: iconName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    if isInWaitPhase {
                        Text("OMEPRAZOLE WAIT TIME")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(accentColor)
                        
                        Text(waitCountdownString)
                            .font(.system(size: 32, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                    } else if isInEatingWindow {
                        Text("EATING WINDOW OPEN")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(accentColor)
                        
                        Text("\(windowMinutes)m remaining")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    } else {
                        Text("OMEPRAZOLE WINDOW CLOSED")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.white.opacity(0.70))
                    }
                }
                
                HStack(spacing: 18) {
                    HStack(spacing: 6) {
                        Text("Eat after (30m):")
                            .foregroundColor(Color.white.opacity(0.75))
                        Text(formatTargetTime(eatAfterDate))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    Text("•")
                        .foregroundColor(Color.white.opacity(0.40))
                    
                    HStack(spacing: 6) {
                        Text("Eat before (1h):")
                            .foregroundColor(Color.white.opacity(0.75))
                        Text(formatTargetTime(eatBeforeDate))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    Text("•")
                        .foregroundColor(Color.white.opacity(0.40))
                    
                    Text("Taken at \(formatTargetTime(medsTakenDate))")
                        .foregroundColor(Color.white.opacity(0.75))
                }
                .font(.subheadline)
            }
            
            Spacer()
            
            Button(action: {
                clearMedsTimer()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                    Text("Dismiss")
                }
                .font(.footnote)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.04))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accentColor.opacity(0.35), lineWidth: 1.5)
        )
    }
    
    // MARK: - Weather Helpers
    private func weatherEmoji(isRaining: Bool, desc: String) -> String {
        if isRaining {
            return "🌧"
        }
        
        switch desc {
        case "Clear": return "☀️"
        case "Partly Cloudy": return "⛅️"
        case "Foggy": return "🌫"
        case "Drizzle": return "🌦"
        case "Raining", "Rain Showers": return "🌧"
        case "Freezing Rain": return "🌨"
        case "Snowing", "Snow Grains", "Snow Showers": return "❄️"
        case "Thunderstorm": return "⛈"
        default: return "☁️"
        }
    }
    
    private func uvColor(for index: Double) -> Color {
        switch index {
        case ..<3.0: return .green
        case 3.0..<6.0: return .yellow
        case 6.0..<8.0: return .orange
        case 8.0..<11.0: return .red
        default: return .purple
        }
    }
    
    private func uvSeverityText(for index: Double) -> String {
        switch index {
        case ..<3.0: return "Low"
        case 3.0..<6.0: return "Moderate"
        case 6.0..<8.0: return "High"
        case 8.0..<11.0: return "Very High"
        default: return "Extreme"
        }
    }
}

#Preview("10 PM Mode") {
    ContentView(preview10PM: true)
}

#Preview("Dashboard") {
    ContentView()
}
