import SwiftUI

// MARK: - Reusable Bodyweight Exercise Illustration Container

public struct BodyweightExerciseIllustrationView: View {
    public let exercise: BodyweightExercise
    
    public init(exercise: BodyweightExercise) {
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
    private func illustration(for exercise: BodyweightExercise) -> some View {
        let normalized = exercise.name.lowercased()
        if normalized.contains("pushup") || normalized.contains("push up") {
            PushupIllustrationView()
        } else if normalized.contains("squat") {
            AirSquatIllustrationView()
        } else if normalized.contains("plank") {
            PlankHoldIllustrationView()
        } else {
            PushupIllustrationView()
        }
    }
}

// MARK: - Shared Luminous Silhouette Palette

private let skinLight = Color(red: 0.94, green: 0.96, blue: 0.98) // Luminous silver-white highlight
private let skinMid   = Color(red: 0.78, green: 0.83, blue: 0.89) // Clean ice-silver body tone
private let skinDark  = Color(red: 0.56, green: 0.62, blue: 0.70) // Cool slate depth tone
private let jointColor = Color.white                               // Crisp pure white joint node
private let cyanNeon  = Color(red: 0.0, green: 0.92, blue: 1.0)
private let tealNeon  = Color(red: 0.0, green: 1.0, blue: 0.80)

// MARK: - 1. Standard Pushup Illustration

public struct PushupIllustrationView: View {
    @State private var pulse: Bool = false
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let floorY = h * 0.78
            
            ZStack {
                // Exercise Mat / Ground Line
                Path { path in
                    path.move(to: CGPoint(x: w * 0.08, y: floorY))
                    path.addLine(to: CGPoint(x: w * 0.92, y: floorY))
                }
                .stroke(Color.white.opacity(0.18), lineWidth: 2.5)
                
                // Key anatomical coordinates
                let footX = w * 0.22
                let footY = floorY - 6
                let kneeX = w * 0.38
                let kneeY = floorY - 26
                let hipX = w * 0.50
                let hipY = floorY - 38
                let shoulderX = w * 0.72
                let shoulderY = floorY - 48
                let headX = w * 0.83
                let headY = floorY - 55
                
                let handX = w * 0.68
                let handY = floorY
                let elbowX = w * 0.63
                let elbowY = floorY - 28
                
                // Torso & Legs line (rigid plank)
                Path { path in
                    path.move(to: CGPoint(x: footX, y: footY))
                    path.addLine(to: CGPoint(x: kneeX, y: kneeY))
                    path.addLine(to: CGPoint(x: hipX, y: hipY))
                    path.addLine(to: CGPoint(x: shoulderX, y: shoulderY))
                }
                .stroke(skinMid, style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round))
                
                // Arms (Pushup press angle)
                Path { path in
                    path.move(to: CGPoint(x: shoulderX, y: shoulderY))
                    path.addLine(to: CGPoint(x: elbowX, y: elbowY))
                    path.addLine(to: CGPoint(x: handX, y: handY))
                }
                .stroke(skinLight, style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round))
                
                // Neck & Head
                Path { path in
                    path.move(to: CGPoint(x: shoulderX, y: shoulderY))
                    path.addLine(to: CGPoint(x: headX, y: headY))
                }
                .stroke(skinLight, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                
                Circle()
                    .fill(skinLight)
                    .frame(width: 26, height: 26)
                    .position(x: headX + 4, y: headY - 4)
                
                // Joint nodes
                ForEach([
                    CGPoint(x: footX, y: footY),
                    CGPoint(x: kneeX, y: kneeY),
                    CGPoint(x: hipX, y: hipY),
                    CGPoint(x: shoulderX, y: shoulderY),
                    CGPoint(x: elbowX, y: elbowY),
                    CGPoint(x: handX, y: handY)
                ], id: \.x) { pt in
                    Circle()
                        .fill(jointColor)
                        .frame(width: 8, height: 8)
                        .position(pt)
                }
                
                // Target muscle callout tags
                HStack(spacing: 12) {
                    Text("CHEST & TRICEPS")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(cyanNeon)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(cyanNeon.opacity(0.18))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(cyanNeon.opacity(0.4), lineWidth: 1)
                        )
                    
                    Text("CORE STABILITY")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(tealNeon)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(tealNeon.opacity(0.18))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(tealNeon.opacity(0.4), lineWidth: 1)
                        )
                }
                .position(x: w * 0.50, y: h * 0.18)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulse.toggle()
            }
        }
    }
}

// MARK: - 2. Bodyweight Air Squat Illustration

public struct AirSquatIllustrationView: View {
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let floorY = h * 0.82
            
            ZStack {
                // Ground Line
                Path { path in
                    path.move(to: CGPoint(x: w * 0.15, y: floorY))
                    path.addLine(to: CGPoint(x: w * 0.85, y: floorY))
                }
                .stroke(Color.white.opacity(0.18), lineWidth: 2.5)
                
                // Squat anatomy: ankles, knees tracking forward, hips sunk back, upright chest, arms out
                let footX = w * 0.52
                let footY = floorY - 4
                let kneeX = w * 0.62
                let kneeY = floorY - 50
                let hipX = w * 0.38
                let hipY = floorY - 54
                let shoulderX = w * 0.44
                let shoulderY = floorY - 128
                let headX = w * 0.45
                let headY = floorY - 156
                
                let elbowX = w * 0.56
                let elbowY = floorY - 126
                let handX = w * 0.68
                let handY = floorY - 124
                
                // Lower leg
                Path { path in
                    path.move(to: CGPoint(x: footX, y: footY))
                    path.addLine(to: CGPoint(x: kneeX, y: kneeY))
                }
                .stroke(skinMid, style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round))
                
