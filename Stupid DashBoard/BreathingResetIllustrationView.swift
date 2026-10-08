import SwiftUI

// MARK: - Ventilatory Reset: 15 Physiological Sighs Interactive Engine

public struct BreathingResetIllustrationView: View {
    public let onComplete: () -> Void
    
    @State private var currentSigh: Int = 1
    @State private var breathingPhase: BreathPhase = .inhaleNose
    @State private var circleScale: CGFloat = 0.55
    @State private var circleOpacity: Double = 0.6
    @State private var phaseTimer: Timer?
    @State private var isAutoPlaying: Bool = true
    
    private let totalSighs = 15
    
    public enum BreathPhase: String {
        case inhaleNose = "Deep Inhale (Nose)"
        case inhaleTopOff = "Sharp Top-Off Inhale"
        case exhaleMouth = "Long Unforced Exhale (Mouth)"
        
        public var cue: String {
            switch self {
            case .inhaleNose:
                return "1. Smooth, deep inhale through your nose"
            case .inhaleTopOff:
                return "2. Quick extra sharp sip of air at the top"
            case .exhaleMouth:
                return "3. Slow, unforced sigh out through your mouth"
            }
        }
    }
    
    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            // Container with refined obsidian styling
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.12), Color(white: 0.07)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.cyan.opacity(0.35), lineWidth: 1.5)
                
                VStack(spacing: 20) {
                    // Header Status
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "wind")
                                .foregroundColor(.cyan)
                            Text("CO₂ CLEARANCE PROTOCOL")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .tracking(2)
                                .foregroundColor(.cyan)
                        }
                        
                        Spacer()
                        
                        Text("SIGH \(currentSigh) OF \(totalSighs)")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 20)
                    
                    // Central Pulsating Lung / Circle Visualizer
                    ZStack {
                        // Outer Ambient Halo
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.cyan.opacity(0.30), Color.clear],
                                    center: .center,
                                    startRadius: 40,
                                    endRadius: 160
                                )
                            )
                            .scaleEffect(circleScale * 1.35)
                        
                        // Expanding / Contracting Core Breathing Ring
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color(red: 0.0, green: 0.95, blue: 1.0), Color(red: 0.0, green: 0.7, blue: 0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 14
                            )
                            .background(
                                Circle()
                                    .fill(Color.cyan.opacity(0.12))
                            )
                            .frame(width: 170, height: 170)
                            .scaleEffect(circleScale)
                            .opacity(circleOpacity)
                        
                        // Phase Label Inside Circle
                        VStack(spacing: 4) {
                            Image(systemName: phaseIcon)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(breathingPhase.rawValue.uppercased())
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .tracking(1)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 14)
                        }
                    }
                    .frame(height: 210)
                    
                    // Instructional Prompt & Physiological Rationale
                    VStack(spacing: 6) {
                        Text(breathingPhase.cue)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Reopens collapsed alveoli & stops compensatory cerebral vasodilation caused by retained CO₂.")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // Segmented Progress Dots
                    HStack(spacing: 6) {
                        ForEach(1...totalSighs, id: \.self) { i in
                            Circle()
                                .fill(i < currentSigh ? Color.green : (i == currentSigh ? Color.cyan : Color.white.opacity(0.2)))
                                .frame(width: i == currentSigh ? 10 : 7, height: i == currentSigh ? 10 : 7)
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 380)
            
            // Interactive Controls
            HStack(spacing: 20) {
                Button(action: nextSigh) {
                    HStack(spacing: 8) {
                        Image(systemName: "forward.fill")
                        Text(currentSigh < totalSighs ? "Next Sigh (\(currentSigh + 1)/\(totalSighs))" : "Finish Breath Reset")
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                
                Button(action: onComplete) {
                    Text("Skip / Mark Complete")
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.60))
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            startBreathingCycle()
        }
        .onDisappear {
            stopBreathingCycle()
        }
    }
    
    private var phaseIcon: String {
        switch breathingPhase {
        case .inhaleNose: return "arrow.up.circle.fill"
        case .inhaleTopOff: return "plus.circle.fill"
        case .exhaleMouth: return "arrow.down.circle.fill"
        }
    }
    
    // MARK: - Breathing Cycle Timing
    private func startBreathingCycle() {
        runPhaseSequence()
    }
    
    private func stopBreathingCycle() {
        phaseTimer?.invalidate()
        phaseTimer = nil
    }
    
    private func runPhaseSequence() {
        // Step 1: Deep Inhale (2.0s)
        breathingPhase = .inhaleNose
        withAnimation(.easeInOut(duration: 2.0)) {
            circleScale = 1.05
            circleOpacity = 0.95
        }
        
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            // Step 2: Top-Off Inhale (1.0s)
            self.breathingPhase = .inhaleTopOff
            withAnimation(.easeInOut(duration: 1.0)) {
                self.circleScale = 1.25
                self.circleOpacity = 1.0
            }
            
            self.phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                // Step 3: Long Exhale (5.0s)
                self.breathingPhase = .exhaleMouth
                withAnimation(.easeInOut(duration: 5.0)) {
                    self.circleScale = 0.55
                    self.circleOpacity = 0.55
                }
                
                self.phaseTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                    // Automatically increment sigh count if autoplays
                    if self.isAutoPlaying {
                        if self.currentSigh < self.totalSighs {
                            self.currentSigh += 1
                            self.runPhaseSequence()
                        } else {
                            self.onComplete()
                        }
                    }
                }
            }
        }
    }
    
    private func nextSigh() {
        stopBreathingCycle()
        if currentSigh < totalSighs {
            currentSigh += 1
            runPhaseSequence()
        } else {
            onComplete()
        }
    }
}
