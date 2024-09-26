//import SensitiveContentAnalysis
//
//final class SensitivityAnalyzer {
//    static private let analyzer = SCSensitivityAnalyzer()
//    
//    static func checkImage(_ url: URL, completion: @escaping (Bool) -> Void) async {
//        do {
//            let handler = try await analyzer.analyzeImage(at: url)
//            completion(handler.isSensitive)
//        } catch {
//            print(error.localizedDescription)
//        }
//    }
//    
//    static func checkImage(_ image: CGImage, completion: @escaping (Bool) -> Void) async {
//        do {
//            let handler = try await analyzer.analyzeImage(image)
//            completion(handler.isSensitive)
//        } catch {
//            print(error.localizedDescription)
//        }
//    }
//    
//    static func checkVideo(_ url: URL, completion: @escaping (Bool) -> Void) async {
//        do {
//            let handler = analyzer.videoAnalysis(forFileAt: url)
//            completion(try await handler.hasSensitiveContent().isSensitive)
//        } catch {
//            print(error.localizedDescription)
//        }
//    }
//    
//    static func checkPolicy() -> Bool {
//        let policy = analyzer.analysisPolicy
//        
//        if policy == .disabled {
//            print("Analysis is disabled")
//            return false
//        } else {
//            return true
//        }
//    }
//}
