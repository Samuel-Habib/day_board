import SwiftUI

public struct SettingsView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAddMorningAlert = false
    @State private var showAddNightAlert = false
    @State private var showAddDailyAlert = false
    @State private var newMorningTitle = ""
    @State private var newNightTitle = ""
    @State private var newDailyTitle = ""
    
    @State private var editingTaskID: UUID?
    @State private var editingIsNightTask = false
    @State private var showRenameAlert = false
    @State private var renameTitle = ""
    
    // Timekeeping API State
    @State private var showApiKeyAlert = false
    @State private var apiKeyInput = ""
    @State private var showTestResultAlert = false
    @State private var testResultText = ""
    @State private var selectedSessionForSummary: RoutineSession?
    
    // Backend Persistence Server State
    @State private var showBackendServerAlert = false
    @State private var serverUrlInput = ""
    @State private var showBackendResultAlert = false
    @State private var backendResultText = ""
    
    // Foot Routine Settings
    @State private var showFootRoutineSettings = false
    @State private var showStretchingRoutineSettings = false
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        NavigationStack {
            HStack(spacing: 40) {
                morningColumn
                nightColumn
                dailyColumn
            }
            .padding()
            .navigationTitle("Configuration")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarTrailingItems
                }
            }
            .alert("Add Morning Habit", isPresented: $showAddMorningAlert) {
                TextField("Task Title", text: $newMorningTitle)
                Button("Add") {
                    appState.addMorningTask(title: newMorningTitle)
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Add Night Habit", isPresented: $showAddNightAlert) {
                TextField("Task Title", text: $newNightTitle)
                Button("Add") {
                    appState.addNightTask(title: newNightTitle)
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Add Daily Task", isPresented: $showAddDailyAlert) {
                TextField("Task Title", text: $newDailyTitle)
                Button("Add") {
                    appState.addDailyTask(title: newDailyTitle)
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Rename Habit", isPresented: $showRenameAlert) {
                TextField("Task Title", text: $renameTitle)
                Button("Save") {
                    if let id = editingTaskID {
                        if editingIsNightTask {
                            appState.updateNightTaskTitle(id: id, newTitle: renameTitle)
                        } else {
                            appState.updateMorningTaskTitle(id: id, newTitle: renameTitle)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Time Sync Key", isPresented: $showApiKeyAlert) {
                TextField("Sync Key", text: $apiKeyInput)
                Button("Save & Verify") {
                    appState.setTimekeepingApiKey(apiKeyInput)
                    Task {
                        do {
                            let success = try await TimekeepingService.shared.testConnection(apiKey: apiKeyInput)
                            await MainActor.run {
                                testResultText = success ? "Connection Verified! Focus sessions will synchronize automatically." : "Could not verify connection."
                                showTestResultAlert = true
                            }
                        } catch {
                            await MainActor.run {
                                testResultText = "Error: \(error.localizedDescription)"
                                showTestResultAlert = true
                            }
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter your key to enable background time synchronization.")
            }
            .alert("API Status", isPresented: $showTestResultAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(testResultText)
            }
            .alert("Backend Persistence Server", isPresented: $showBackendServerAlert) {
                TextField("http://100.113.33.28:8080", text: $serverUrlInput)
                Button("Save & Test") {
                    appState.backendServerUrl = serverUrlInput
                    Task {
                        do {
                            let healthy = try await DashboardPersistenceService.shared.testConnection()
                            await appState.syncStateWithServer()
                            await MainActor.run {
                                backendResultText = healthy ? "Connected to backend server at \(appState.backendServerUrl)! State synchronized." : "Server responded with an unexpected status."
                                showBackendResultAlert = true
                            }
                        } catch {
                            await MainActor.run {
                                backendResultText = "Connection error: \(error.localizedDescription)"
                                showBackendResultAlert = true
                            }
                        }
                    }
                }
                Button("Sync Now") {
                    Task {
                        await appState.syncStateWithServer()
                        await appState.fetchServerState()
                        await MainActor.run {
                            backendResultText = "State synchronized with \(appState.backendServerUrl)."
                            showBackendResultAlert = true
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Tailscale Backend Server (default: http://100.113.33.28:8080). Synchronizes morning routines, habits, and medications.")
            }
            .alert("Server Status", isPresented: $showBackendResultAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(backendResultText)
            }
            .fullScreenCover(item: $selectedSessionForSummary) { session in
                RoutineSummaryView(session: session) {
                    selectedSessionForSummary = nil
                }
            }
            .sheet(isPresented: $showFootRoutineSettings) {
                FootRoutineSettingsView(appState: appState)
            }
            .sheet(isPresented: $showStretchingRoutineSettings) {
                StretchingRoutineSettingsView(appState: appState)
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var morningColumn: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Morning Habits")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(appState.currentMorningMode.rawValue) • \(appState.currentMorningMode.estimatedMinutes)m")
                        .font(.caption2)
                        .foregroundColor(Color(red: 1.0, green: 0.78, blue: 0.2))
                }
                Spacer()
                Button(action: {
                    appState.morningTasks = AppState.defaultMorningSchedule()
                    appState.saveMorningTasks()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                }
                Button(action: {
                    newMorningTitle = ""
                    showAddMorningAlert = true
                }) {
                    Image(systemName: "plus")
                }
            }
            .padding(.horizontal)
            
            List {
                ForEach(appState.morningTasks) { task in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.body)
                                .fontWeight(.semibold)
                            if let deadline = task.targetDeadlineTime {
                                Text("\(deadline) • \(task.durationMinutes ?? 10)m")
                                    .font(.caption2)
                                    .foregroundColor(Color(red: 1.0, green: 0.78, blue: 0.2))
                            }
                        }
                        Spacer()
                        Button(action: {
                            editingTaskID = task.id
                            editingIsNightTask = false
                            renameTitle = task.title
                            showRenameAlert = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(Color.white.opacity(0.60))
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 10)
                    }
                }
                .onDelete { indexSet in
                    appState.deleteMorningTask(at: indexSet)
                }
                .onMove { indices, newOffset in
                    appState.moveMorningTask(from: indices, to: newOffset)
                }
            }
            .environment(\.editMode, .constant(.active))
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var nightColumn: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Night Habits")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    newNightTitle = ""
                    showAddNightAlert = true
                }) {
                    Image(systemName: "plus")
                }
            }
            .padding(.horizontal)
            
            List {
                ForEach(appState.nightTasks) { task in
                    HStack {
                        Text(task.title)
                            .font(.body)
                        Spacer()
                        Button(action: {
                            editingTaskID = task.id
                            editingIsNightTask = true
                            renameTitle = task.title
                            showRenameAlert = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(Color.white.opacity(0.60))
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 10)
                    }
                }
                .onDelete { indexSet in
                    appState.deleteNightTask(at: indexSet)
                }
                .onMove { indices, newOffset in
                    appState.moveNightTask(from: indices, to: newOffset)
                }
            }
            .environment(\.editMode, .constant(.active))
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var dailyColumn: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Today's Tasks")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    newDailyTitle = ""
                    showAddDailyAlert = true
                }) {
                    Image(systemName: "plus")
                }
            }
            .padding(.horizontal)
            
            List {
                ForEach(appState.todayDailyTasks) { task in
                    Text(task.title)
                        .font(.body)
                }
                .onDelete { indexSet in
                    let todayTasks = appState.todayDailyTasks
                    for index in indexSet {
                        let task = todayTasks[index]
                        appState.deleteDailyTask(id: task.id)
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var toolbarTrailingItems: some View {
        HStack(spacing: 16) {
            Button(action: {
                showFootRoutineSettings = true
            }) {
                Label("Foot Rehab", systemImage: "shoeprints.fill")
            }
            
            Button(action: {
                showStretchingRoutineSettings = true
            }) {
                Label("Stretching", systemImage: "figure.flexibility")
            }
            
            Button(action: {
                serverUrlInput = appState.backendServerUrl
                showBackendServerAlert = true
            }) {
                Label(
                    appState.isServerReachable ? "Server Online" : "Backend Server",
                    systemImage: appState.isServerReachable ? "network" : "network.slash"
                )
            }
            
            Button(action: {
                apiKeyInput = appState.timekeepingApiKey
                showApiKeyAlert = true
            }) {
                Label(appState.timekeepingApiKey.isEmpty ? "Time Sync" : "Sync Active", systemImage: "clock.badge.checkmark")
            }
            
            Button(action: {
                dismiss()
                appState.lastDismissedNightCycle = ""
                UserDefaults.standard.removeObject(forKey: "lastDismissedNightCycle")
                appState.trigger10PMNightModePreview()
            }) {
                Label("Test 10 PM Alert", systemImage: "moon.stars.fill")
            }
        }
    }
}

// MARK: - Foot Routine Settings View

public struct FootRoutineSettingsView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FOOT REHABILITATION CONFIGURATION")
                            .font(.title3)
                            .fontWeight(.black)
                            .tracking(1)
                        
                        Text("Customize plantar-fasciitis exercises, duration, sets, and demo styles")
                            .font(.headline)
                            .foregroundColor(Color.white.opacity(0.75))
                    }
                    
                    Spacer()
                    
                    Button("Reset to Defaults") {
                        appState.resetFootExercisesToDefault()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 40)
                .padding(.top, 24)
                
                List {
                    ForEach($appState.footExercises) { $exercise in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center, spacing: 16) {
                                Toggle(isOn: $exercise.isEnabled) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(exercise.name)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                        Text(exercise.instruction)
                                            .font(.subheadline)
                                            .foregroundColor(Color.white.opacity(0.75))
                                            .lineLimit(2)
                                    }
                                }
                                .toggleStyle(.switch)
                            }
                            
                            if exercise.isEnabled {
                                HStack(spacing: 24) {
                                    // Sets adjustment
                                    HStack(spacing: 8) {
                                        Text("Sets:")
                                            .font(.caption)
                                            .fontWeight(.heavy)
                                            .foregroundColor(Color.white.opacity(0.70))
                                        
                                        Picker("Sets", selection: $exercise.sets) {
                                            Text("1").tag(1)
                                            Text("2").tag(2)
                                            Text("3").tag(3)
                                        }
                                        .pickerStyle(.segmented)
                                        .frame(width: 180)
                                    }
                                    
                                    if exercise.isTimed {
                                        // Duration adjustment
                                        HStack(spacing: 8) {
                                            Text("Duration:")
                                                .font(.caption)
                                                .fontWeight(.heavy)
                                                .foregroundColor(Color.white.opacity(0.70))
                                            
                                            Picker("Duration", selection: Binding(
                                                get: { exercise.targetSeconds ?? 30 },
                                                set: { exercise.targetSeconds = $0 }
                                            )) {
                                                Text("15s").tag(15)
                                                Text("20s").tag(20)
                                                Text("30s").tag(30)
                                                Text("45s").tag(45)
                                                Text("60s").tag(60)
                                            }
                                            .pickerStyle(.segmented)
                                            .frame(width: 300)
                                        }
                                    } else {
                                        // Reps adjustment
                                        HStack(spacing: 8) {
                                            Text("Reps:")
                                                .font(.caption)
                                                .fontWeight(.heavy)
                                                .foregroundColor(Color.white.opacity(0.70))
                                            
                                            Picker("Reps", selection: Binding(
                                                get: { exercise.targetReps ?? 12 },
                                                set: { exercise.targetReps = $0 }
                                            )) {
                                                Text("8").tag(8)
                                                Text("10").tag(10)
                                                Text("12").tag(12)
                                                Text("15").tag(15)
                                                Text("20").tag(20)
                                            }
                                            .pickerStyle(.segmented)
                                            .frame(width: 300)
                                        }
                                    }
                                    
                                    // Media type picker
                                    HStack(spacing: 8) {
                                        Text("Demo:")
                                            .font(.caption)
                                            .fontWeight(.heavy)
                                            .foregroundColor(Color.white.opacity(0.70))
                                        
                                        Picker("Demo", selection: $exercise.mediaType) {
                                            ForEach(FootExerciseMediaType.allCases) { type in
                                                Text(type.rawValue).tag(type)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                        .frame(width: 320)
                                    }
                                }
                                .padding(.top, 2)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onMove { indices, newOffset in
                        appState.footExercises.move(fromOffsets: indices, toOffset: newOffset)
                        for i in 0..<appState.footExercises.count {
                            appState.footExercises[i].order = i
                        }
                        appState.saveFootExercises()
                    }
                }
                .environment(\.editMode, .constant(.active))
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        appState.saveFootExercises()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Stretching Routine Settings View

public struct StretchingRoutineSettingsView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Guided Stretching & Mobility Protocol").font(.headline)) {
                    ForEach($appState.stretchingExercises) { $exercise in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(exercise.name)
                                    .font(.headline)
                                Spacer()
                                Toggle("", isOn: $exercise.isEnabled)
                                    .labelsHidden()
                            }
                            
                            if let purpose = exercise.purpose {
                                Text(purpose)
                                    .font(.caption)
                                    .foregroundColor(Color.white.opacity(0.75))
                            }
                            
                            HStack(spacing: 20) {
                                HStack(spacing: 8) {
                                    Text("Sets:")
                                        .font(.caption)
                                        .fontWeight(.heavy)
                                        .foregroundColor(Color.white.opacity(0.70))
                                    Picker("Sets", selection: $exercise.sets) {
                                        Text("1").tag(1)
                                        Text("2").tag(2)
                                        Text("3").tag(3)
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 180)
                                }
                                
                                HStack(spacing: 8) {
                                    Text("Hold:")
                                        .font(.caption)
                                        .fontWeight(.heavy)
                                        .foregroundColor(Color.white.opacity(0.70))
                                    Picker("Duration", selection: Binding(
                                        get: { exercise.targetSeconds ?? 45 },
                                        set: { exercise.targetSeconds = $0 }
                                    )) {
                                        Text("20s").tag(20)
                                        Text("30s").tag(30)
                                        Text("45s").tag(45)
                                        Text("60s").tag(60)
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 260)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onMove { indices, newOffset in
                        appState.stretchingExercises.move(fromOffsets: indices, toOffset: newOffset)
                        for i in 0..<appState.stretchingExercises.count {
                            appState.stretchingExercises[i].order = i
                        }
                        appState.saveStretchingExercises()
                    }
                }
                
                Section {
                    Button("Reset Stretches to Defaults") {
                        appState.resetStretchingExercisesToDefault()
                    }
                    .foregroundColor(.red)
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Stretching Protocol")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        appState.saveStretchingExercises()
                        dismiss()
                    }
                }
            }
        }
    }
}

