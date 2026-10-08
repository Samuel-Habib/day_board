import SwiftUI
import AVKit

// MARK: - Reusable Exercise Animation Container

public struct FootExerciseAnimationView: View {
    public let exercise: FootExercise
    
    public init(exercise: FootExercise) {
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
            
            switch exercise.mediaType {
            case .video:
                if let url = exercise.videoURL {
                    VideoDemonstrationView(url: url, fallbackExercise: exercise)
                } else {
                    localAnimation(for: exercise)
                }
            case .instructionOnly:
                instructionOnlyDemonstration(for: exercise)
            case .animated:
                localAnimation(for: exercise)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 380)
        .clipped()
    }
    
    @ViewBuilder
    private func localAnimation(for exercise: FootExercise) -> some View {
        let normalized = exercise.name.lowercased()
        if normalized.contains("plantar") {
            PlantarFasciaStretchAnimationView()
        } else if normalized.contains("straight") {
            StraightKneeCalfStretchAnimationView()
        } else if normalized.contains("bent") {
            BentKneeCalfStretchAnimationView()
        } else if normalized.contains("raise") {
            CalfRaisesAnimationView()
        } else {
            PlantarFasciaStretchAnimationView()
        }
    }
    
    private func instructionOnlyDemonstration(for exercise: FootExercise) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk")
                .font(.system(size: 72))
                .foregroundColor(.cyan)
            
