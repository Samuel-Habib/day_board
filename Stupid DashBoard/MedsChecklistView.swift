import SwiftUI

public typealias MedsChecklistView = MedsChecklistModalView

public struct MedsChecklistModalView: View {
    @Bindable var appState: AppState
    @State public var selectedPeriod: HabitPeriod
    public let onDismiss: () -> Void
    public let onMedsUpdated: () -> Void
    
    @State private var showAddMedAlert: Bool = false
    @State private var newMedName: String = ""
    @State private var newMedNotes: String = ""
    
    private enum FocusField: Hashable {
        case doneButton
        case addMedButton
        case periodMorning
        case periodNight
        case medItem(UUID)
    }
    @FocusState private var focusedField: FocusField?
    
    public init(
        appState: AppState,
        period: HabitPeriod = .morning,
        onDismiss: @escaping () -> Void,
        onMedsUpdated: @escaping () -> Void
    ) {
        self.appState = appState
        self._selectedPeriod = State(initialValue: period)
        self.onDismiss = onDismiss
        self.onMedsUpdated = onMedsUpdated
    }
    
    private var filteredMeds: [MedicationItem] {
        appState.medications.filter { $0.period == selectedPeriod }
    }
    
    private var completedCount: Int {
        filteredMeds.filter { $0.isCompleted }.count
    }
    
    private var isAllCompleted: Bool {
        !filteredMeds.isEmpty && completedCount == filteredMeds.count
    }
    