                // Thigh (parallel to floor)
                Path { path in
                    path.move(to: CGPoint(x: kneeX, y: kneeY))
                    path.addLine(to: CGPoint(x: hipX, y: hipY))
                }
                .stroke(skinMid, style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                
                // Torso (upright angle)
                Path { path in
                    path.move(to: CGPoint(x: hipX, y: hipY))
                    path.addLine(to: CGPoint(x: shoulderX, y: shoulderY))
                }
                .stroke(skinLight, style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                
                // Arms reaching forward for balance
                Path { path in
                    path.move(to: CGPoint(x: shoulderX, y: shoulderY))
                    path.addLine(to: CGPoint(x: elbowX, y: elbowY))
                    path.addLine(to: CGPoint(x: handX, y: handY))
                }
                .stroke(skinLight, style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                
                // Head
                Circle()
                    .fill(skinLight)
                    .frame(width: 28, height: 28)
                    .position(x: headX, y: headY)
                
                // Joint nodes
                ForEach([
                    CGPoint(x: footX, y: footY),
                    CGPoint(x: kneeX, y: kneeY),
                    CGPoint(x: hipX, y: hipY),
                    CGPoint(x: shoulderX, y: shoulderY),
                    CGPoint(x: elbowX, y: elbowY),
                    CGPoint(x: handX, y: handY)
                ], id: \.x) { pt in
                    Circle()
                        .fill(jointColor)
                        .frame(width: 8, height: 8)
                        .position(pt)
                }
                
                // Muscle tags
                HStack(spacing: 12) {
                    Text("QUADRICEPS & GLUTES")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(cyanNeon)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(cyanNeon.opacity(0.18))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(cyanNeon.opacity(0.4), lineWidth: 1)
                        )
                    
                    Text("HIP MOBILITY")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(tealNeon)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(tealNeon.opacity(0.18))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(tealNeon.opacity(0.4), lineWidth: 1)
                        )
                }
                .position(x: w * 0.50, y: h * 0.18)
            }
        }
    }
}

// MARK: - 3. Forearm Plank Hold Illustration

public struct PlankHoldIllustrationView: View {
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let floorY = h * 0.78
            
            ZStack {
                // Ground Line
                Path { path in
                    path.move(to: CGPoint(x: w * 0.08, y: floorY))
                    path.addLine(to: CGPoint(x: w * 0.92, y: floorY))
                }
                .stroke(Color.white.opacity(0.18), lineWidth: 2.5)
                
                let footX = w * 0.20
                let footY = floorY - 6
                let kneeX = w * 0.36
                let kneeY = floorY - 22
                let hipX = w * 0.50
                let hipY = floorY - 32
                let shoulderX = w * 0.70
                let shoulderY = floorY - 42
                let headX = w * 0.81
                let headY = floorY - 45
                
                let elbowX = w * 0.70
                let elbowY = floorY
                let handX = w * 0.78
                let handY = floorY
                
                // Rigid body line
                Path { path in
                    path.move(to: CGPoint(x: footX, y: footY))
                    path.addLine(to: CGPoint(x: kneeX, y: kneeY))
                    path.addLine(to: CGPoint(x: hipX, y: hipY))
                    path.addLine(to: CGPoint(x: shoulderX, y: shoulderY))
                }
                .stroke(skinMid, style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round))
                
                // Forearm grounded
                Path { path in
                    path.move(to: CGPoint(x: shoulderX, y: shoulderY))
                    path.addLine(to: CGPoint(x: elbowX, y: elbowY))
                    path.addLine(to: CGPoint(x: handX, y: handY))
                }
                .stroke(skinLight, style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round))
                
                // Head
                Circle()
                    .fill(skinLight)
                    .frame(width: 26, height: 26)
                    .position(x: headX, y: headY)
                
                // Joint nodes
                ForEach([
                    CGPoint(x: footX, y: footY),
                    CGPoint(x: kneeX, y: kneeY),
                    CGPoint(x: hipX, y: hipY),
                    CGPoint(x: shoulderX, y: shoulderY),
                    CGPoint(x: elbowX, y: elbowY),
                    CGPoint(x: handX, y: handY)
                ], id: \.x) { pt in
                    Circle()
                        .fill(jointColor)
                        .frame(width: 8, height: 8)
                        .position(pt)
                }
                
                // Muscle tags
                HStack(spacing: 12) {
                    Text("TRANSVERSE CORE")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(cyanNeon)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(cyanNeon.opacity(0.18))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(cyanNeon.opacity(0.4), lineWidth: 1)
                        )
                    
                    Text("ISOMETRIC ENDURANCE")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(tealNeon)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(tealNeon.opacity(0.18))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(tealNeon.opacity(0.4), lineWidth: 1)
                        )
                }
                .position(x: w * 0.50, y: h * 0.18)
            }
        }
    }
}