            Text(exercise.name.uppercased())
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(exercise.instruction)
                .font(.headline)
                .foregroundColor(Color.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Shared Luminous Silhouette Palette (High Contrast, Zero Muddy Tones)

private let skinLight = Color(red: 0.94, green: 0.96, blue: 0.98) // Luminous silver-white highlight
private let skinMid   = Color(red: 0.78, green: 0.83, blue: 0.89) // Clean ice-silver body tone
private let skinDark  = Color(red: 0.56, green: 0.62, blue: 0.70) // Cool slate depth tone (never black)
private let jointColor = Color.white                               // Crisp pure white joint node

// MARK: - Exercise 1: Plantar Fascia Stretch Animation
// Seated with one leg extended. Opposite hand pulls toes toward shin, stretching the plantar fascia.

public struct PlantarFasciaStretchAnimationView: View {
    @State private var stretchT: CGFloat = 0          // 0 → 1 stretch progress
    @State private var breatheT: CGFloat = 0          // subtle breathing cycle
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Subtle background grid
                Path { path in
                    for i in 1...6 {
                        let y = h * CGFloat(i) / 7.0
                        path.move(to: CGPoint(x: 20, y: y))
                        path.addLine(to: CGPoint(x: w - 20, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.02), lineWidth: 1)
                
                // Floor / Surface
                Path { path in
                    path.move(to: CGPoint(x: w * 0.10, y: h * 0.80))
                    path.addLine(to: CGPoint(x: w * 0.90, y: h * 0.80))
                }
                .stroke(Color.white.opacity(0.10), lineWidth: 2)
                
                // ── Lower Leg (shin lies along surface, ankle at right)
                let legStartX = w * 0.14
                let legEndX   = w * 0.44
                let legY      = h * 0.76
                let legThick: CGFloat = 22
                
                // Shin muscle contour (calf facing upward since leg is on surface)
                Path { path in
                    path.move(to: CGPoint(x: legStartX, y: legY))
                    // Top edge — bulge for the shin/tibialis anterior
                    path.addCurve(
                        to: CGPoint(x: legEndX, y: legY),
                        control1: CGPoint(x: legStartX + (legEndX - legStartX) * 0.35, y: legY - legThick * 0.8),
                        control2: CGPoint(x: legStartX + (legEndX - legStartX) * 0.65, y: legY - legThick * 0.5)
                    )
                    // Bottom edge — flatter underside
                    path.addCurve(
                        to: CGPoint(x: legStartX, y: legY),
                        control1: CGPoint(x: legEndX - (legEndX - legStartX) * 0.3, y: legY + legThick * 0.55),
                        control2: CGPoint(x: legStartX + (legEndX - legStartX) * 0.3, y: legY + legThick * 0.4)
                    )
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(colors: [skinLight, skinMid], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 3)
                
                // Ankle joint
                Circle()
                    .fill(jointColor)
                    .frame(width: 14, height: 14)
                    .position(x: legEndX + 2, y: legY + 2)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, y: 1)
                
                // ── Foot (pivots slightly with stretch via ankle rotation)
                let ankleX = legEndX + 2
                let ankleY = legY + 2
                let footLen: CGFloat = w * 0.22
                let footDropAngle: Double = 8 - (Double(stretchT) * 4) // foot flattens toward neutral
                
                // Foot body — anatomical shape with heel, arch, and ball
                let footGroup = footShapePath(ankleX: ankleX, ankleY: ankleY, length: footLen, dropAngle: footDropAngle)
                
                footGroup
                    .fill(
                        LinearGradient(colors: [skinLight, skinMid, skinDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 3, x: 1, y: 3)
                
                // Heel contour line
                Path { path in
                    let heelCx = ankleX - 4
                    let heelCy = ankleY + 18
                    path.move(to: CGPoint(x: heelCx - 10, y: heelCy - 6))
                    path.addQuadCurve(
                        to: CGPoint(x: heelCx - 10, y: heelCy + 10),
                        control: CGPoint(x: heelCx - 18, y: heelCy + 2)
                    )
                }
                .stroke(skinDark.opacity(0.6), lineWidth: 1.5)
                
                // ── Toes — individual toe segments that dorsiflex with stretch
                let toeBaseX = ankleX + footLen * cos(CGFloat(footDropAngle) * .pi / 180) - 6
                let toeBaseY = ankleY + footLen * sin(CGFloat(footDropAngle) * .pi / 180) - 8
                let toeAngle: Double = -28.0 * Double(stretchT) // toes pull upward
                
                ForEach(0..<4, id: \.self) { i in
                    let spread: CGFloat = CGFloat(i - 1) * 5.5
                    let toeLen: CGFloat = [22, 26, 24, 18][i]
                    let baseY = toeBaseY + spread
                    
                    Path { path in
                        let endX = toeBaseX + toeLen * cos(CGFloat(toeAngle) * .pi / 180)
                        let endY = baseY + toeLen * sin(CGFloat(toeAngle) * .pi / 180)
                        path.move(to: CGPoint(x: toeBaseX, y: baseY))
                        path.addQuadCurve(
                            to: CGPoint(x: endX, y: endY),
                            control: CGPoint(x: toeBaseX + toeLen * 0.5, y: baseY + CGFloat(toeAngle) * 0.3)
                        )
                    }
                    .stroke(skinLight, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .shadow(color: Color.black.opacity(0.15), radius: 1, y: 1)
                }
                
                // ── Plantar Fascia Band (highlight along the sole)
                let fasciaStartX = ankleX + 2
                let fasciaStartY = ankleY + 22
                let fasciaEndX = toeBaseX - 4
                let fasciaEndY = toeBaseY + 2
                let fasciaArchDepth: CGFloat = 12 + stretchT * 6
                
                Path { path in
                    path.move(to: CGPoint(x: fasciaStartX, y: fasciaStartY))
                    path.addQuadCurve(
                        to: CGPoint(x: fasciaEndX, y: fasciaEndY),
                        control: CGPoint(x: (fasciaStartX + fasciaEndX) / 2, y: fasciaStartY + fasciaArchDepth)
                    )
                }
                .stroke(
                    stretchT > 0.5
                        ? LinearGradient(colors: [.teal, .cyan, .blue], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.cyan.opacity(0.35), Color.blue.opacity(0.25)], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 3 + stretchT * 3, lineCap: .round)
                )
                .shadow(color: stretchT > 0.5 ? Color.cyan.opacity(0.7) : Color.clear, radius: 8)
                
                // Fascia tension ripples at peak stretch
                if stretchT > 0.6 {
                    ForEach(0..<3, id: \.self) { i in
                        let frac = 0.25 + Double(i) * 0.25
                        let cx = fasciaStartX + (fasciaEndX - fasciaStartX) * CGFloat(frac)
                        let cy = fasciaStartY + fasciaArchDepth * CGFloat(frac < 0.5 ? frac * 2 : (1 - frac) * 2)
                        Circle()
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                            .frame(width: 8, height: 8)
                            .position(x: cx, y: cy + 2)
                    }
                }
                
                // ── Hand pulling toes
                let handX = toeBaseX + 30 * cos(CGFloat(toeAngle - 20) * .pi / 180)
                let handY = toeBaseY + 30 * sin(CGFloat(toeAngle - 20) * .pi / 180) - 10
                
                // Forearm reaching in
                Path { path in
                    path.move(to: CGPoint(x: handX + 60, y: handY - 70 + breatheT * 3))
                    path.addQuadCurve(
                        to: CGPoint(x: handX, y: handY),
                        control: CGPoint(x: handX + 40, y: handY - 20)
                    )
                }
                .stroke(skinMid, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .shadow(color: Color.black.opacity(0.2), radius: 2, y: 2)
                
                // Hand shape (simplified palm + fingers wrapping)
                Path { path in
                    path.move(to: CGPoint(x: handX + 4, y: handY - 6))
                    path.addQuadCurve(
                        to: CGPoint(x: handX - 10, y: handY + 8),
                        control: CGPoint(x: handX - 12, y: handY - 4)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: handX + 12, y: handY + 10),
                        control: CGPoint(x: handX, y: handY + 16)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: handX + 4, y: handY - 6),
                        control: CGPoint(x: handX + 16, y: handY)
                    )
                    path.closeSubpath()
                }
                .fill(skinLight)
                .shadow(color: Color.black.opacity(0.2), radius: 2, y: 1)
                
                // Pull direction arrow
                let arrowOpacity = 0.2 + stretchT * 0.8
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.cyan)
                        Text("PULL TOES TOWARD SHIN")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.cyan.opacity(0.12))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
                }
                .offset(x: w * 0.58, y: h * 0.22)
                .opacity(arrowOpacity)
                
                // Fascia label
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.teal)
                        .frame(width: 7, height: 7)
                    Text("PLANTAR FASCIA")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundColor(.teal)
                }
                .offset(x: (fasciaStartX + fasciaEndX) / 2 - w / 2, y: fasciaStartY + fasciaArchDepth + 14 - h / 2)
                .opacity(0.4 + stretchT * 0.6)
            }
        }
        .onAppear {
            // Main stretch cycle
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                stretchT = 1.0
            }
            // Subtle breathing
            withAnimation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true)) {
                breatheT = 1.0
            }
        }
    }
    
    /// Builds an anatomically contoured foot path originating at the ankle.
    private func footShapePath(ankleX: CGFloat, ankleY: CGFloat, length: CGFloat, dropAngle: Double) -> Path {
        let rad = CGFloat(dropAngle) * .pi / 180
        let dirX = cos(rad)
        let dirY = sin(rad)
        // perpendicular (for foot thickness)
        let perpX = -dirY
        let perpY = dirX
        let thick: CGFloat = 18
        
        return Path { path in
            // Heel (behind ankle)
            let heelX = ankleX - 14 * dirX + perpY * 6
            let heelY = ankleY - 14 * dirY + perpX * 6
            path.move(to: CGPoint(x: heelX + perpX * thick * 0.5, y: heelY + perpY * thick * 0.5))
            
            // Bottom edge — heel to ball (arch)
            let ballX = ankleX + length * dirX
            let ballY = ankleY + length * dirY
            let archCtrlX = ankleX + length * 0.5 * dirX + perpX * thick * 0.6
            let archCtrlY = ankleY + length * 0.5 * dirY + perpY * thick * 0.6
            path.addQuadCurve(
                to: CGPoint(x: ballX + perpX * thick * 0.3, y: ballY + perpY * thick * 0.3),
                control: CGPoint(x: archCtrlX, y: archCtrlY)
            )
            
            // Ball round
            path.addQuadCurve(
                to: CGPoint(x: ballX - perpX * thick * 0.3, y: ballY - perpY * thick * 0.3),
                control: CGPoint(x: ballX + dirX * 8, y: ballY + dirY * 8)
            )
            
            // Top edge — ball back to ankle (instep)
            let instepCtrlX = ankleX + length * 0.4 * dirX - perpX * thick * 0.55
            let instepCtrlY = ankleY + length * 0.4 * dirY - perpY * thick * 0.55
            path.addQuadCurve(
                to: CGPoint(x: heelX - perpX * thick * 0.35, y: heelY - perpY * thick * 0.35),
                control: CGPoint(x: instepCtrlX, y: instepCtrlY)
            )
            
            // Heel back-curve
            path.addQuadCurve(
                to: CGPoint(x: heelX + perpX * thick * 0.5, y: heelY + perpY * thick * 0.5),
                control: CGPoint(x: heelX - dirX * 12, y: heelY - dirY * 12)
            )
            path.closeSubpath()
        }
    }
}

