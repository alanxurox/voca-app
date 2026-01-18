import Foundation

enum ModelStatus: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case error(String)

    static func == (lhs: ModelStatus, rhs: ModelStatus) -> Bool {
        switch (lhs, rhs) {
        case (.notDownloaded, .notDownloaded): return true
        case (.downloaded, .downloaded): return true
        case (.downloading(let p1), .downloading(let p2)): return p1 == p2
        case (.error(let e1), .error(let e2)): return e1 == e2
        default: return false
        }
    }
}

class ModelManager: NSObject {
    static let shared = ModelManager()

    // Model status for each supported model
    private(set) var modelStatus: [ASRModel: ModelStatus] = [:]

    // Callbacks for status updates
    var onStatusChanged: ((ASRModel, ModelStatus) -> Void)?

    // Active downloads
    private var activeDownloads: [ASRModel: URLSessionDownloadTask] = [:]
    private var downloadSessions: [ASRModel: URLSession] = [:]

    // Model download URLs
    private let modelURLs: [ASRModel: String] = [
        .senseVoice: "https://github.com/zhengyishen0/voca-app/releases/download/models-v1/sensevoice.zip",
        .whisperTurbo: "https://github.com/zhengyishen0/voca-app/releases/download/models-v1/whisper-turbo.zip",
        .parakeet: "https://github.com/zhengyishen0/voca-app/releases/download/models-v1/parakeet-v2.zip"
    ]

    // Model folder names after extraction (must match what ASREngine expects)
    private let modelFolderNames: [ASRModel: String] = [
        .senseVoice: "sensevoice-500-itn.mlmodelc",
        .whisperTurbo: "whisper-turbo",  // WhisperKit format (folder, not .mlmodelc)
        .parakeet: "parakeet-v2"  // FluidAudio format (folder with multiple models)
    ]

    var modelDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Voca/models")
    }

    override init() {
        super.init()
        checkAllModelStatus()
    }

    // MARK: - Status Checking

    func checkAllModelStatus() {
        for model in ASRModel.availableModels {
            checkModelStatus(model)
        }
    }

    func checkModelStatus(_ model: ASRModel) {
        guard let folderName = modelFolderNames[model] else {
            updateStatus(model, .error("Unknown model"))
            return
        }

        let modelPath = modelDirectory.appendingPathComponent(folderName)
        if FileManager.default.fileExists(atPath: modelPath.path) {
            updateStatus(model, .downloaded)
        } else {
            updateStatus(model, .notDownloaded)
        }
    }

    func isModelDownloaded(_ model: ASRModel) -> Bool {
        return modelStatus[model] == .downloaded
    }

    func isAnyModelDownloaded() -> Bool {
        return modelStatus.values.contains(.downloaded)
    }

    // MARK: - Download

    func downloadModel(_ model: ASRModel) {
        guard let urlString = modelURLs[model],
              let url = URL(string: urlString) else {
            updateStatus(model, .error("Invalid URL"))
            return
        }

        // Don't re-download if already downloading or downloaded
        if case .downloading = modelStatus[model] { return }
        if modelStatus[model] == .downloaded { return }

        updateStatus(model, .downloading(progress: 0))

        // Create a dedicated session for this download with delegate
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        downloadSessions[model] = session

        let task = session.downloadTask(with: url)
        activeDownloads[model] = task
        task.resume()
    }

    func cancelDownload(_ model: ASRModel) {
        activeDownloads[model]?.cancel()
        activeDownloads.removeValue(forKey: model)
        downloadSessions[model]?.invalidateAndCancel()
        downloadSessions.removeValue(forKey: model)
        updateStatus(model, .notDownloaded)
    }

    // MARK: - Private Helpers

    private func updateStatus(_ model: ASRModel, _ status: ModelStatus) {
        modelStatus[model] = status
        onStatusChanged?(model, status)
    }

    private func findModel(for task: URLSessionTask) -> ASRModel? {
        for (model, downloadTask) in activeDownloads {
            if downloadTask == task {
                return model
            }
        }
        return nil
    }

    private func unzipModel(at zipURL: URL, for model: ASRModel) -> Bool {
        guard let folderName = modelFolderNames[model] else { return false }

        // Ensure model directory exists
        try? FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)

        // Create temp extraction directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Unzip using ditto (built-in macOS command)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-xk", zipURL.path, tempDir.path]

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                print("Unzip failed with status \(process.terminationStatus)")
                return false
            }

            // Find the .mlmodelc folder in extracted contents
            let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            var modelcPath: URL?

            for item in contents {
                if item.lastPathComponent == folderName {
                    modelcPath = item
                    break
                }
                // Check one level deeper (in case zip has a wrapper folder)
                if item.hasDirectoryPath {
                    let subContents = try? FileManager.default.contentsOfDirectory(at: item, includingPropertiesForKeys: nil)
                    for subItem in subContents ?? [] {
                        if subItem.lastPathComponent == folderName {
                            modelcPath = subItem
                            break
                        }
                    }
                }
            }

            guard let sourcePath = modelcPath else {
                print("Could not find \(folderName) in extracted contents")
                return false
            }

            // Move to final location
            let destPath = modelDirectory.appendingPathComponent(folderName)

            // Remove existing if present
            try? FileManager.default.removeItem(at: destPath)

            try FileManager.default.moveItem(at: sourcePath, to: destPath)

            // Cleanup
            try? FileManager.default.removeItem(at: tempDir)
            try? FileManager.default.removeItem(at: zipURL)

            return true
        } catch {
            print("Unzip error: \(error)")
            try? FileManager.default.removeItem(at: tempDir)
            return false
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension ModelManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let model = findModel(for: downloadTask) else { return }

        // Move to a permanent temp location (the provided location is deleted after this method)
        let tempZip = FileManager.default.temporaryDirectory.appendingPathComponent("\(model.rawValue).zip")
        try? FileManager.default.removeItem(at: tempZip)

        do {
            try FileManager.default.moveItem(at: location, to: tempZip)

            if unzipModel(at: tempZip, for: model) {
                updateStatus(model, .downloaded)
                print("✓ Downloaded \(model.displayName)")
            } else {
                updateStatus(model, .error("Failed to extract model"))
            }
        } catch {
            updateStatus(model, .error("Failed to save download: \(error.localizedDescription)"))
        }

        activeDownloads.removeValue(forKey: model)
        downloadSessions[model]?.finishTasksAndInvalidate()
        downloadSessions.removeValue(forKey: model)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let model = findModel(for: downloadTask) else { return }

        let progress = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            : 0

        updateStatus(model, .downloading(progress: progress))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let model = findModel(for: task), let error = error else { return }

        // Don't report cancellation as error
        if (error as NSError).code == NSURLErrorCancelled {
            updateStatus(model, .notDownloaded)
        } else {
            updateStatus(model, .error(error.localizedDescription))
        }

        activeDownloads.removeValue(forKey: model)
        downloadSessions[model]?.finishTasksAndInvalidate()
        downloadSessions.removeValue(forKey: model)
    }
}
