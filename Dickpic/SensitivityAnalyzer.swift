import SensitiveContentAnalysis

final class SensitivityAnalyzer {
    private let analyzer = SCSensitivityAnalyzer()
    private var serviceUnavailable = false
    private var didLogServiceUnavailable = false
    
    func checkImage(_ url: URL) async throws -> Bool {
        guard !serviceUnavailable else {
            return false
        }

        do {
            return try await analyzer.analyzeImage(at: url).isSensitive
        } catch {
            if shouldDisableService(for: error) {
                disableService()
                return false
            }

            throw error
        }
    }
    
    func checkImage(_ image: CGImage) async throws -> Bool {
        guard !serviceUnavailable else {
            return false
        }

        do {
            return try await analyzer.analyzeImage(image).isSensitive
        } catch {
            if shouldDisableService(for: error) {
                disableService()
                return false
            }

            throw error
        }
    }
    
    func checkVideo(_ url: URL) async throws -> Bool {
        guard !serviceUnavailable else {
            return false
        }

        do {
            let handler = analyzer.videoAnalysis(forFileAt: url)
            let result = try await handler.hasSensitiveContent()
            return result.isSensitive
        } catch {
            if shouldDisableService(for: error) {
                disableService()
                return false
            }

            throw error
        }
    }
    
    func checkPolicy() -> Bool {
        if serviceUnavailable {
            return false
        }

        let policy = analyzer.analysisPolicy
        
        if policy == .disabled {
            print("Analysis is disabled")
            return false
        } else {
            return true
        }
    }

    private func shouldDisableService(for error: Error) -> Bool {
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

    private func disableService() {
        serviceUnavailable = true

        guard !didLogServiceUnavailable else {
            return
        }

        didLogServiceUnavailable = true
        print("SensitiveContentAnalysis service unavailable in current sandbox, falling back to non-sensitive result")
    }
}