// MARK: - Exercise 2: Straight-Knee Calf Stretch Animation
// Standing wall stretch — rear leg straight, heel locked, leaning into wall targets gastrocnemius.

public struct StraightKneeCalfStretchAnimationView: View {
    @State private var leanT: CGFloat = 0          // 0 → 1 lean progress
    @State private var breatheT: CGFloat = 0
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let groundY = h * 0.84
            let wallX = w * 0.22
            
            ZStack {
                // Wall surface (textured fill)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.06), Color.white.opacity(0.03)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: 10)
                    .position(x: wallX, y: h * 0.5)
                    .frame(height: h * 0.72)
                
                // Wall edge
                Path { path in
                    path.move(to: CGPoint(x: wallX + 5, y: h * 0.14))
                    path.addLine(to: CGPoint(x: wallX + 5, y: groundY))
                }
                .stroke(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                
                Text("WALL")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.40))
                    .rotationEffect(.degrees(-90))
                    .position(x: wallX - 18, y: h * 0.42)
                
                // Ground
                Path { path in
                    path.move(to: CGPoint(x: w * 0.12, y: groundY))
                    path.addLine(to: CGPoint(x: w * 0.92, y: groundY))
                }
                .stroke(Color.white.opacity(0.12), lineWidth: 2)
                
                // ── Figure skeleton points ──
                let hipX = w * 0.52 - leanT * 28
                let hipY = groundY - h * 0.44 + breatheT * 2
                
                let shoulderX = hipX - 18 - leanT * 14
                let shoulderY = hipY - h * 0.22 + breatheT * 1
                
                let headX = shoulderX - 10
                let headY = shoulderY - 28
                
                // Rear leg — STRAIGHT from hip to heel
                let rearHeelX = w * 0.74
                let rearAnkleX = rearHeelX - 4
                let rearAnkleY = groundY - 16
                
                // Front leg — bent at knee
                let frontFootX = w * 0.36 - leanT * 10
                let frontKneeX = frontFootX + 14 - leanT * 6
                let frontKneeY = groundY - h * 0.18
                
                // ── Rear Foot ──
                rearFootShape(heelX: rearHeelX, groundY: groundY, len: 52)
                    .fill(LinearGradient(colors: [skinLight, skinMid], startPoint: .top, endPoint: .bottom))
                    .shadow(color: Color.black.opacity(0.3), radius: 3, y: 2)
                
