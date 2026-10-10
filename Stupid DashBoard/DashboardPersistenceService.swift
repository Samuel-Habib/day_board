import Foundation

// MARK: - Dashboard Persistence Service (Tailscale Backend API)

public actor DashboardPersistenceService {
    public static let shared = DashboardPersistenceService()
    
    // Server URL defaults to user's Tailscale server at http://100.113.33.28:8080
    public static let defaultServerURL = "http://100.113.33.28:8080"
    
    private var baseURL: URL {
        let stored = UserDefaults.standard.string(forKey: "dashboardPersistenceServerUrl") ?? ""
        let cleaned = stored.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleaned.isEmpty, let url = URL(string: cleaned) {
            return url
        }
        return URL(string: DashboardPersistenceService.defaultServerURL)!
    }
    
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
    
    private var decoder: JSONDecoder {
        let dec = JSONDecoder()
        let isoFormatterWithMillis = ISO8601DateFormatter()
        isoFormatterWithMillis.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        let customDateFormatter = DateFormatter()
        customDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        customDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        dec.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            if let date = isoFormatterWithMillis.date(from: dateStr) {
                return date
            }
            if let date = isoFormatter.date(from: dateStr) {
                return date
            }
            customDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            if let date = customDateFormatter.date(from: dateStr) {
                return date
            }
            customDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = customDateFormatter.date(from: dateStr) {
                return date
            }
            customDateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = customDateFormatter.date(from: dateStr) {
                return date
            }
            if let timeInterval = Double(dateStr) {
                return Date(timeIntervalSince1970: timeInterval)
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateStr)")
        }
        return dec
    }
    
    private var encoder: JSONEncoder {
        let enc = JSONEncoder()
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        enc.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(isoFormatter.string(from: date))
        }
        return enc
    }
    
    // MARK: - Health / Connection Check
    public func testConnection() async throws -> Bool {
        let url = baseURL.appendingPathComponent("health")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 8.0
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { return false }
        
        if (200...299).contains(httpResponse.statusCode) {
            return true
        } else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw NSError(domain: "DashboardPersistenceService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }
    
    // MARK: - Fetch Today's Full Snapshot
    public func fetchSnapshot(date: String? = nil) async -> DashboardSnapshotResponse? {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/sync/snapshot"), resolvingAgainstBaseURL: false)
        if let d = date {
            components?.queryItems = [URLQueryItem(name: "date", value: d)]
        }
        guard let url = components?.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            return try decoder.decode(DashboardSnapshotResponse.self, from: data)
        } catch {
            print("DashboardPersistenceService: failed to fetch snapshot: \(error)")
            return nil
        }
    }
    
    // MARK: - Bulk State Synchronization
    public func syncState(payload: DashboardSyncPayload) async -> Bool {
        let url = baseURL.appendingPathComponent("api/sync/state")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 12.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            request.httpBody = try encoder.encode(payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return false
            }
            return true
        } catch {
            print("DashboardPersistenceService: syncState failed: \(error)")
            return false
        }
    }
    
    // MARK: - Morning Routine Remote State
    public func fetchMorningRoutine(date: String? = nil) async -> MorningRoutineResponse? {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/routines/morning"), resolvingAgainstBaseURL: false)
        if let d = date {
            components?.queryItems = [URLQueryItem(name: "date", value: d)]
        }
        guard let url = components?.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 8.0
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            return try decoder.decode(MorningRoutineResponse.self, from: data)
        } catch {
            print("DashboardPersistenceService: fetchMorningRoutine failed: \(error)")
            return nil
        }
    }
    
    public func updateMorningRoutine(update: MorningRoutineUpdate) async -> Bool {
        let url = baseURL.appendingPathComponent("api/routines/morning")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            request.httpBody = try encoder.encode(update)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return false
            }
            return true
        } catch {
            print("DashboardPersistenceService: updateMorningRoutine failed: \(error)")
            return false
        }
    }
    
    // MARK: - Task Event Logging
    public func logTaskEvent(event: TaskEventCreate) async -> Bool {
        let url = baseURL.appendingPathComponent("api/tasks/event")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            request.httpBody = try encoder.encode(event)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return false
            }
            return true
        } catch {
            print("DashboardPersistenceService: logTaskEvent failed: \(error)")
            return false
        }
    }
    
    // MARK: - Medication Logging
    public func logMedication(log: MedicationLogCreate) async -> Bool {
        let url = baseURL.appendingPathComponent("api/medications/log")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            request.httpBody = try encoder.encode(log)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return false
            }
            return true
        } catch {
            print("DashboardPersistenceService: logMedication failed: \(error)")
            return false
        }
    }
    
    // MARK: - Omeprazole Live Server Status
    public func fetchOmeprazoleStatus(date: String? = nil) async -> OmeprazoleServerStatus? {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/medications/omeprazole-status"), resolvingAgainstBaseURL: false)
        if let d = date {
            components?.queryItems = [URLQueryItem(name: "date", value: d)]
        }
        guard let url = components?.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 8.0
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            return try decoder.decode(OmeprazoleServerStatus.self, from: data)
        } catch {
            print("DashboardPersistenceService: fetchOmeprazoleStatus failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Eating Event Logging
    public func logEatingEvent(date: String? = nil, notes: String? = nil) async -> Bool {
        let url = baseURL.appendingPathComponent("api/medications/eating-event")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let payload = EatingEventCreate(
            date: date,
            food_consumed_at: isoFormatter.string(from: Date()),
            notes: notes
        )
        
        do {
            request.httpBody = try encoder.encode(payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return false
            }
            return true
        } catch {
            print("DashboardPersistenceService: logEatingEvent failed: \(error)")
            return false
        }
    }
    
    // MARK: - Work Session Logging
    public func logWorkSession(session: WorkSessionCreate) async -> Bool {
        let url = baseURL.appendingPathComponent("api/work/session")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            request.httpBody = try encoder.encode(session)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return false
            }
            return true
        } catch {
            print("DashboardPersistenceService: logWorkSession failed: \(error)")
            return false
        }
    }
}
