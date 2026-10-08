import SwiftUI

// MARK: - Reusable Stretching Exercise Illustration Container

public struct StretchingExerciseIllustrationView: View {
    public let exercise: StretchingExercise
    
    public init(exercise: StretchingExercise) {
        self.exercise = exercise
    }
    
    public var body: some View {
        ZStack {
            // Container background: Refined obsidian slate with subtle crisp border
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.12), Color(white: 0.07)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.14), lineWidth: 1.5)
            
            illustration(for: exercise)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 380)
        .clipped()
    }
    
    @ViewBuilder
    private func illustration(for exercise: StretchingExercise) -> some View {
        let normalized = exercise.name.lowercased()
        if normalized.contains("lunge") {
            LowLungeHandsInsideIllustrationView()
        } else if normalized.contains("wall") || normalized.contains("figure") {
            WallFigure4StretchIllustrationView()
        } else if normalized.contains("puppy") {
            PuppyPoseIllustrationView()
        } else if normalized.contains("side bend") || normalized.contains("bend") {
            SeatedSideBendIllustrationView()
        } else {
            LowLungeHandsInsideIllustrationView()
        }
    }
}

// MARK: - Shared Luminous Silhouette Palette (High Contrast, Zero Muddy Tones)

private let skinLight = Color(red: 0.94, green: 0.96, blue: 0.98) // Luminous silver-white highlight
private let skinMid   = Color(red: 0.78, green: 0.83, blue: 0.89) // Clean ice-silver body tone
private let skinDark  = Color(red: 0.56, green: 0.62, blue: 0.70) // Cool slate depth tone (never black)
private let jointColor = Color.white                               // Crisp pure white joint node
private let cyanNeon  = Color(red: 0.0, green: 0.92, blue: 1.0)
private let tealNeon  = Color(red: 0.0, green: 1.0, blue: 0.80)

// MARK: - 1. Low Lunge with Hands Inside (Lizard Pose)

public struct LowLungeHandsInsideIllustrationView: View {
    @State private var pulse: Bool = false
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let floorY = h * 0.82
            
