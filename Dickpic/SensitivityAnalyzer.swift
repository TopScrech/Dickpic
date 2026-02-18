import SensitiveContentAnalysis
import OSLog

final class SensitivityAnalyzer {
    private let analyzer = SCSensitivityAnalyzer()
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "dev.topscrech.Dickpic",
        category: "SensitivityAnalyzer"
    )
    
    func checkImage(_ url: URL) async throws -> Bool {
        do {
            return try await analyzer.analyzeImage(at: url).isSensitive
        } catch {
            if isServiceError(error) {
                logger.info("SensitiveContentAnalysis unavailable for this image, skipping")
                return false
            }
            
            throw error
        }
    }
    
    func checkImage(_ image: CGImage) async throws -> Bool {
        do {
            return try await analyzer.analyzeImage(image).isSensitive
        } catch {
            if isServiceError(error) {
                logger.info("SensitiveContentAnalysis unavailable for this image, skipping")
                return false
            }
            
            throw error
        }
    }
    
    func checkVideo(_ url: URL) async throws -> Bool {
        do {
            let handler = analyzer.videoAnalysis(forFileAt: url)
            let result = try await handler.hasSensitiveContent()
            return result.isSensitive
        } catch {
            if isServiceError(error) {
                logger.info("SensitiveContentAnalysis unavailable for this video, skipping")
                return false
            }
            
            throw error
        }
    }
    
    func checkPolicy() -> Bool {
        let policy = analyzer.analysisPolicy
        
        if policy == .disabled {
            logger.info("Analysis is disabled")
            return false
        } else {
            return true
        }
    }
    
    private func isServiceError(_ error: Error) -> Bool {
        let nsError = error as NSError
        let description = nsError.localizedDescription.lowercased()
        
        if nsError.domain == NSCocoaErrorDomain && nsError.code == 4099 {
            return true
        }
        
        if description.contains("screentimeagent") || description.contains("sandbox restriction") {
            return true
        }
        
        return false
    }
}
