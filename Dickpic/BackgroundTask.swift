import Foundation
import BackgroundTasks
import OSLog

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "dev.topscrech.Dickpic",
    category: "BackgroundTask"
)

private enum BackgroundTaskIdentifier {
    static let continuedProcessingPrefix = "dev.topscrech.Dickpic.process-assets."
}

extension PhotoLibraryVM {
    func registerBackgroundTask(analyzeConcurrently: Bool) {
        guard #available(iOS 26.0, *) else {
            logger.info("Skipping background task registration below iOS 26")
            return
        }

        let id = UUID()
        registerContinuedBackgroundTask(
            id: id,
            analyzeConcurrently: analyzeConcurrently
        )
        submitContinuedBackgroundTask(id: id)
    }
}

private extension PhotoLibraryVM {
    func prepareBackgroundAnalysis() -> Date? {
        let startTime = Date()
        isProcessing = true
        processingTime = nil

        processAssetsTask?.cancel()

        guard analyzer.checkPolicy() else {
            sheetEnablePolicy = true
            isProcessing = false
            return nil
        }

        progress = 0
        assetCount = 0
        processedAssets = 0
        sensitiveAssets.removeAll()
        sensitiveVideos.removeAll()

        return startTime
    }

    func completeBackgroundAnalysis(startTime: Date) -> Bool {
        let elapsed = Date().timeIntervalSince(startTime)
        processingTime = Int(elapsed)
        isProcessing = false
        return !Task.isCancelled
    }

    func cancelBackgroundAnalysis() {
        logger.info("Background task expired")
        processAssetsTask?.cancel()
        isProcessing = false
    }

    @available(iOS 26.0, *)
    func registerContinuedBackgroundTask(
        id: UUID,
        analyzeConcurrently: Bool
    ) {
        let taskID = BackgroundTaskIdentifier.continuedProcessingPrefix + id.uuidString
        let didRegister = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskID,
            using: nil
        ) { task in
            guard let task = task as? BGContinuedProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }

            task.expirationHandler = { [weak self] in
                Task { @MainActor in
                    self?.cancelBackgroundAnalysis()
                }
            }

            Task { @MainActor in
                guard let startTime = self.prepareBackgroundAnalysis() else {
                    task.setTaskCompleted(success: false)
                    return
                }

                let assets = await self.fetchAssets()
                task.progress.totalUnitCount = Int64(assets.count)

                self.processAssetsTask = Task { @MainActor in
                    await self.processAssets(
                        assets,
                        maxConcurrentTasks: self.maxConcurrentTasks(analyzeConcurrently),
                        onAssetProcessed: {
                            task.progress.completedUnitCount += 1
                        }
                    )

                    let success = self.completeBackgroundAnalysis(startTime: startTime)
                    logger.info("Continued background task completed: \(success)")
                    task.setTaskCompleted(success: success)
                }
            }
        }

        if !didRegister {
            logger.error("Failed to register continued background task")
        }
    }

    @available(iOS 26.0, *)
    func submitContinuedBackgroundTask(id: UUID) {
        let request = BGContinuedProcessingTaskRequest(
            identifier: BackgroundTaskIdentifier.continuedProcessingPrefix + id.uuidString,
            title: "Analyze Photo Library",
            subtitle: "Scanning photos and videos"
        )

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            logger.error("Failed to submit continued background task: \(error)")
        }
    }
}
