import Foundation

public actor TimekeepingService {
    public static let shared = TimekeepingService()
    
    private let baseURL = URL(string: "https://timekeeping.samuelhabib.com")!
    
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private let fallbackIsoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    // MARK: - Test API Connection
    public func testConnection(apiKey: String) async throws -> Bool {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("api/entries"))
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { return false }
        
        if httpResponse.statusCode == 200 {
            return true
        } else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw NSError(domain: "TimekeepingService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }
    
    // MARK: - Start Live Timer
    public func startLiveTimer(
        title: String,
        project: String = "Habits",
        category: String,
        notes: String? = "Started from Apple TV Dashboard",
        tags: String? = "routine,appletv",
        apiKey: String
    ) async -> Int? {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("api/timer/start"))
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        var payload: [String: Any] = [
            "title": title,
            "project": project,
            "category": category
        ]
        if let notes = notes { payload["notes"] = notes }
        if let tags = tags { payload["tags"] = tags }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...201).contains(httpResponse.statusCode) else {
                return nil
            }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let entryId = json["id"] as? Int {
                return entryId
            }
        } catch {
            print("TimekeepingService: failed to start live timer: \(error)")
        }
        return nil
    }
    
    // MARK: - Stop Live Timer
    public func stopLiveTimer(entryId: Int, notes: String?, tags: String? = "routine,appletv,completed", apiKey: String) async -> Bool {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("api/timer/\(entryId)/stop"))
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        var payload: [String: Any] = [:]
        if let notes = notes { payload["notes"] = notes }
        if let tags = tags { payload["tags"] = tags }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                return true
            }
        } catch {
            print("TimekeepingService: failed to stop live timer: \(error)")
        }
        return false
    }
    
    // MARK: - Fetch Overall Stats
    public func fetchStats(apiKey: String) async -> TimeStatsResponse? {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("api/stats"))
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            return try JSONDecoder().decode(TimeStatsResponse.self, from: data)
        } catch {
            print("TimekeepingService: failed to fetch stats: \(error)")
            return nil
        }
    }
    
    // MARK: - Fetch Remote Entries
    public func fetchRecentEntries(apiKey: String, limit: Int = 100) async -> [TimeEntryResponse]? {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        
        var components = URLComponents(url: baseURL.appendingPathComponent("api/entries"), resolvingAgainstBaseURL: true)
        components?.queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]
        
        guard let url = components?.url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            return try JSONDecoder().decode([TimeEntryResponse].self, from: data)
        } catch {
            print("TimekeepingService: failed to fetch recent entries: \(error)")
            return nil
        }
    }
    
    // MARK: - Delete Entry
    public func deleteEntry(entryId: Int, apiKey: String) async -> Bool {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("api/entries/\(entryId)"))
        request.httpMethod = "DELETE"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                return true
            }
        } catch {
            print("TimekeepingService: failed to delete entry \(entryId): \(error)")
        }
        return false
    }
    
    // MARK: - Create Completed Time Entry Directly
    public func logCompletedSession(_ session: RoutineSession, apiKey: String) async -> Int? {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("api/entries"))
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let routineTitle = "\(session.period.rawValue) Routine"
        let durationMins = round((session.totalDurationSeconds / 60.0) * 10) / 10.0
        
        let breakdownText = session.taskRecords
            .sorted(by: { $0.durationSeconds > $1.durationSeconds })
            .map { "\($0.title): \(Int(round($0.durationSeconds)))s" }
            .joined(separator: ", ")
        
        let notes = breakdownText.isEmpty ? "Completed on Apple TV" : "Task breakdown: \(breakdownText)"
        let startTimeString = fallbackIsoFormatter.string(from: session.startTime)
        let endTimeString = fallbackIsoFormatter.string(from: session.endTime ?? Date())
        
        let payload: [String: Any] = [
            "title": routineTitle,
            "project": "Habits",
            "category": "\(session.period.rawValue) Routine",
            "start_time": startTimeString,
            "end_time": endTimeString,
            "duration_minutes": durationMins,
            "status": "completed",
            "notes": notes,
            "tags": "routine,dashboard,\(session.period.rawValue.lowercased())"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...201).contains(httpResponse.statusCode) else {
                print("TimekeepingService: direct entry creation failed with status \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return nil
            }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let entryId = json["id"] as? Int {
                return entryId
            }
        } catch {
            print("TimekeepingService: failed to log completed session: \(error)")
        }
        return nil
    }
}
