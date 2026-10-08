import SwiftUI

public struct BodyweightExerciseRoutineView: View {
    @Bindable var appState: AppState
    public let onDismiss: () -> Void
    
    // Focus Control for Siri Remote
    private enum FocusField: Hashable {
        case primaryAction
        case secondaryAction
        case restSkip
        case doneButton
    }
    @FocusState private var focusedField: FocusField?
    
    // Routine Progression State
    @State private var currentExerciseIndex: Int = 0
    @State private var currentSet: Int = 1
    @State private var isResting: Bool = false
    @State private var restTimeRemaining: Int = 45
    @State private var restTotalTime: Int = 45
    @State private var isCompletedRoutine: Bool = false
    
    // Timed Exercise State (e.g. Plank)
    @State private var timerActive: Bool = false
    @State private var timerRemaining: Int = 45
    @State private var timerTotal: Int = 45
    @State private var tickerTimer: Timer?
    @State private var routineStartTime: Date = Date()
    
    private var exercises: [BodyweightExercise] {
        let list = appState.enabledBodyweightExercises
        return list.isEmpty ? BodyweightExercise.defaultExercises : list
    }
    
    private var currentExercise: BodyweightExercise? {
        guard currentExerciseIndex >= 0 && currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }
    
    public init(appState: AppState, onDismiss: @escaping () -> Void) {
        self.appState = appState
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            // Obsidian Backdrop
            Color(red: 0.05, green: 0.05, blue: 0.07)
                .ignoresSafeArea()
            
            // Subtle energetic ambient radial glow
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.0, green: 0.6, blue: 0.7).opacity(0.18),
                    Color(white: 0.04).opacity(0.12),
                    Color(red: 0.03, green: 0.03, blue: 0.04)
                ]),
                center: .center,
                startRadius: 200,
                endRadius: 1000
            )
            .ignoresSafeArea()
            
            if isCompletedRoutine {
                completionView
            } else if let exercise = currentExercise {
                activeExerciseView(exercise: exercise)
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            routineStartTime = Date()
            setupExercise(at: 0, set: 1)
        }
        .onDisappear {
            stopTicker()
        }
        .onExitCommand {
            handleExit()
        }
    }
    
    // MARK: - Exercise Setup
    private func setupExercise(at index: Int, set: Int) {
        currentExerciseIndex = index
        currentSet = set
        isResting = false
        stopTicker()
        
        if let ex = currentExercise {
            if ex.isTimed {
                let targetSecs = ex.targetSeconds ?? 45
                timerTotal = targetSecs
                timerRemaining = targetSecs
                timerActive = true
                startExerciseTimer()
            } else {
                timerActive = false
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = .primaryAction
        }
    }
    
    // MARK: - Active Exercise View
    private func activeExerciseView(exercise: BodyweightExercise) -> some View {
        VStack(spacing: 0) {
            // Top Header Bar
            HStack(alignment: .center) {
                Button(action: handleExit) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                        Text("Morning Routine")
                    }
                    .font(.headline)
                    .foregroundColor(Color.white.opacity(0.85))
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("BODYWEIGHT EXERCISE")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .tracking(3)
                        .foregroundColor(Color(red: 0.0, green: 0.92, blue: 1.0))
                    
                    Text("Exercise \(currentExerciseIndex + 1) of \(exercises.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(appState.currentTime)
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(Color.white.opacity(0.70))
            }
            .padding(.horizontal, 60)
            .padding(.top, 40)
            .padding(.bottom, 20)
            
            // Main Two-Column Content
            HStack(spacing: 40) {
                // Left: Anatomical Illustration
                VStack(spacing: 16) {
                    BodyweightExerciseIllustrationView(exercise: exercise)
                    
                    if let target = exercise.targetMuscles {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .foregroundColor(Color(red: 0.0, green: 0.92, blue: 1.0))
                            Text("TARGET: \(target.uppercased())")
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(Color.white.opacity(0.75))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Right: Controls & Guidance
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SET \(currentSet) OF \(exercise.sets)")
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                            .foregroundColor(Color(red: 0.0, green: 0.92, blue: 1.0))
                            .tracking(2)
                        
                        Text(exercise.name)
                            .font(.system(size: 42, weight: .black))
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                    
                    if let purpose = exercise.purpose {
                        Text(purpose)
                            .font(.body)
                            .foregroundColor(Color.white.opacity(0.80))
                            .lineSpacing(4)
                    }
                    
                    Text(exercise.instruction)
                        .font(.callout)
                        .foregroundColor(Color.white.opacity(0.65))
                        .lineSpacing(3)
                    
                    Spacer()
                    
                    // State Cards: Active vs Resting
                    if isResting {
                        // Rest Timer View
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("REST PERIOD")
                                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                    .foregroundColor(.yellow)
                                Spacer()
                                Text("\(restTimeRemaining)s")
                                    .font(.system(size: 32, weight: .black, design: .monospaced))
                                    .foregroundColor(.yellow)
                            }
                            
                            ProgressView(value: Double(restTotalTime - restTimeRemaining), total: Double(restTotalTime))
                                .tint(.yellow)
                            
                            Button(action: skipRest) {
                                HStack(spacing: 10) {
                                    Image(systemName: "forward.fill")
                                    Text("Skip Rest & Start Set \(currentSet)")
                                }
                                .font(.title3)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.yellow)
                            .focused($focusedField, equals: .restSkip)
                        }
                        .padding(24)
                        .background(Color.yellow.opacity(0.12))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.yellow.opacity(0.35), lineWidth: 1.5)
                        )
                    } else if exercise.isTimed {
                        // Timed Exercise (e.g. Plank)
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("HOLD DURATION")
                                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                    .foregroundColor(Color(red: 0.0, green: 0.92, blue: 1.0))
                                Spacer()
                                Text("\(timerRemaining)s")
                                    .font(.system(size: 38, weight: .black, design: .monospaced))
                                    .foregroundColor(Color(red: 0.0, green: 0.92, blue: 1.0))
                            }
                            
                            ProgressView(value: Double(timerTotal - timerRemaining), total: Double(timerTotal))
                                .tint(Color(red: 0.0, green: 0.92, blue: 1.0))
                            
                            HStack(spacing: 16) {
                                Button(action: completeCurrentSet) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "checkmark")
                                        Text("Complete Set \(currentSet)")
                                    }
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color(red: 0.0, green: 0.92, blue: 1.0))
                                .focused($focusedField, equals: .primaryAction)
                            }
                        }
                        .padding(24)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color(red: 0.0, green: 0.92, blue: 1.0).opacity(0.35), lineWidth: 1.5)
                        )
                    } else {
                        // Rep-based Exercise (e.g. Pushups, Squats)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("TARGET REPETITIONS")
                                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                    .foregroundColor(Color.white.opacity(0.70))
                                Spacer()
                                Text("\(exercise.targetReps ?? 15) REPS")
                                    .font(.system(size: 34, weight: .black, design: .monospaced))
                                    .foregroundColor(Color(red: 0.0, green: 0.92, blue: 1.0))
                            }
                            
                            Button(action: completeCurrentSet) {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Logged Set \(currentSet) (\(exercise.targetReps ?? 15) Reps)")
                                }
                                .font(.title3)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(red: 0.0, green: 0.85, blue: 0.95))
                            .focused($focusedField, equals: .primaryAction)
                            .onPlayPauseCommand {
                                completeCurrentSet()
                            }
                        }
                        .padding(24)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                        )
                    }
                    
                    // Skip button
                    Button(action: skipExercise) {
                        Text("Skip Exercise")
                            .font(.callout)
                            .foregroundColor(Color.white.opacity(0.50))
                    }
                    .buttonStyle(.plain)
                    .focused($focusedField, equals: .secondaryAction)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 60)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Logic Handlers
    private func completeCurrentSet() {
        guard let ex = currentExercise else { return }
        stopTicker()
        
        if currentSet < ex.sets {
            // Enter rest period
            currentSet += 1
            isResting = true
            restTotalTime = ex.restSeconds
            restTimeRemaining = ex.restSeconds
            startRestTimer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = .restSkip
            }
        } else {
            // Finished all sets of this exercise!
            if currentExerciseIndex < exercises.count - 1 {
                setupExercise(at: currentExerciseIndex + 1, set: 1)
            } else {
                // Whole routine complete!
                isCompletedRoutine = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = .doneButton
                }
            }
        }
    }
    
    private func skipRest() {
        stopTicker()
        isResting = false
        if let ex = currentExercise, ex.isTimed {
            let targetSecs = ex.targetSeconds ?? 45
            timerTotal = targetSecs
            timerRemaining = targetSecs
            timerActive = true
            startExerciseTimer()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = .primaryAction
        }
    }
    
    private func skipExercise() {
        stopTicker()
        if currentExerciseIndex < exercises.count - 1 {
            setupExercise(at: currentExerciseIndex + 1, set: 1)
        } else {
            isCompletedRoutine = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = .doneButton
            }
        }
    }
    
    private func startRestTimer() {
        stopTicker()
        tickerTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if restTimeRemaining > 1 {
                restTimeRemaining -= 1
            } else {
                skipRest()
            }
        }
    }
    
    private func startExerciseTimer() {
        stopTicker()
        tickerTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timerRemaining > 1 {
                timerRemaining -= 1
            } else {
                completeCurrentSet()
            }
        }
    }
    
    private func stopTicker() {
        tickerTimer?.invalidate()
        tickerTimer = nil
    }
    
    private func handleExit() {
        stopTicker()
        onDismiss()
    }
    
    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(red: 0.0, green: 0.92, blue: 1.0))
            
            Text("WORKOUT COMPLETE!")
                .font(.system(size: 46, weight: .black))
                .foregroundColor(.white)
                .tracking(2)
            
            let elapsed = Int(Date().timeIntervalSince(routineStartTime))
            let mins = elapsed / 60
            let secs = elapsed % 60
            
            Text("Finished all \(exercises.count) exercises in \(mins)m \(secs)s.")
                .font(.title3)
                .foregroundColor(Color.white.opacity(0.80))
            
            Button(action: {
                appState.completeExerciseRoutine()
                onDismiss()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Finish & Next Morning Task")
                }
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal, 36)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.0, green: 0.92, blue: 1.0))
            .focused($focusedField, equals: .doneButton)
            
            Spacer()
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
