import Foundation
import BackgroundTasks
import OSLog

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "dev.topscrech.Dickpic",
    category: "BackgroundTask"
)

extension PhotoLibraryVM {
    func registerBackgroundTask(analyzeConcurrently: Bool) {
        let id = UUID()
        let taskID = "dev.topscrech.Dickpic.process-assets.\(id)"
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskID, using: nil) { task in
            logger.info("Registered a background task")
            //self.handleAppRefresh(task: task as! BGProcessingTask)
#warning("Implement cancelling")
            var shouldContinue = true
            
            guard let task = task as? BGContinuedProcessingTask else {
                fatalError("Unexpected task type")
            }
            
            //            task.progress.totalUnitCount = 100
            
            task.expirationHandler = {
                logger.info("Expiration handler called")
                shouldContinue = false
            }
            
            let startTime = Date()
            self.isProcessing = true
            self.processingTime = nil
            
            // Cancel previous task
            self.processAssetsTask?.cancel()
            
            guard self.analyzer.checkPolicy() else {
                self.sheetEnablePolicy = true
                return
            }
            
            self.progress = 0
            self.assetCount = 0
            self.processedAssets = 0
            self.sensitiveAssets.removeAll()
            self.sensitiveVideos.removeAll()
            
            Task {
                let assets = await self.fetchAssets()
                
                task.progress.totalUnitCount = Int64(assets.count)
                
                self.processAssetsTask = Task {
                    await self.processAssets(
                        assets,
                        maxConcurrentTasks: self.maxConcurrentTasks(analyzeConcurrently),
                        task: task
                    )
                    
                    let elapsed = Date().timeIntervalSince(startTime)
                    self.processingTime = Int(elapsed)
                    
                    self.isProcessing = false
                    
                    logger.info("Task completed")
                    task.setTaskCompleted(success: true)
                }
            }
        }
        
        Task {
            await startBackgroundTask(id)
        }
    }
}

func startBackgroundTask(_ id: UUID) async {
    logger.info("Start")
    
    let req = BGContinuedProcessingTaskRequest(
        identifier: "dev.topscrech.Dickpic.process-assets.\(id)",
        title: "Title",
        subtitle: "Subtitle"
    )
    
    do {
        try BGTaskScheduler.shared.submit(req)
    } catch {
        logger.error("Error: \(error)")
    }
}