                // Heel planted badge
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                    Text("HEEL DOWN")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.12))
                .cornerRadius(4)
                .position(x: rearHeelX + 30, y: groundY + 16)
                
                // ── Rear Leg (straight) — anatomical thigh + shank ──
                // Shank (ankle to knee-ish midpoint, but since leg is straight it's ankle to hip)
                let rearLegMidX = (hipX + rearAnkleX) / 2
                let rearLegMidY = (hipY + rearAnkleY) / 2
                
                // Full rear leg as a contoured limb
                Path { path in
                    // Outer edge (front of leg)
                    path.move(to: CGPoint(x: hipX + 10, y: hipY + 5))
                    path.addCurve(
                        to: CGPoint(x: rearAnkleX + 8, y: rearAnkleY),
                        control1: CGPoint(x: rearLegMidX + 14, y: rearLegMidY - 20),
                        control2: CGPoint(x: rearAnkleX + 12, y: rearAnkleY - 40)
                    )
                    // Ankle
                    path.addQuadCurve(
                        to: CGPoint(x: rearAnkleX - 8, y: rearAnkleY),
                        control: CGPoint(x: rearAnkleX, y: rearAnkleY + 6)
                    )
                    // Inner edge (back of leg — calf)
                    path.addCurve(
                        to: CGPoint(x: hipX - 6, y: hipY + 5),
                        control1: CGPoint(x: rearAnkleX - 14, y: rearAnkleY - 45),
                        control2: CGPoint(x: rearLegMidX - 18, y: rearLegMidY - 15)
                    )
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(colors: [skinLight, skinMid, skinDark], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: -1, y: 3)
                
                // Ankle joint
                Circle()
                    .fill(jointColor)
                    .frame(width: 12, height: 12)
                    .position(x: rearAnkleX, y: rearAnkleY)
                
                // ── Gastrocnemius muscle highlight (upper-mid calf, bulges out) ──
                let gastroTopY = rearLegMidY - h * 0.06
                let gastroBotY = rearLegMidY + h * 0.10
                let gastroBulge: CGFloat = 12 + leanT * 10
                
                Path { path in
                    path.move(to: CGPoint(x: rearLegMidX - 12, y: gastroTopY))
                    path.addCurve(
                        to: CGPoint(x: rearLegMidX - 8, y: gastroBotY),
                        control1: CGPoint(x: rearLegMidX - 12 - gastroBulge, y: gastroTopY + (gastroBotY - gastroTopY) * 0.35),
                        control2: CGPoint(x: rearLegMidX - 8 - gastroBulge * 0.6, y: gastroTopY + (gastroBotY - gastroTopY) * 0.7)
                    )
                }
                .stroke(
                    leanT > 0.5
                        ? LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color.orange.opacity(0.3), Color.yellow.opacity(0.2)], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: leanT > 0.5 ? 5 : 2.5, lineCap: .round)
                )
                .shadow(color: leanT > 0.5 ? Color.orange.opacity(0.6) : Color.clear, radius: 8)
                
                // Achilles tendon line
                Path { path in
                    path.move(to: CGPoint(x: rearAnkleX - 6, y: rearAnkleY - 2))
                    path.addLine(to: CGPoint(x: rearLegMidX - 10, y: gastroBotY))
                }
                .stroke(Color.orange.opacity(leanT > 0.3 ? 0.5 : 0.15), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                
                // ── Front Leg (bent knee, lunge position) ──
                frontLegShape(hipX: hipX, hipY: hipY, kneeX: frontKneeX, kneeY: frontKneeY, footX: frontFootX, groundY: groundY)
                    .fill(LinearGradient(colors: [skinMid, skinDark], startPoint: .top, endPoint: .bottom))
                    .shadow(color: Color.black.opacity(0.2), radius: 3, y: 2)
                
                // Front foot
                rearFootShape(heelX: frontFootX - 8, groundY: groundY, len: 42)
                    .fill(skinMid)
                
                // Knee joint
                Circle()
                    .fill(jointColor)
                    .frame(width: 11, height: 11)
                    .position(x: frontKneeX, y: frontKneeY)
                
                // ── Torso ──
                Path { path in
                    path.move(to: CGPoint(x: hipX - 4, y: hipY))
                    path.addLine(to: CGPoint(x: hipX + 8, y: hipY))
                    path.addCurve(
                        to: CGPoint(x: shoulderX + 12, y: shoulderY),
                        control1: CGPoint(x: hipX + 4, y: hipY - 30),
                        control2: CGPoint(x: shoulderX + 14, y: shoulderY + 30)
                    )
                    path.addLine(to: CGPoint(x: shoulderX - 8, y: shoulderY))
                    path.addCurve(
                        to: CGPoint(x: hipX - 4, y: hipY),
                        control1: CGPoint(x: shoulderX - 8, y: shoulderY + 25),
                        control2: CGPoint(x: hipX - 6, y: hipY - 25)
                    )
                    path.closeSubpath()
                }
                .fill(LinearGradient(colors: [skinLight.opacity(0.9), skinMid], startPoint: .top, endPoint: .bottom))
                .shadow(color: Color.black.opacity(0.2), radius: 3, y: 2)
                
                // Hip joint
                Circle()
                    .fill(jointColor)
                    .frame(width: 12, height: 12)
                    .position(x: hipX + 2, y: hipY + 2)
                
                // ── Head ──
                Ellipse()
                    .fill(
                        RadialGradient(colors: [skinLight, skinMid], center: .center, startRadius: 2, endRadius: 18)
                    )
                    .frame(width: 30, height: 34)
                    .position(x: headX, y: headY)
                    .shadow(color: Color.black.opacity(0.2), radius: 3, y: 2)
                
                // ── Arms extended to wall ──
                // Upper arm
                Path { path in
                    path.move(to: CGPoint(x: shoulderX, y: shoulderY + 6))
                    path.addQuadCurve(
                        to: CGPoint(x: wallX + 8, y: shoulderY + 4),
                        control: CGPoint(x: (shoulderX + wallX) / 2, y: shoulderY - 8)
                    )
                }
                .stroke(skinMid, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .shadow(color: Color.black.opacity(0.15), radius: 2, y: 1)
                
                // Hand flat on wall
                RoundedRectangle(cornerRadius: 3)
                    .fill(skinLight)
                    .frame(width: 14, height: 18)
                    .position(x: wallX + 10, y: shoulderY + 4)
                
                // ── Instruction Badge ──
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.cyan)
                        Text("KEEP REAR KNEE STRAIGHT")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.cyan.opacity(0.12))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
                }
                .position(x: w * 0.60, y: h * 0.16)
                .opacity(0.3 + leanT * 0.7)
                
                // Gastrocnemius label
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                    Text("GASTROCNEMIUS")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundColor(.orange)
                }
                .position(x: rearLegMidX - 50, y: (gastroTopY + gastroBotY) / 2)
                .opacity(0.3 + leanT * 0.7)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                leanT = 1.0
            }
            withAnimation(.easeInOut(duration: 3.6).repeatForever(autoreverses: true)) {
                breatheT = 1.0
            }
        }
    }
    
    /// Flat foot planted on ground, heel at heelX
    private func rearFootShape(heelX: CGFloat, groundY: CGFloat, len: CGFloat) -> Path {
        Path { path in
            path.move(to: CGPoint(x: heelX - 6, y: groundY))
            // Sole
            path.addLine(to: CGPoint(x: heelX - 6 - len * 0.3, y: groundY))
            // Toes curve
            path.addQuadCurve(
                to: CGPoint(x: heelX - 6 - len * 0.35, y: groundY - 12),
                control: CGPoint(x: heelX - 6 - len * 0.42, y: groundY - 3)
            )
            // Top of foot
            path.addQuadCurve(
                to: CGPoint(x: heelX + 2, y: groundY - 16),
                control: CGPoint(x: heelX - len * 0.15, y: groundY - 18)
            )
            // Heel round
            path.addQuadCurve(
                to: CGPoint(x: heelX - 6, y: groundY),
                control: CGPoint(x: heelX + 6, y: groundY - 4)
            )
            path.closeSubpath()
        }
    }
    
    /// Front leg with bent knee
    private func frontLegShape(hipX: CGFloat, hipY: CGFloat, kneeX: CGFloat, kneeY: CGFloat, footX: CGFloat, groundY: CGFloat) -> Path {
        Path { path in
            let thick: CGFloat = 8
            // Thigh outer
            path.move(to: CGPoint(x: hipX + thick, y: hipY + 8))
            path.addLine(to: CGPoint(x: kneeX + thick, y: kneeY))
            // Shank outer
            path.addLine(to: CGPoint(x: footX + thick * 0.6, y: groundY - 14))
            // Bottom across ankle
            path.addLine(to: CGPoint(x: footX - thick * 0.6, y: groundY - 14))
            // Shank inner
            path.addLine(to: CGPoint(x: kneeX - thick, y: kneeY))
            // Thigh inner
            path.addLine(to: CGPoint(x: hipX - thick * 0.5, y: hipY + 8))
            path.closeSubpath()
        }
    }
}

