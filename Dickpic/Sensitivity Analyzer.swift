import SensitiveContentAnalysis

final class SensitivityAnalyzer {
    private let analyzer = SCSensitivityAnalyzer()
    
    func checkImage(_ url: URL) async throws -> Bool {
        let handler = try await analyzer.analyzeImage(at: url)
        
        return handler.isSensitive
    }
    
    func checkImage(_ image: CGImage) async throws -> Bool {
        let handler = try await analyzer.analyzeImage(image)
        
        return handler.isSensitive
    }
    
    func checkVideo(_ url: URL) async throws -> Bool {
        let handler = analyzer.videoAnalysis(forFileAt: url)
        let result = try await handler.hasSensitiveContent()
        
        return result.isSensitive
    }
    
    func checkPolicy() -> Bool {
        let policy = analyzer.analysisPolicy
        
        if policy == .disabled {
            print("Analysis is disabled")
            return false
        } else {
            return true
        }
    }
}
