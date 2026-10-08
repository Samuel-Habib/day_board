import SwiftUI

public struct FootRoutineView: View {
    @Bindable var appState: AppState
    public let onDismiss: () -> Void
    
    // Focus Control for Siri Remote
    private enum FocusField: Hashable {
        case primaryAction
        case secondaryAction
        case backButton
        case resumeContinue
        case resumeStartOver
        case doneButton
    }
    @FocusState private var focusedField: FocusField?
    
    // Exercise Progress State
    @State private var currentExerciseIndex: Int = 0
    @State private var currentSet: Int = 1
    @State private var isCompletedRoutine: Bool = false
    @State private var showResumePrompt: Bool = false
    
    // Timer State (Based on real Date elapsed time)
    @State private var timerActive: Bool = false
    @State private var timerPaused: Bool = false
    @State private var timeRemaining: TimeInterval = 30
    @State private var totalTime: TimeInterval = 30
    @State private var timerStartDate: Date?
    @State private var timerAccumulatedSeconds: TimeInterval = 0
    @State private var tickerTimer: Timer?
    
    // Repetition State
    @State private var currentRepsCompleted: Int = 0
    
    private var exercises: [FootExercise] {
        let list = appState.enabledFootExercises
        return list.isEmpty ? FootExercise.defaultExercises : list
    }
    
    private var currentExercise: FootExercise? {
        guard currentExerciseIndex >= 0 && currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }
    