// MARK: - Exercise 3: Bent-Knee Calf Stretch Animation
// Standing wall stretch — rear knee bends forward, heel stays planted. Targets the deeper soleus muscle.

public struct BentKneeCalfStretchAnimationView: View {
    @State private var bendT: CGFloat = 0
    @State private var breatheT: CGFloat = 0
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let groundY = h * 0.84
            let wallX = w * 0.22
            
            ZStack {
                // Wall surface
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.06), Color.white.opacity(0.03)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: 10)
                    .position(x: wallX, y: h * 0.5)
                    .frame(height: h * 0.72)
                
                Path { path in
                    path.move(to: CGPoint(x: wallX + 5, y: h * 0.14))
                    path.addLine(to: CGPoint(x: wallX + 5, y: groundY))
                }
                .stroke(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                
                Text("WALL")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.40))
                    .rotationEffect(.degrees(-90))
                    .position(x: wallX - 18, y: h * 0.42)
                
                // Ground
                Path { path in
                    path.move(to: CGPoint(x: w * 0.12, y: groundY))
                    path.addLine(to: CGPoint(x: w * 0.92, y: groundY))
                }
                .stroke(Color.white.opacity(0.12), lineWidth: 2)
                
                // ── Figure skeleton ──
                let hipX = w * 0.50 - bendT * 14
                let hipY = groundY - h * 0.40 + bendT * 18 + breatheT * 2
                
                let shoulderX = hipX - 16 - bendT * 8
                let shoulderY = hipY - h * 0.22 + breatheT * 1
                
                let headX = shoulderX - 8
                let headY = shoulderY - 28
                
                // Rear leg — BENT at knee
                let rearHeelX = w * 0.72
                let rearAnkleX = rearHeelX - 4
                let rearAnkleY = groundY - 16
                let rearKneeX = (hipX + rearAnkleX) / 2 - bendT * 30
                let rearKneeY = (hipY + rearAnkleY) / 2 + bendT * 8
                
                // Front leg
                let frontFootX = w * 0.36 - bendT * 6
                let frontKneeX = frontFootX + 10 - bendT * 4
                let frontKneeY = groundY - h * 0.16
                
                // ── Rear Foot ──
                rearFootShape(heelX: rearHeelX, groundY: groundY, len: 50)
                    .fill(LinearGradient(colors: [skinLight, skinMid], startPoint: .top, endPoint: .bottom))
                    .shadow(color: Color.black.opacity(0.3), radius: 3, y: 2)
                
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                    Text("HEEL DOWN")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.12))
                .cornerRadius(4)
                .position(x: rearHeelX + 30, y: groundY + 16)
                
                // ── Rear Leg — thigh (hip to knee) ──
                Path { path in
                    let thick: CGFloat = 10
                    path.move(to: CGPoint(x: hipX + thick, y: hipY + 6))
                    path.addCurve(
                        to: CGPoint(x: rearKneeX + thick * 0.8, y: rearKneeY),
                        control1: CGPoint(x: hipX + thick + 4, y: hipY + 30),
                        control2: CGPoint(x: rearKneeX + thick + 6, y: rearKneeY - 20)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: rearKneeX - thick * 0.8, y: rearKneeY),
                        control: CGPoint(x: rearKneeX, y: rearKneeY + 6)
                    )
                    path.addCurve(
                        to: CGPoint(x: hipX - thick * 0.6, y: hipY + 6),
                        control1: CGPoint(x: rearKneeX - thick - 2, y: rearKneeY - 15),
                        control2: CGPoint(x: hipX - thick, y: hipY + 25)
                    )
                    path.closeSubpath()
                }
                .fill(LinearGradient(colors: [skinLight, skinMid], startPoint: .top, endPoint: .bottom))
                .shadow(color: Color.black.opacity(0.25), radius: 3, y: 2)
                
                // ── Rear Leg — shank (knee to ankle) with soleus contour ──
                Path { path in
                    let thick: CGFloat = 9
                    // Outer edge
                    path.move(to: CGPoint(x: rearKneeX + thick, y: rearKneeY + 2))
                    path.addCurve(
                        to: CGPoint(x: rearAnkleX + 7, y: rearAnkleY),
                        control1: CGPoint(x: rearKneeX + thick + 4, y: rearKneeY + 30),
                        control2: CGPoint(x: rearAnkleX + 10, y: rearAnkleY - 30)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: rearAnkleX - 7, y: rearAnkleY),
                        control: CGPoint(x: rearAnkleX, y: rearAnkleY + 5)
                    )
                    // Inner edge — calf belly (soleus bulges here)
                    let calfBulge: CGFloat = 6 + bendT * 10
                    path.addCurve(
                        to: CGPoint(x: rearKneeX - thick, y: rearKneeY + 2),
                        control1: CGPoint(x: rearAnkleX - 12, y: rearAnkleY - 35),
                        control2: CGPoint(x: rearKneeX - thick - calfBulge, y: rearKneeY + 30)
                    )
                    path.closeSubpath()
                }
                .fill(LinearGradient(colors: [skinMid, skinDark], startPoint: .top, endPoint: .bottom))
                .shadow(color: Color.black.opacity(0.25), radius: 3, y: 2)
                
                // Rear knee joint
                Circle()
                    .fill(jointColor)
                    .frame(width: 13, height: 13)
                    .position(x: rearKneeX, y: rearKneeY)
                
                // Rear ankle joint
                Circle()
                    .fill(jointColor)
                    .frame(width: 11, height: 11)
                    .position(x: rearAnkleX, y: rearAnkleY)
                
                // ── Soleus + Achilles stretch highlight ──
                let soleusMidY = (rearKneeY + rearAnkleY) / 2
                let soleusBulge: CGFloat = 10 + bendT * 12
                
                Path { path in
                    path.move(to: CGPoint(x: rearKneeX - 8, y: rearKneeY + 12))
                    path.addCurve(
                        to: CGPoint(x: rearAnkleX - 5, y: rearAnkleY - 4),
                        control1: CGPoint(x: rearKneeX - 8 - soleusBulge, y: soleusMidY - 10),
                        control2: CGPoint(x: rearAnkleX - 5 - soleusBulge * 0.5, y: soleusMidY + 20)
                    )
                }
                .stroke(
                    bendT > 0.4
                        ? LinearGradient(colors: [.indigo, .cyan], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color.indigo.opacity(0.25), Color.cyan.opacity(0.15)], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: bendT > 0.4 ? 5 : 2.5, lineCap: .round)
                )
                .shadow(color: bendT > 0.4 ? Color.cyan.opacity(0.6) : Color.clear, radius: 8)
                
                // Achilles tendon
                Path { path in
                    path.move(to: CGPoint(x: rearAnkleX - 4, y: rearAnkleY - 2))
                    path.addLine(to: CGPoint(x: rearAnkleX - 6, y: rearAnkleY - 28))
                }
                .stroke(Color.cyan.opacity(bendT > 0.3 ? 0.5 : 0.15), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                
                // ── Front Leg ──
                frontLegPath(hipX: hipX, hipY: hipY, kneeX: frontKneeX, kneeY: frontKneeY, ankleY: groundY - 14, thick: 8)
                    .fill(LinearGradient(colors: [skinMid, skinDark], startPoint: .top, endPoint: .bottom))
                    .shadow(color: Color.black.opacity(0.2), radius: 3, y: 2)
                
                rearFootShape(heelX: frontFootX - 6, groundY: groundY, len: 40)
                    .fill(skinMid)
                
                Circle()
                    .fill(jointColor)
                    .frame(width: 10, height: 10)
                    .position(x: frontKneeX, y: frontKneeY)
                
                // ── Torso ──
                Path { path in
                    path.move(to: CGPoint(x: hipX - 4, y: hipY))
                    path.addLine(to: CGPoint(x: hipX + 8, y: hipY))
                    path.addCurve(
                        to: CGPoint(x: shoulderX + 12, y: shoulderY),
                        control1: CGPoint(x: hipX + 4, y: hipY - 30),
                        control2: CGPoint(x: shoulderX + 14, y: shoulderY + 30)
                    )
                    path.addLine(to: CGPoint(x: shoulderX - 8, y: shoulderY))
                    path.addCurve(
                        to: CGPoint(x: hipX - 4, y: hipY),
                        control1: CGPoint(x: shoulderX - 8, y: shoulderY + 25),
                        control2: CGPoint(x: hipX - 6, y: hipY - 25)
                    )
                    path.closeSubpath()
                }
                .fill(LinearGradient(colors: [skinLight.opacity(0.9), skinMid], startPoint: .top, endPoint: .bottom))
                .shadow(color: Color.black.opacity(0.2), radius: 3, y: 2)
                
                Circle()
                    .fill(jointColor)
                    .frame(width: 12, height: 12)
                    .position(x: hipX + 2, y: hipY + 2)
                
                // Head
                Ellipse()
                    .fill(RadialGradient(colors: [skinLight, skinMid], center: .center, startRadius: 2, endRadius: 18))
                    .frame(width: 30, height: 34)
                    .position(x: headX, y: headY)
                    .shadow(color: Color.black.opacity(0.2), radius: 3, y: 2)
                
                // Arms to wall
                Path { path in
                    path.move(to: CGPoint(x: shoulderX, y: shoulderY + 6))
                    path.addQuadCurve(
                        to: CGPoint(x: wallX + 8, y: shoulderY + 4),
                        control: CGPoint(x: (shoulderX + wallX) / 2, y: shoulderY - 8)
                    )
                }
                .stroke(skinMid, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .shadow(color: Color.black.opacity(0.15), radius: 2, y: 1)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(skinLight)
                    .frame(width: 14, height: 18)
                    .position(x: wallX + 10, y: shoulderY + 4)
                
                // ── Instruction Badge ──
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.right")
                            .foregroundColor(.cyan)
                        Text("BEND REAR KNEE • SOLEUS STRETCH")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.cyan.opacity(0.12))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
                }
                .position(x: w * 0.58, y: h * 0.14)
                .opacity(0.3 + bendT * 0.7)
                
                // Soleus label
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.indigo)
                        .frame(width: 6, height: 6)
                    Text("SOLEUS")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundColor(.indigo)
                }
                .position(x: rearKneeX - 55 - soleusBulge, y: soleusMidY)
                .opacity(0.3 + bendT * 0.7)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                bendT = 1.0
            }
            withAnimation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true)) {
                breatheT = 1.0
            }
        }
    }
    
    private func rearFootShape(heelX: CGFloat, groundY: CGFloat, len: CGFloat) -> Path {
        Path { path in
            path.move(to: CGPoint(x: heelX - 6, y: groundY))
            path.addLine(to: CGPoint(x: heelX - 6 - len * 0.3, y: groundY))
            path.addQuadCurve(
                to: CGPoint(x: heelX - 6 - len * 0.35, y: groundY - 12),
                control: CGPoint(x: heelX - 6 - len * 0.42, y: groundY - 3)
            )
            path.addQuadCurve(
                to: CGPoint(x: heelX + 2, y: groundY - 16),
                control: CGPoint(x: heelX - len * 0.15, y: groundY - 18)
            )
            path.addQuadCurve(
                to: CGPoint(x: heelX - 6, y: groundY),
                control: CGPoint(x: heelX + 6, y: groundY - 4)
            )
            path.closeSubpath()
        }
    }
    
    private func frontLegPath(hipX: CGFloat, hipY: CGFloat, kneeX: CGFloat, kneeY: CGFloat, ankleY: CGFloat, thick: CGFloat) -> Path {
        Path { path in
            path.move(to: CGPoint(x: hipX + thick, y: hipY + 8))
            path.addLine(to: CGPoint(x: kneeX + thick, y: kneeY))
            path.addLine(to: CGPoint(x: kneeX + thick * 0.6, y: ankleY))
            path.addLine(to: CGPoint(x: kneeX - thick * 0.6, y: ankleY))
            path.addLine(to: CGPoint(x: kneeX - thick, y: kneeY))
            path.addLine(to: CGPoint(x: hipX - thick * 0.5, y: hipY + 8))
            path.closeSubpath()
        }
    }
}

