import SwiftUI

// MARK: - Jaw & Suboccipital Decompression Interactive Engine

public struct JawSuboccipitalIllustrationView: View {
    public let onComplete: () -> Void
    
    @State private var selectedTechnique: Int = 0 // 0: Masseter Knuckles, 1: Occipital Traction
    @State private var masseterReps: Int = 0
    @State private var tractionSeconds: Int = 20
    @State private var isTractionTiming: Bool = false
    @State private var timer: Timer?
    
    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Container Card
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
                    .stroke(Color(red: 0.0, green: 0.92, blue: 1.0).opacity(0.35), lineWidth: 1.5)
                
                VStack(spacing: 16) {
                    // Switcher Tabs
                    HStack(spacing: 16) {
                        Button(action: {
                            selectedTechnique = 0
                            stopTractionTimer()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "hand.raised.fill")
                                Text("1. Masseter Knuckle Drop")
                            }
                            .font(.headline)
                            .foregroundColor(selectedTechnique == 0 ? .white : Color.white.opacity(0.55))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedTechnique == 0 ? Color.cyan.opacity(0.25) : Color.clear)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            selectedTechnique = 1
                            startTractionTimer()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.up.and.down.and.sparkles")
                                Text("2. Occipital Traction Lift")
                            }
                            .font(.headline)
                            .foregroundColor(selectedTechnique == 1 ? .white : Color.white.opacity(0.55))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedTechnique == 1 ? Color(red: 0.0, green: 0.92, blue: 1.0).opacity(0.25) : Color.clear)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 16)
                    
                    // Anatomical Diagram View
                    if selectedTechnique == 0 {
                        masseterDiagramView
                    } else {
                        occipitalDiagramView
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 380)
            
            // Bottom Action
            HStack(spacing: 24) {
                if selectedTechnique == 0 {
                    Button(action: {
                        if masseterReps < 5 {
                            masseterReps += 1
                        }
                        if masseterReps >= 5 {
                            selectedTechnique = 1
                            startTractionTimer()
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "mouth.fill")
                            Text("Log Jaw Open (\(masseterReps)/5)")
                        }
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                } else {
                    Button(action: onComplete) {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                            Text(tractionSeconds == 0 ? "Complete Jaw & Neck Protocol" : "Traction Hold: \(tractionSeconds)s (Complete)")
                        }
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.0, green: 0.92, blue: 1.0))
                }
                
                Button(action: onComplete) {
                    Text("Skip Protocol")
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.50))
                }
                .buttonStyle(.plain)
            }
        }
        .onDisappear {
            stopTractionTimer()
        }
    }
    
    // MARK: - Diagram 1: Masseter Knuckle Drop
    private var masseterDiagramView: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Anatomical Head Silhouette Outline (Side Profile)
                Path { path in
                    // Forehead -> Nose -> Lips -> Chin -> Jawline -> Ear
                    path.move(to: CGPoint(x: w * 0.44, y: h * 0.20))
                    path.addQuadCurve(to: CGPoint(x: w * 0.52, y: h * 0.35), control: CGPoint(x: w * 0.50, y: h * 0.25))
                    path.addLine(to: CGPoint(x: w * 0.56, y: h * 0.45)) // nose
                    path.addLine(to: CGPoint(x: w * 0.51, y: h * 0.52)) // lip
                    path.addLine(to: CGPoint(x: w * 0.53, y: h * 0.62)) // chin
                    path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.68)) // jawline
                    path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.48)) // ear
                    path.closeSubpath()
                }
                .fill(Color(white: 0.16))
                
                // Target Masseter Muscle Highlight
                Circle()
                    .fill(Color.cyan.opacity(0.35))
                    .frame(width: 44, height: 44)
                    .position(x: w * 0.44, y: h * 0.56)
                
                // Knuckles Contact Point Indicator
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .background(Circle().fill(Color.cyan))
                    .frame(width: 18, height: 18)
                    .position(x: w * 0.44, y: h * 0.56)
                
                // Downward Opening Motion Arrow
                Image(systemName: "arrow.down")
                    .font(.title2)
                    .foregroundColor(.white)
                    .position(x: w * 0.53, y: h * 0.72)
                
                // Labels & Cue
                VStack(spacing: 4) {
                    Text("MASSETER KNUCKLE DROP")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(.cyan)
                    
                    Text("Place knuckles below cheekbones; slowly open mouth wide 5 times.")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Relieves temporalis guarding & stops nocturnal grinding tension.")
                        .font(.caption2)
                        .foregroundColor(Color.white.opacity(0.65))
                }
                .position(x: w * 0.50, y: h * 0.10)
            }
        }
    }
    
    // MARK: - Diagram 2: Occipital Traction Lift
    private var occipitalDiagramView: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Lateral Cervical Spine Silhouette
                Path { path in
                    // Base of skull to upper cervical spine
                    path.move(to: CGPoint(x: w * 0.40, y: h * 0.30))
                    path.addQuadCurve(to: CGPoint(x: w * 0.48, y: h * 0.65), control: CGPoint(x: w * 0.42, y: h * 0.48))
                    path.addLine(to: CGPoint(x: w * 0.52, y: h * 0.65))
                    path.addQuadCurve(to: CGPoint(x: w * 0.46, y: h * 0.30), control: CGPoint(x: w * 0.48, y: h * 0.48))
                    path.closeSubpath()
                }
                .fill(Color(white: 0.16))
                
                // Suboccipital Ridge Highlight
                Capsule()
                    .fill(Color(red: 0.0, green: 0.92, blue: 1.0).opacity(0.40))
                    .frame(width: 50, height: 18)
                    .position(x: w * 0.42, y: h * 0.42)
                
                // Traction Lift Vector (Upward & Forward Arrow)
                VStack(spacing: 2) {
                    Image(systemName: "arrow.up")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.0, green: 0.92, blue: 1.0))
                    Text("UPWARD LIFT")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(Color(red: 0.0, green: 0.92, blue: 1.0))
                }
                .position(x: w * 0.35, y: h * 0.36)
                
                // Chin Tuck Indicator
                HStack(spacing: 4) {
                    Image(systemName: "arrow.backward")
                        .foregroundColor(.yellow)
                    Text("CHIN TUCK")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(.yellow)
                }
                .position(x: w * 0.60, y: h * 0.52)
                
                // Instructions
                VStack(spacing: 4) {
                    Text("OCCIPITAL TRACTION")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(Color(red: 0.0, green: 0.92, blue: 1.0))
                    
                    Text("Interlace hands at base of skull, tuck chin, and lift gently upward.")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Decompresses suboccipital spasms & C1-C2 nerve impingement.")
                        .font(.caption2)
                        .foregroundColor(Color.white.opacity(0.65))
                }
                .position(x: w * 0.50, y: h * 0.10)
            }
        }
    }
    
    private func startTractionTimer() {
        stopTractionTimer()
        isTractionTiming = true
        tractionSeconds = 20
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if tractionSeconds > 0 {
                tractionSeconds -= 1
            } else {
                stopTractionTimer()
            }
        }
    }
    
    private func stopTractionTimer() {
        timer?.invalidate()
        timer = nil
        isTractionTiming = false
    }
}