    public var body: some View {
        ZStack {
            // Main Modal Card (Centered, high contrast, quiet luxury)
            VStack(spacing: 0) {
                headerView
                
                Divider()
                    .background(Color.white.opacity(0.10))
                
                medicationListView
                
                Divider()
                    .background(Color.white.opacity(0.10))
                
                bottomToolbarView
            }
            .frame(width: 860, height: 650)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.13, blue: 0.16),
                        Color(red: 0.08, green: 0.09, blue: 0.11)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(28)
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.45), radius: 36, x: 0, y: 12)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let first = filteredMeds.first {
                    focusedField = .medItem(first.id)
                } else {
                    focusedField = .doneButton
                }
            }
        }
        .onExitCommand {
            onDismiss()
        }
        .alert("Add New Medication", isPresented: $showAddMedAlert) {
            TextField("Medication name (e.g. Zinc)", text: $newMedName)
            TextField("Notes (e.g. With water)", text: $newMedNotes)
            Button("Cancel", role: .cancel) {}
            Button("Add") {
                let trimmed = newMedName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                let isOmep = trimmed.lowercased().contains("omeprazole") || trimmed.lowercased().contains("prilosec")
                let newItem = MedicationItem(
                    name: trimmed,
                    notes: newMedNotes.trimmingCharacters(in: .whitespacesAndNewlines),
                    period: selectedPeriod,
                    isCompleted: false,
                    isOmeprazole: isOmep,
                    order: filteredMeds.count
                )
                appState.addMedication(newItem)
                onMedsUpdated()
            }
        }
    }
    
    // MARK: - Header
    @ViewBuilder
    private var headerView: some View {
        HStack(alignment: .center, spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "pills.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.cyan)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) {
                    Text("MEDICATION CHECKLIST")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.white)
                        .tracking(1)
                    
                    // Progress Counter Badge
                    HStack(spacing: 6) {
                        Image(systemName: isAllCompleted ? "checkmark.circle.fill" : "clock.fill")
                            .font(.caption2)
                        Text("\(completedCount) OF \(filteredMeds.count) TAKEN")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                    }
                    .foregroundColor(isAllCompleted ? .green : .cyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background((isAllCompleted ? Color.green : Color.cyan).opacity(0.12))
                    .cornerRadius(8)
                }
                
                Text("Check off your \(selectedPeriod.rawValue.lowercased()) medications to track intake and timing")
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.75))
            }
            
            Spacer()
            
            // Morning / Night Period Switcher
            HStack(spacing: 8) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = .morning
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "sun.max.fill")
                        Text("Morning")
                            .foregroundColor(.white)
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .tint(selectedPeriod == .morning ? .cyan : Color.white.opacity(0.35))
                .focused($focusedField, equals: .periodMorning)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = .night
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.stars.fill")
                        Text("Night")
                            .foregroundColor(.white)
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .tint(selectedPeriod == .night ? .cyan : Color.white.opacity(0.35))
                .focused($focusedField, equals: .periodNight)
            }
        }
        .padding(.horizontal, 36)
        .padding(.top, 32)
        .padding(.bottom, 22)
    }
    
    // MARK: - Medication List
    @ViewBuilder
    private var medicationListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                if filteredMeds.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "cross.vial.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color.white.opacity(0.40))
                        Text("No \(selectedPeriod.rawValue.lowercased()) medications added yet.")
                            .font(.title3)
                            .foregroundColor(Color.white.opacity(0.75))
                    }
                    .frame(maxWidth: .infinity, minHeight: 220)
                } else {
                    ForEach(filteredMeds) { med in
                        medicationRowView(med: med)
                    }
                }
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Medication Row
    @ViewBuilder
    private func medicationRowView(med: MedicationItem) -> some View {
        MedicationRowItemView(
            med: med,
            isFocused: focusedField == .medItem(med.id),
            onToggle: {
                toggleMedication(med)
            },
            onDelete: {
                appState.deleteMedication(id: med.id)
                onMedsUpdated()
            }
        )
        .focused($focusedField, equals: .medItem(med.id))
    }
    
    // MARK: - Bottom Toolbar
    @ViewBuilder
    private var bottomToolbarView: some View {
        HStack(spacing: 16) {
            Button(action: {
                newMedName = ""
                newMedNotes = ""
                showAddMedAlert = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Add Medication")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            }
            .buttonStyle(.bordered)
            .focused($focusedField, equals: .addMedButton)
            
            Spacer()
            
            Button(action: {
                onDismiss()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark")
                    Text(isAllCompleted ? "Done (All Taken)" : "Done")
                }
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            }
            .buttonStyle(.borderedProminent)
            .tint(isAllCompleted ? .green : .cyan)
            .focused($focusedField, equals: .doneButton)
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 22)
    }
    
    private func toggleMedication(_ med: MedicationItem) {
        let willBeCompleted = !med.isCompleted
        appState.toggleMedication(id: med.id)
        
        // If Omeprazole was toggled, start or clear timer
        if med.isOmeprazole {
            if willBeCompleted {
                appState.startMedsTimer()
            } else {
                appState.clearMedsTimer()
            }
        }
        
        onMedsUpdated()
    }
}

// MARK: - Modular Medication Row Item View

private struct MedicationRowItemView: View {
    let med: MedicationItem
    let isFocused: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    private var rowBackground: Color {
        if isFocused {
            return Color.white.opacity(0.20)
        }
        return med.isCompleted ? Color.white.opacity(0.04) : Color.white.opacity(0.08)
    }
    
    private var strokeColor: Color {
        if isFocused {
            return Color.cyan
        }
        return med.isCompleted ? Color.green.opacity(0.35) : Color.white.opacity(0.12)
    }
    
    private var strokeWidth: CGFloat {
        isFocused ? 2.0 : 1.0
    }
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 20) {
                // Checkmark circle
                Image(systemName: med.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 32))
                    .foregroundColor(med.isCompleted ? .green : (isFocused ? .cyan : Color.white.opacity(0.45)))
                    .shadow(color: med.isCompleted ? Color.green.opacity(0.5) : Color.clear, radius: 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        Text(med.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(med.isCompleted ? Color.white.opacity(0.55) : Color.white)
                            .strikethrough(med.isCompleted)
                        
                        if med.isOmeprazole {
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .font(.caption2)
                                Text("STARTS 30M TIMER")
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.18))
                            .cornerRadius(4)
                        }
                    }
                    
                    if !med.notes.isEmpty {
                        Text(med.notes)
                            .font(.subheadline)
                            .foregroundColor(med.isCompleted ? Color.white.opacity(0.40) : Color.white.opacity(0.72))
                    }
                }
                
                Spacer()
                
                // Delete medication button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.headline)
                        .foregroundColor(Color.white.opacity(isFocused ? 0.8 : 0.45))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(strokeColor, lineWidth: strokeWidth)
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .shadow(color: isFocused ? Color.cyan.opacity(0.35) : Color.clear, radius: 10)
        }
        .buttonStyle(.plain)
    }
}