// MARK: - Exercise 4: Calf Raises Animation
// Standing on both feet, heels rise onto balls of feet (concentric), pause at peak,
// then lower under control (eccentric). Targets gastrocnemius + soleus.

public struct CalfRaisesAnimationView: View {
    @State private var liftT: CGFloat = 0  // 0 = flat, 1 = peak
    @State private var breatheT: CGFloat = 0
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let groundY = h * 0.84
            
            let heelLift: CGFloat = liftT * 48
            let isAtPeak = liftT > 0.7
            
            ZStack {
                // Ground
                Path { path in
                    path.move(to: CGPoint(x: w * 0.15, y: groundY))
                    path.addLine(to: CGPoint(x: w * 0.85, y: groundY))
                }
                .stroke(Color.white.opacity(0.12), lineWidth: 2)
                
                // Step edge (optional — shows they can do this off a step)
                Path { path in
                    path.move(to: CGPoint(x: w * 0.30, y: groundY))
                    path.addLine(to: CGPoint(x: w * 0.30, y: groundY + 6))
                    path.addLine(to: CGPoint(x: w * 0.70, y: groundY + 6))
                    path.addLine(to: CGPoint(x: w * 0.70, y: groundY))
                }
                .stroke(Color.white.opacity(0.06), lineWidth: 1.5)
                
                // Ball-of-foot anchor line
                Path { path in
                    path.move(to: CGPoint(x: w * 0.42, y: groundY))
                    path.addLine(to: CGPoint(x: w * 0.58, y: groundY))
                }
                .stroke(Color.cyan.opacity(0.4), lineWidth: 3)
                
                // ── Feet (side view, both overlapping) ──
                let footCenterX = w * 0.50
                let ballX = footCenterX + 12
                let heelX = footCenterX - 35
                let heelY = groundY - heelLift
                let ankleX = footCenterX - 10
                let ankleY = groundY - 20 - heelLift * 0.8
                
                // Foot shape that pivots around ball of foot
                Path { path in
                    // Heel (rises)
                    path.move(to: CGPoint(x: heelX, y: heelY))
                    // Sole — arch from heel to ball
                    path.addQuadCurve(
                        to: CGPoint(x: ballX, y: groundY),
                        control: CGPoint(x: footCenterX - 5, y: min(heelY, groundY) - 10 - heelLift * 0.15)
                    )
                    // Toes
                    path.addQuadCurve(
                        to: CGPoint(x: ballX + 22, y: groundY),
                        control: CGPoint(x: ballX + 16, y: groundY + 4)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: ballX + 16, y: groundY - 10),
                        control: CGPoint(x: ballX + 24, y: groundY - 6)
                    )
                    // Top of foot
                    path.addQuadCurve(
                        to: CGPoint(x: ankleX + 8, y: ankleY + 10),
                        control: CGPoint(x: ballX - 4, y: ankleY + 4)
                    )
                    // Down to ankle
                    path.addLine(to: CGPoint(x: ankleX - 8, y: ankleY + 10))
                    // Back of ankle / Achilles to heel
                    path.addQuadCurve(
                        to: CGPoint(x: heelX, y: heelY),
                        control: CGPoint(x: heelX - 6, y: (ankleY + heelY) / 2)
                    )
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(colors: [skinLight, skinMid, skinDark], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 4, y: 3)
                
                // Ankle joint
                Circle()
                    .fill(jointColor)
                    .frame(width: 11, height: 11)
                    .position(x: ankleX, y: ankleY + 10)
                
                // ── Lower Leg (shank) — from ankle up ──
                let kneeY = ankleY - h * 0.24
                let kneeX = ankleX + 2
                
                // Shank with calf muscle contour
                Path { path in
                    let thick: CGFloat = 10
                    // Front (shin)
                    path.move(to: CGPoint(x: ankleX + thick * 0.7, y: ankleY + 8))
                    path.addCurve(
                        to: CGPoint(x: kneeX + thick, y: kneeY),
                        control1: CGPoint(x: ankleX + thick + 2, y: ankleY - 30),
                        control2: CGPoint(x: kneeX + thick + 4, y: kneeY + 40)
                    )
                    // Across knee
                    path.addQuadCurve(
                        to: CGPoint(x: kneeX - thick, y: kneeY),
                        control: CGPoint(x: kneeX, y: kneeY + 5)
                    )
                    // Back (calf muscle) — bigger bulge when contracted
                    let calfBulge: CGFloat = 10 + liftT * 14
                    let calfPeakY = ankleY - (ankleY - kneeY) * 0.55
                    path.addCurve(
                        to: CGPoint(x: ankleX - thick * 0.7, y: ankleY + 8),
                        control1: CGPoint(x: kneeX - thick - 4, y: kneeY + 30),
                        control2: CGPoint(x: ankleX - thick - calfBulge, y: calfPeakY)
                    )
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(colors: [skinLight, skinMid, skinDark], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: -1, y: 3)
                
                // Knee joint
                Circle()
                    .fill(jointColor)
                    .frame(width: 12, height: 12)
                    .position(x: kneeX, y: kneeY)
                
                // ── Calf Muscle Contraction Glow ──
                let calfPeakY = ankleY - (ankleY - kneeY) * 0.55
                let calfBulge: CGFloat = 10 + liftT * 14
                
                Path { path in
                    path.move(to: CGPoint(x: ankleX - 10, y: kneeY + 25))
                    path.addCurve(
                        to: CGPoint(x: ankleX - 8, y: ankleY - 15),
                        control1: CGPoint(x: ankleX - 10 - calfBulge - 4, y: calfPeakY - 10),
                        control2: CGPoint(x: ankleX - 8 - calfBulge * 0.4, y: calfPeakY + 30)
                    )
                }
                .stroke(
                    isAtPeak
                        ? LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color.orange.opacity(0.25), Color.yellow.opacity(0.15)], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: isAtPeak ? 5 : 2.5, lineCap: .round)
                )
                .shadow(color: isAtPeak ? Color.orange.opacity(0.7) : Color.clear, radius: 10)
                