    public init(appState: AppState, onDismiss: @escaping () -> Void) {
        self.appState = appState
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            // Clean Neutral Obsidian Canvas (No Murky Blue Cast)
            Color(red: 0.05, green: 0.05, blue: 0.06)
                .ignoresSafeArea()
            
            // Subtle Neutral Studio Ambient Glow
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(white: 0.12).opacity(0.35),
                    Color(white: 0.06).opacity(0.20),
                    Color(red: 0.03, green: 0.03, blue: 0.04)
                ]),
                center: .center,
                startRadius: 200,
                endRadius: 1000
            )
            .ignoresSafeArea()
            
            if isCompletedRoutine {
                completionView
            } else if showResumePrompt {
                resumePromptView
            } else if let exercise = currentExercise {
                activeExerciseView(exercise: exercise)
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            setupInitialState()
        }
        .onDisappear {
            stopTicker()
        }
        .onExitCommand {
            handleExit()
        }
    }
    
    // MARK: - Initial State & Resume Check
    private func setupInitialState() {
        if let session = appState.activeFootSession, !session.completedExerciseIds.isEmpty || session.currentExerciseIndex > 0 {
            // Incomplete session exists from earlier today
            showResumePrompt = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = .resumeContinue
            }
        } else {
            // Fresh start
            startExerciseAtIndex(0, set: 1)
        }
    }
    
    private func startExerciseAtIndex(_ index: Int, set: Int) {
        currentExerciseIndex = index
        currentSet = set
        currentRepsCompleted = 0
        timerActive = false
        timerPaused = false
        stopTicker()
        
        if let ex = currentExercise {
            let target = TimeInterval(ex.targetSeconds ?? 30)
            totalTime = target
            timeRemaining = target
            timerAccumulatedSeconds = 0
            timerStartDate = nil
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = .primaryAction
        }
    }
    
    // MARK: - Resume Prompt View
    private var resumePromptView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "shoeprints.fill")
                .font(.system(size: 72))
                .foregroundColor(.cyan)
                .padding(.bottom, 8)
            
            Text("FOOT REHAB ROUTINE")
                .font(.system(size: 40, weight: .black))
                .tracking(2)
                .foregroundColor(.white)
            
            let savedIndex = appState.activeFootSession?.currentExerciseIndex ?? 0
            let completedCount = appState.activeFootSession?.completedExerciseIds.count ?? 0
            
            Text("You completed \(completedCount) of \(exercises.count) exercises earlier today.\nContinue where you left off?")
                .font(.title3)
                .foregroundColor(Color.white.opacity(0.80))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
            
            HStack(spacing: 30) {
                Button(action: {
                    showResumePrompt = false
                    let targetIdx = min(savedIndex, exercises.count - 1)
                    let targetSet = appState.activeFootSession?.currentSet ?? 1
                    startExerciseAtIndex(targetIdx, set: targetSet)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                        Text("Continue Routine")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .focused($focusedField, equals: .resumeContinue)
                
                Button(action: {
                    showResumePrompt = false
                    appState.startNewFootSession()
                    startExerciseAtIndex(0, set: 1)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Start Over")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .focused($focusedField, equals: .resumeStartOver)
            }
            .padding(.top, 16)
            
            Spacer()
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Active Exercise View
    private func activeExerciseView(exercise: FootExercise) -> some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            HStack(alignment: .center) {
                Button(action: {
                    handleExit()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                        Text("Dashboard")
                            .foregroundColor(.white)
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                }
                .buttonStyle(.bordered)
                .focused($focusedField, equals: .backButton)
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("FOOT REHABILITATION")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .foregroundColor(Color.white.opacity(0.75))
                        .tracking(2)
                    
                    Text("Plantar Fascia Guided Protocol")
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.60))
                }
                
                Spacer()
                
                // Exercise Progress Indicator (Dots)
                HStack(spacing: 14) {
                    Text("EXERCISE \(currentExerciseIndex + 1) OF \(exercises.count)")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.black)
                        .foregroundColor(.cyan)
                        .tracking(1)
                    
                    HStack(spacing: 6) {
                        ForEach(0..<exercises.count, id: \.self) { idx in
                            Circle()
                                .fill(idx <= currentExerciseIndex ? Color.cyan : Color.white.opacity(0.2))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
            }
            .padding(.horizontal, 60)
            .padding(.top, 36)
            .padding(.bottom, 20)
            
            // Main Exercise Content
            HStack(alignment: .center, spacing: 48) {
                // Left Column: Visual Demonstration Centerpiece
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name.uppercased())
                            .font(.system(size: 38, weight: .black))
                            .foregroundColor(.white)
                            .tracking(1)
                        
                        if let purpose = exercise.purpose {
                            Text(purpose)
                                .font(.headline)
                                .foregroundColor(.cyan.opacity(0.9))
                        }
                    }
                    
                    // The Animated Visual Demonstration
                    FootExerciseAnimationView(exercise: exercise)
                        .frame(maxWidth: .infinity)
                    
                    // Instruction text
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.cyan)
                            .font(.headline)
                        Text(exercise.instruction)
                            .font(.headline)
                            .foregroundColor(Color.white.opacity(0.85))
                            .lineLimit(2)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                }
                .frame(width: 820)
                
                // Right Column: Exercise Timer / Reps Guidance & Action Controls
                VStack(spacing: 24) {
                    // Set tracker
                    HStack(spacing: 8) {
                        Text("SET \(currentSet) OF \(exercise.sets)")
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.black)
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.cyan.opacity(0.15))
                            .cornerRadius(8)
                        
                        Spacer()
                        
                        if exercise.isTimed {
                            Text("TIMED HOLD")
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(Color.white.opacity(0.75))
                        } else {
                            Text("CONTROLLED REPETITIONS")
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(Color.white.opacity(0.75))
                        }
                    }
                    
                    if exercise.isTimed {
                        // Timed Exercise Display
                        VStack(spacing: 12) {
                            Text(formatTime(timeRemaining))
                                .font(.system(size: 100, weight: .black, design: .monospaced))
                                .foregroundColor(timerActive ? .cyan : (timerPaused ? .orange : Color.white.opacity(0.5)))
                                .tracking(-2)
                            
                            // Visual Progress Bar
                            GeometryReader { pGeo in
                                let progress = totalTime > 0 ? max(0, min(1.0, 1.0 - (timeRemaining / totalTime))) : 0.0
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.08))
                                        .frame(height: 12)
                                    
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [.teal, .cyan],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: pGeo.size.width * CGFloat(progress), height: 12)
                                }
                            }
                            .frame(height: 12)
                            .padding(.horizontal, 20)
                            
                            Text(timerActive ? "Hold position gently • Breathe slowly" : (timerPaused ? "Paused" : "Press Start when ready"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.white.opacity(0.75))
                        }
                        .padding(.vertical, 20)
                    } else {
                        // Repetition Exercise Display
                        VStack(spacing: 16) {
                            let target = exercise.targetReps ?? 12
                            Text("\(currentRepsCompleted) / \(target)")
                                .font(.system(size: 92, weight: .black, design: .monospaced))
                                .foregroundColor(.cyan)
                            
                            HStack(spacing: 16) {
                                Button(action: {
                                    if currentRepsCompleted < target {
                                        currentRepsCompleted += 1
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus")
                                        Text("1 Rep")
                                    }
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                }
                                .buttonStyle(.bordered)
                                
                                Button(action: {
                                    if currentRepsCompleted > 0 {
                                        currentRepsCompleted -= 1
                                    }
                                }) {
                                    Image(systemName: "minus")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            Text("Perform \(target) smooth, controlled repetitions")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.white.opacity(0.75))
                        }
                        .padding(.vertical, 16)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.08))
                    
                    // Primary Action Buttons
                    VStack(spacing: 14) {
                        if exercise.isTimed {
                            if !timerActive && !timerPaused && timeRemaining > 0 {
                                Button(action: {
                                    startTimer()
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "play.fill")
                                        Text("Start Exercise")
                                    }
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.cyan)
                                .focused($focusedField, equals: .primaryAction)
                            } else if timerActive {
                                Button(action: {
                                    pauseTimer()
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "pause.fill")
                                        Text("Pause")
                                    }
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                                .focused($focusedField, equals: .primaryAction)
                            } else if timerPaused {
                                Button(action: {
                                    resumeTimer()
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "play.fill")
                                        Text("Resume")
                                    }
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.cyan)
                                .focused($focusedField, equals: .primaryAction)
                            } else {
                                // Time completed
                                Button(action: {
                                    finishCurrentSet()
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "checkmark")
                                        Text(currentSet < exercise.sets ? "Next Set" : "Complete Exercise")
                                    }
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                .focused($focusedField, equals: .primaryAction)
                            }
                        } else {
                            // Repetition-based action
                            Button(action: {
                                finishCurrentSet()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark")
                                    Text(currentSet < exercise.sets ? "Complete Set \(currentSet)" : "Complete Exercise")
                                }
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.cyan)
                            .focused($focusedField, equals: .primaryAction)
                        }
                        
                        // Skip Exercise Button
                        Button(action: {
                            advanceToNextExercise()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "forward.fill")
                                Text("Skip Exercise")
                            }
                            .font(.headline)
                            .foregroundColor(Color.white.opacity(0.80))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.bordered)
                        .focused($focusedField, equals: .secondaryAction)
                    }
                }
                .padding(28)
                .background(Color.white.opacity(0.035))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 60)
            
            Spacer()
            
            // Medical Clinical Guidance Note (Unobtrusive footer)
            HStack(spacing: 8) {
                Image(systemName: "cross.case.fill")
                    .foregroundColor(Color.white.opacity(0.60))
                    .font(.caption)
                
                Text("Follow the exercise plan provided by your clinician. Stop if an exercise causes sharp or significantly worsening pain.")
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.75))
            }
            .padding(.bottom, 28)
        }
    }
    
    // MARK: - Routine Complete View
    private var completionView: some View {
        VStack(spacing: 28) {
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 96))
                .foregroundColor(.green)
                .shadow(color: Color.green.opacity(0.4), radius: 24)
            
            VStack(spacing: 8) {
                Text("FOOT ROUTINE COMPLETE")
                    .font(.system(size: 48, weight: .black))
                    .tracking(2)
                    .foregroundColor(.white)
                
                Text("\(exercises.count) / \(exercises.count) exercises completed")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            Text("Nice work. Routine recorded and habit marked complete.")
                .font(.headline)
                .foregroundColor(Color.white.opacity(0.85))
                .padding(.top, 4)
            
            Button(action: {
                appState.completeFootRoutine()
                onDismiss()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark")
                    Text("Done")
                        .foregroundColor(.white)
                }
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal, 48)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .focused($focusedField, equals: .doneButton)
            .padding(.top, 20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = .doneButton
            }
        }
    }
    
    // MARK: - Timer Mechanics (Date Elapsed Truth)
    private func startTimer() {
        timerStartDate = Date()
        timerActive = true
        timerPaused = false
        startTicker()
    }
    
    private func pauseTimer() {
        stopTicker()
        if let start = timerStartDate {
            timerAccumulatedSeconds += Date().timeIntervalSince(start)
        }
        timerStartDate = nil
        timerActive = false
        timerPaused = true
    }
    
    private func resumeTimer() {
        timerStartDate = Date()
        timerActive = true
        timerPaused = false
        startTicker()
    }
    
    private func startTicker() {
        stopTicker()
        tickerTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let start = timerStartDate else { return }
            let elapsed = timerAccumulatedSeconds + Date().timeIntervalSince(start)
            let rem = max(0, totalTime - elapsed)
            timeRemaining = rem
            if rem <= 0 {
                stopTicker()
                timerActive = false
                timerPaused = false
                // Auto trigger finish or set completion
                finishCurrentSet()
            }
        }
    }
    
    private func stopTicker() {
        tickerTimer?.invalidate()
        tickerTimer = nil
    }
    
    // MARK: - Set & Exercise Advancement
    private func finishCurrentSet() {
        guard let exercise = currentExercise else { return }
        stopTicker()
        
        if currentSet < exercise.sets {
            // Next set of same exercise
            startExerciseAtIndex(currentExerciseIndex, set: currentSet + 1)
        } else {
            // Exercise complete!
            appState.completeFootExercise(id: exercise.id)
            advanceToNextExercise()
        }
    }
    
    private func advanceToNextExercise() {
        stopTicker()
        let nextIndex = currentExerciseIndex + 1
        if nextIndex < exercises.count {
            startExerciseAtIndex(nextIndex, set: 1)
            // Update active session index
            if var session = appState.activeFootSession {
                session.currentExerciseIndex = nextIndex
                session.currentSet = 1
                appState.activeFootSession = session
            }
        } else {
            // Whole routine complete!
            isCompletedRoutine = true
        }
    }
    
    private func handleExit() {
        stopTicker()
        // Save current progress before leaving
        if var session = appState.activeFootSession {
            session.currentExerciseIndex = currentExerciseIndex
            session.currentSet = currentSet
            appState.activeFootSession = session
        }
        appState.exitFootRoutine(savePartial: true)
        onDismiss()
    }
    
    // MARK: - Formatters
    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(ceil(seconds)))
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