            ZStack {
                // Background Grid
                Path { path in
                    for i in 1...5 {
                        let y = h * CGFloat(i) / 6.0
                        path.move(to: CGPoint(x: 20, y: y))
                        path.addLine(to: CGPoint(x: w - 20, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.02), lineWidth: 1)
                
                // Exercise Yoga Mat
                Path { path in
                    path.move(to: CGPoint(x: w * 0.10, y: floorY))
                    path.addLine(to: CGPoint(x: w * 0.90, y: floorY))
                }
                .stroke(Color.white.opacity(0.12), lineWidth: 2)
                
                // Rear foot / shin on mat
                let rearKneeX = w * 0.30
                let rearKneeY = floorY - 8
                let rearFootX = w * 0.14
                
                // Rear lower leg resting flat on floor
                Path { path in
                    path.move(to: CGPoint(x: rearKneeX, y: rearKneeY))
                    path.addLine(to: CGPoint(x: rearFootX, y: floorY - 4))
                }
                .stroke(skinMid, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                
                // Rear Foot flat on ground
                Path { path in
                    path.move(to: CGPoint(x: rearFootX, y: floorY - 4))
                    path.addLine(to: CGPoint(x: rearFootX - 18, y: floorY - 2))
                }
                .stroke(skinDark, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                
                // Rear Knee Pad / Joint indicator
                Circle()
                    .fill(jointColor)
                    .frame(width: 14, height: 14)
                    .position(x: rearKneeX, y: rearKneeY)
                
                // Pelvis / Hips sinking down & forward
                let hipX = w * 0.44
                let hipY = h * 0.58
                
                // Rear thigh angled from knee up to hip
                Path { path in
                    path.move(to: CGPoint(x: rearKneeX, y: rearKneeY))
                    path.addLine(to: CGPoint(x: hipX, y: hipY))
                }
                .stroke(
                    LinearGradient(colors: [skinLight, skinMid], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 24, lineCap: .round)
                )
                
                // Front Leg: Thigh from Hip forward to Front Knee
                let frontKneeX = w * 0.64
                let frontKneeY = h * 0.54
                let frontFootX = w * 0.66
                
                Path { path in
                    path.move(to: CGPoint(x: hipX, y: hipY))
                    path.addLine(to: CGPoint(x: frontKneeX, y: frontKneeY))
                }
                .stroke(
                    LinearGradient(colors: [skinLight, skinMid], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 24, lineCap: .round)
                )
                
                // Front Shin (vertical down to foot)
                Path { path in
                    path.move(to: CGPoint(x: frontKneeX, y: frontKneeY))
                    path.addLine(to: CGPoint(x: frontFootX, y: floorY - 6))
                }
                .stroke(skinMid, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                
                // Front Knee Joint
                Circle()
                    .fill(jointColor)
                    .frame(width: 15, height: 15)
                    .position(x: frontKneeX, y: frontKneeY)
                
                // Front Foot flat on mat
                Path { path in
                    path.move(to: CGPoint(x: frontFootX - 10, y: floorY - 4))
                    path.addLine(to: CGPoint(x: frontFootX + 24, y: floorY - 4))
                }
                .stroke(skinDark, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                
                // Torso leaning forward long spine
                let shoulderX = w * 0.54
                let shoulderY = h * 0.42
                
                Path { path in
                    path.move(to: CGPoint(x: hipX, y: hipY))
                    path.addLine(to: CGPoint(x: shoulderX, y: shoulderY))
                }
                .stroke(
                    LinearGradient(colors: [skinLight, skinMid, skinDark], startPoint: .bottom, endPoint: .top),
                    style: StrokeStyle(lineWidth: 26, lineCap: .round)
                )
                
                // Head / Neck extending spine
                let headX = shoulderX + 16
                let headY = shoulderY - 14
                
                Circle()
                    .fill(
                        LinearGradient(colors: [skinLight, skinMid], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 28, height: 28)
                    .position(x: headX, y: headY)
                
                // Arms: Hands planted inside the front foot on floor
                let handsX = w * 0.54
                let handsY = floorY - 6
                
                // Near arm
                Path { path in
                    path.move(to: CGPoint(x: shoulderX, y: shoulderY))
                    path.addLine(to: CGPoint(x: handsX, y: handsY))
                }
                .stroke(skinLight, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                
                // Far arm (slightly offset)
                Path { path in
                    path.move(to: CGPoint(x: shoulderX - 10, y: shoulderY + 4))
                    path.addLine(to: CGPoint(x: handsX - 14, y: handsY))
                }
                .stroke(skinDark, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                
                // Hands planted flat
                Capsule()
                    .fill(skinLight)
                    .frame(width: 26, height: 8)
                    .position(x: handsX - 4, y: floorY - 3)
                
                // ── Glowing Stretch Accent: Hip Flexor & Psoas Arc ──
                Path { path in
                    path.move(to: CGPoint(x: rearKneeX + 12, y: rearKneeY - 10))
                    path.addQuadCurve(
                        to: CGPoint(x: hipX + 12, y: hipY - 6),
                        control: CGPoint(x: (rearKneeX + hipX) * 0.5, y: hipY + 12)
                    )
                }
                .stroke(
                    LinearGradient(colors: [tealNeon, cyanNeon], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .shadow(color: cyanNeon.opacity(pulse ? 0.9 : 0.6), radius: pulse ? 10 : 6)
                
                // Hands Inside badge / Alignment tag
                HStack(spacing: 6) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 10))
                    Text("HANDS INSIDE FOOT")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                }
                .foregroundColor(.cyan)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.cyan.opacity(0.12))
                .cornerRadius(6)
                .position(x: handsX - 6, y: floorY - 36)
                
                // Target muscle highlight label
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.cyan)
                    Text("HIP FLEXORS & PSOAS")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(white: 0.16))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(cyanNeon.opacity(0.6), lineWidth: 1.5)
                )
                .position(x: w * 0.36, y: h * 0.44)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - 2. Wall Figure-4 Stretch

public struct WallFigure4StretchIllustrationView: View {
    @State private var pulse: Bool = false
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let floorY = h * 0.82
            let wallX = w * 0.78
            
            ZStack {
                // Background Grid
                Path { path in
                    for i in 1...5 {
                        let y = h * CGFloat(i) / 6.0
                        path.move(to: CGPoint(x: 20, y: y))
                        path.addLine(to: CGPoint(x: w - 20, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.02), lineWidth: 1)
                
                // Floor line
                Path { path in
                    path.move(to: CGPoint(x: w * 0.12, y: floorY))
                    path.addLine(to: CGPoint(x: wallX, y: floorY))
                }
                .stroke(Color.white.opacity(0.12), lineWidth: 2)
                
                // Wall vertical structure
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: 14)
                    .position(x: wallX + 7, y: h * 0.5)
                    .frame(height: h * 0.74)
                
                Path { path in
                    path.move(to: CGPoint(x: wallX, y: h * 0.14))
                    path.addLine(to: CGPoint(x: wallX, y: floorY))
                }
                .stroke(Color.white.opacity(0.20), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                
                Text("WALL")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.40))
                    .rotationEffect(.degrees(-90))
                    .position(x: wallX + 22, y: h * 0.44)
                
                // ── Body in Supine (Lying Flat on Floor) ──
                let headX = w * 0.22
                let headY = floorY - 14
                let shoulderX = w * 0.32
                let shoulderY = floorY - 12
                let hipX = w * 0.48
                let hipY = floorY - 12
                
                // Torso along floor
                Path { path in
                    path.move(to: CGPoint(x: hipX, y: hipY))
                    path.addLine(to: CGPoint(x: shoulderX, y: shoulderY))
                }
                .stroke(
                    LinearGradient(colors: [skinMid, skinLight], startPoint: .trailing, endPoint: .leading),
                    style: StrokeStyle(lineWidth: 22, lineCap: .round)
                )
                
                // Head resting on floor
                Circle()
                    .fill(skinLight)
                    .frame(width: 26, height: 26)
                    .position(x: headX, y: headY)
                
                // Relaxed arms along body
                Path { path in
                    path.move(to: CGPoint(x: shoulderX, y: shoulderY))
                    path.addLine(to: CGPoint(x: hipX - 10, y: floorY - 4))
                }
                .stroke(skinDark, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                
                // ── Base Leg: Planted Against Wall at 90° ──
                let baseKneeX = w * 0.62
                let baseKneeY = h * 0.50
                let wallFootY = baseKneeY
                
                // Thigh upward from hip to base knee
                Path { path in
                    path.move(to: CGPoint(x: hipX, y: hipY))
                    path.addLine(to: CGPoint(x: baseKneeX, y: baseKneeY))
                }
                .stroke(skinMid, style: StrokeStyle(lineWidth: 22, lineCap: .round))
                
                // Shin horizontal to foot flat on wall
                Path { path in
                    path.move(to: CGPoint(x: baseKneeX, y: baseKneeY))
                    path.addLine(to: CGPoint(x: wallX - 4, y: wallFootY))
                }
                .stroke(skinMid, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                
                // Base foot flat on wall
                Capsule()
                    .fill(skinLight)
                    .frame(width: 8, height: 28)
                    .position(x: wallX - 4, y: wallFootY)
                
                // ── Crossed Leg: Figure-4 Ankle Across Knee ──
                let crossAnkleX = baseKneeX - 6
                let crossAnkleY = baseKneeY + 12
                let crossKneeX = w * 0.46
                let crossKneeY = h * 0.44
                
                // Crossed shin across
                Path { path in
                    path.move(to: CGPoint(x: crossKneeX, y: crossKneeY))
                    path.addLine(to: CGPoint(x: crossAnkleX, y: crossAnkleY))
                }
                .stroke(skinLight, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                
                // Crossed thigh from hip up to flared knee
                Path { path in
                    path.move(to: CGPoint(x: hipX, y: hipY))
                    path.addLine(to: CGPoint(x: crossKneeX, y: crossKneeY))
                }
                .stroke(
                    LinearGradient(colors: [skinLight, skinMid], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 22, lineCap: .round)
                )
                
                // Crossed foot flexed
                Capsule()
                    .fill(skinDark)
                    .frame(width: 22, height: 8)
                    .position(x: crossAnkleX + 6, y: crossAnkleY + 8)
                
                // Knee and Ankle joints
                Circle()
                    .fill(jointColor)
                    .frame(width: 13, height: 13)
                    .position(x: crossKneeX, y: crossKneeY)
                
                Circle()
                    .fill(jointColor)
                    .frame(width: 12, height: 12)
                    .position(x: baseKneeX, y: baseKneeY)
                
                // ── Glowing Stretch Accent on Outer Glute / Piriformis ──
                Path { path in
                    path.move(to: CGPoint(x: hipX - 6, y: hipY - 14))
                    path.addQuadCurve(
                        to: CGPoint(x: crossKneeX, y: crossKneeY + 12),
                        control: CGPoint(x: hipX + 8, y: hipY - 26)
                    )
                }
                .stroke(
                    LinearGradient(colors: [tealNeon, cyanNeon], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                )
                .shadow(color: cyanNeon.opacity(pulse ? 0.95 : 0.6), radius: pulse ? 10 : 6)
                
                // 90° Wall Foot tag
                HStack(spacing: 4) {
                    Image(systemName: "square.fill")
                        .font(.system(size: 8))
                    Text("90° ON WALL")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.12))
                .cornerRadius(4)
                .position(x: wallX - 44, y: wallFootY - 24)
                
                // Muscle Target Label
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.cyan)
                    Text("PIRIFORMIS & GLUTES")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(white: 0.16))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(cyanNeon.opacity(0.6), lineWidth: 1.5)
                )
                .position(x: w * 0.40, y: h * 0.28)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - 3. Puppy Pose (Uttana Shishosana)

public struct PuppyPoseIllustrationView: View {
    @State private var pulse: Bool = false
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let floorY = h * 0.82
            
            ZStack {
                // Background Grid
                Path { path in
                    for i in 1...5 {
                        let y = h * CGFloat(i) / 6.0
                        path.move(to: CGPoint(x: 20, y: y))
                        path.addLine(to: CGPoint(x: w - 20, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.02), lineWidth: 1)
                
                // Yoga Mat on Floor
                Path { path in
                    path.move(to: CGPoint(x: w * 0.10, y: floorY))
                    path.addLine(to: CGPoint(x: w * 0.90, y: floorY))
                }
                .stroke(Color.white.opacity(0.12), lineWidth: 2)
                
                // ── Lower Body: Kneeling with HIPS DIRECTLY OVER KNEES ──
                let kneeX = w * 0.32
                let kneeY = floorY - 8
                let footX = w * 0.16
                let hipX = kneeX // Vertical thighs!
                let hipY = h * 0.50
                
                // Shins flat on floor
                Path { path in
                    path.move(to: CGPoint(x: kneeX, y: kneeY))
                    path.addLine(to: CGPoint(x: footX, y: floorY - 4))
                }
                .stroke(skinMid, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                
                // Feet flat
                Path { path in
                    path.move(to: CGPoint(x: footX, y: floorY - 4))
                    path.addLine(to: CGPoint(x: footX - 16, y: floorY - 2))
                }
                .stroke(skinDark, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                
                // Knees
                Circle()
                    .fill(jointColor)
                    .frame(width: 14, height: 14)
                    .position(x: kneeX, y: kneeY)
                
                // Thighs: Vertical alignment from knees straight up to elevated hips
                Path { path in
                    path.move(to: CGPoint(x: kneeX, y: kneeY))
                    path.addLine(to: CGPoint(x: hipX, y: hipY))
                }
                .stroke(
                    LinearGradient(colors: [skinMid, skinLight], startPoint: .bottom, endPoint: .top),
                    style: StrokeStyle(lineWidth: 24, lineCap: .round)
                )
                
                // Hip Joint indicator
                Circle()
                    .fill(jointColor)
                    .frame(width: 15, height: 15)
                    .position(x: hipX, y: hipY)
                
                // ── Torso: Arching down with chest melting to floor ──
                let shoulderX = w * 0.62
                let shoulderY = floorY - 14
                
                // Spine curve
                Path { path in
                    path.move(to: CGPoint(x: hipX, y: hipY))
                    path.addQuadCurve(
                        to: CGPoint(x: shoulderX, y: shoulderY),
                        control: CGPoint(x: hipX + 16, y: floorY - 24)
                    )
                }
                .stroke(
                    LinearGradient(colors: [skinLight, skinMid], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 24, lineCap: .round)
                )
                
                // Head / Forehead resting on mat
                let headX = shoulderX + 4
                let headY = floorY - 14
                
                Circle()
                    .fill(skinLight)
                    .frame(width: 26, height: 26)
                    .position(x: headX, y: headY)
                
                // ── Arms: Reaching straight out along mat ──
                let handsX = w * 0.84
                let handsY = floorY - 4
                
                Path { path in
                    path.move(to: CGPoint(x: shoulderX - 4, y: shoulderY))
                    path.addLine(to: CGPoint(x: handsX, y: handsY))
                }
                .stroke(
                    LinearGradient(colors: [skinLight, skinMid], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                
                // Hands flat on floor
                Capsule()
                    .fill(skinLight)
                    .frame(width: 22, height: 6)
                    .position(x: handsX + 4, y: floorY - 2)
                
                // ── Glowing Stretch Highlight: Thoracic Spine & Lats ──
                Path { path in
                    path.move(to: CGPoint(x: hipX + 10, y: hipY + 12))
                    path.addQuadCurve(
                        to: CGPoint(x: shoulderX, y: shoulderY - 6),
                        control: CGPoint(x: (hipX + shoulderX) * 0.5, y: floorY - 36)
                    )
                }
                .stroke(
                    LinearGradient(colors: [tealNeon, cyanNeon], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                )
                .shadow(color: cyanNeon.opacity(pulse ? 0.95 : 0.6), radius: pulse ? 10 : 6)
                
                // Alignment Guide: Hips over knees
                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.and.down")
                        .font(.system(size: 9))
                    Text("HIPS OVER KNEES")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                }
                .foregroundColor(.cyan)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.cyan.opacity(0.12))
                .cornerRadius(4)
                .position(x: kneeX, y: h * 0.36)
                
                // Muscle Target Label
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.cyan)
                    Text("THORACIC EXTENSION & LATS")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(white: 0.16))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(cyanNeon.opacity(0.6), lineWidth: 1.5)
                )
                .position(x: w * 0.58, y: h * 0.38)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - 4. Seated Side Bend Stretch

public struct SeatedSideBendIllustrationView: View {
    @State private var pulse: Bool = false
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let floorY = h * 0.82
            
            ZStack {
                // Background Grid
                Path { path in
                    for i in 1...5 {
                        let y = h * CGFloat(i) / 6.0
                        path.move(to: CGPoint(x: 20, y: y))
                        path.addLine(to: CGPoint(x: w - 20, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.02), lineWidth: 1)
                
                // Floor line
                Path { path in
                    path.move(to: CGPoint(x: w * 0.12, y: floorY))
                    path.addLine(to: CGPoint(x: w * 0.88, y: floorY))
                }
                .stroke(Color.white.opacity(0.12), lineWidth: 2)
                
                // ── Crossed Legs Base on Floor ──
                let pelvisX = w * 0.48
                let pelvisY = floorY - 14
                
                // Folded legs
                Path { path in
                    path.move(to: CGPoint(x: pelvisX - 70, y: floorY - 8))
                    path.addQuadCurve(
                        to: CGPoint(x: pelvisX + 70, y: floorY - 8),
                        control: CGPoint(x: pelvisX, y: floorY + 4)
                    )
                }
                .stroke(
                    LinearGradient(colors: [skinDark, skinMid, skinDark], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 24, lineCap: .round)
                )
                
                // Pelvis node
                Circle()
                    .fill(jointColor)
                    .frame(width: 16, height: 16)
                    .position(x: pelvisX, y: pelvisY)
                
                // ── Right Arm: Grounded on Floor Supporting Lateral Lean ──
                let groundHandX = w * 0.68
                let groundHandY = floorY - 4
                let rightShoulderX = w * 0.54
                let rightShoulderY = h * 0.52
                
                Path { path in
                    path.move(to: CGPoint(x: rightShoulderX, y: rightShoulderY))
                    path.addLine(to: CGPoint(x: groundHandX, y: groundHandY))
                }
                .stroke(skinMid, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                
                Capsule()
                    .fill(skinLight)
                    .frame(width: 20, height: 6)
                    .position(x: groundHandX, y: floorY - 2)
                
                // ── Torso: Arcing gracefully to the right ──
                let leftShoulderX = w * 0.44
                let leftShoulderY = h * 0.46
                
                Path { path in
                    path.move(to: CGPoint(x: pelvisX, y: pelvisY))
                    path.addQuadCurve(
                        to: CGPoint(x: leftShoulderX, y: leftShoulderY),
                        control: CGPoint(x: pelvisX + 16, y: h * 0.62)
                    )
                }
                .stroke(
                    LinearGradient(colors: [skinMid, skinLight], startPoint: .bottom, endPoint: .top),
                    style: StrokeStyle(lineWidth: 26, lineCap: .round)
                )
                
                // Head tilted with lateral spine arc
                let headX = w * 0.52
                let headY = h * 0.38
                
                Circle()
                    .fill(
                        LinearGradient(colors: [skinLight, skinMid], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 26, height: 26)
                    .position(x: headX, y: headY)
                
                // ── Left Arm: Sweeping Overhead in Long Lateral Arc ──
                let reachingHandX = w * 0.68
                let reachingHandY = h * 0.28
                
                Path { path in
                    path.move(to: CGPoint(x: leftShoulderX, y: leftShoulderY))
                    path.addQuadCurve(
                        to: CGPoint(x: reachingHandX, y: reachingHandY),
                        control: CGPoint(x: w * 0.42, y: h * 0.22)
                    )
                }
                .stroke(
                    LinearGradient(colors: [skinLight, skinMid], startPoint: .bottom, endPoint: .topTrailing),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                
                // Reaching fingertips
                Capsule()
                    .fill(skinLight)
                    .frame(width: 18, height: 6)
                    .rotationEffect(.degrees(24))
                    .position(x: reachingHandX + 4, y: reachingHandY + 2)
                
                // ── Glowing Stretch Line: Lateral Obliques, Ribs & Lats ──
                Path { path in
                    path.move(to: CGPoint(x: pelvisX - 16, y: pelvisY - 6))
                    path.addQuadCurve(
                        to: CGPoint(x: reachingHandX - 8, y: reachingHandY + 12),
                        control: CGPoint(x: w * 0.34, y: h * 0.42)
                    )
                }
                .stroke(
                    LinearGradient(colors: [tealNeon, cyanNeon], startPoint: .bottomLeading, endPoint: .topTrailing),
                    style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                )
                .shadow(color: cyanNeon.opacity(pulse ? 0.95 : 0.6), radius: pulse ? 10 : 6)
                
                // Alignment Cue
                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9))
                    Text("GROUND SIT BONES")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                }
                .foregroundColor(.cyan)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.cyan.opacity(0.12))
                .cornerRadius(4)
                .position(x: pelvisX - 30, y: floorY - 36)
                
                // Target Muscle Label
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.cyan)
                    Text("LATERAL OBLIQUES & LATS")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(white: 0.16))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(cyanNeon.opacity(0.6), lineWidth: 1.5)
                )
                .position(x: w * 0.32, y: h * 0.32)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