                // Achilles tendon highlight
                Path { path in
                    path.move(to: CGPoint(x: ankleX - 6, y: ankleY + 6))
                    path.addLine(to: CGPoint(x: heelX + 6, y: heelY + 2))
                }
                .stroke(
                    isAtPeak ? Color.orange.opacity(0.6) : Color.orange.opacity(0.15),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                
                // ── Upper thigh (partial, fading into frame top) ──
                Path { path in
                    let thick: CGFloat = 12
                    path.move(to: CGPoint(x: kneeX + thick, y: kneeY - 2))
                    path.addLine(to: CGPoint(x: kneeX + thick + 2, y: kneeY - 80))
                    path.addLine(to: CGPoint(x: kneeX - thick - 2, y: kneeY - 80))
                    path.addLine(to: CGPoint(x: kneeX - thick, y: kneeY - 2))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [skinMid.opacity(0.0), skinMid.opacity(0.5), skinMid],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                
                // ── Elevation indicator ──
                if heelLift > 4 {
                    // Dashed line from ground to heel
                    Path { path in
                        path.move(to: CGPoint(x: heelX - 14, y: groundY))
                        path.addLine(to: CGPoint(x: heelX - 14, y: heelY))
                    }
                    .stroke(Color.cyan.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    
                    // Height value
                    Text(String(format: "%.0f%%", liftT * 100))
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundColor(.cyan.opacity(0.7))
                        .position(x: heelX - 30, y: (groundY + heelY) / 2)
                }
                
                // ── Instruction Badge ──
                if isAtPeak {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                            Text("RISE • HOLD AT PEAK")
                        }
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.cyan.opacity(0.12))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .position(x: w * 0.50, y: h * 0.10)
                    .transition(.opacity)
                } else {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                            Text("CONTROLLED LOWERING")
                        }
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.80))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(6)
                    }
                    .position(x: w * 0.50, y: h * 0.10)
                    .transition(.opacity)
                }
                
                // Calf label
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                    Text("CALF")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundColor(.orange)
                }
                .position(x: ankleX - 10 - calfBulge - 20, y: calfPeakY)
                .opacity(0.3 + liftT * 0.7)
            }
        }
        .onAppear {
            startCycle()
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                breatheT = 1.0
            }
        }
    }
    
    private func startCycle() {
        // Rise phase
        withAnimation(.easeInOut(duration: 1.6)) {
            liftT = 1.0
        }
        // Schedule lower after hold
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeInOut(duration: 1.8)) {
                liftT = 0.0
            }
            // Schedule next rise
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                startCycle()
            }
        }
    }
}

// MARK: - Video Demonstration Fallback
struct VideoDemonstrationView: View {
    let url: URL
    let fallbackExercise: FootExercise
    @State private var hasError = false
    
    var body: some View {
        Group {
            if hasError {
                // Silently fallback to local animation
                PlantarFasciaStretchAnimationView()
            } else {
                VideoPlayer(player: AVPlayer(url: url))
                    .onAppear {
                        // Silent fallback guard
                    }
            }
        }
    }
}
