import Foundation
import Combine

public enum NetworkStatus {
    case checking
    case online
    case offline
}

public struct NetworkDiagnosis: Equatable {
    public let target: String
    public let reachable: Bool
    public let responseTimeMs: Int
    public let statusCode: Int?
    public let errorMessage: String?
    public let timestamp: String
}

@MainActor
public final class NetworkGuardStore: ObservableObject {
    public static let shared = NetworkGuardStore()
    
    @Published public var status: NetworkStatus = .checking
    @Published public var isBypassed: Bool = false
    @Published public var diagnosis: NetworkDiagnosis? = nil
    @Published public var showDiagnosisDetails: Bool = false
    
    public let targetNode = "172.16.50.4"
    public let targetURLString = "http://172.16.50.4"
    
    public init() {
        checkConnectivity()
    }
    
    public func checkConnectivity() {
        self.status = .checking
        self.isBypassed = false
        
        let startTime = Date()
        guard let url = URL(string: targetURLString) else {
            self.status = .offline
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 2.5
        request.httpMethod = "HEAD" // Fast probe
        
        Task {
            do {
                let configuration = URLSessionConfiguration.ephemeral
                configuration.timeoutIntervalForRequest = 2.5
                configuration.timeoutIntervalForResource = 3.0
                let session = URLSession(configuration: configuration)
                
                let (_, response) = try await session.data(for: request)
                let elapsedMs = Int(Date().timeIntervalSince(startTime) * 1000)
                
                // Enforce minimum check delay of 1.2s for pleasant animation
                if elapsedMs < 1200 {
                    try? await Task.sleep(nanoseconds: UInt64((1200 - elapsedMs) * 1_000_000))
                }
                
                let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? 200
                self.diagnosis = NetworkDiagnosis(
                    target: self.targetNode,
                    reachable: true,
                    responseTimeMs: elapsedMs,
                    statusCode: httpStatus,
                    errorMessage: nil,
                    timestamp: DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
                )
                self.status = .online
            } catch {
                let elapsedMs = Int(Date().timeIntervalSince(startTime) * 1000)
                if elapsedMs < 1200 {
                    try? await Task.sleep(nanoseconds: UInt64((1200 - elapsedMs) * 1_000_000))
                }
                
                self.diagnosis = NetworkDiagnosis(
                    target: self.targetNode,
                    reachable: false,
                    responseTimeMs: elapsedMs,
                    statusCode: nil,
                    errorMessage: error.localizedDescription,
                    timestamp: DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
                )
                self.status = .offline
            }
        }
    }
    
    public func bypassToPreview() {
        self.isBypassed = true
    }
}
