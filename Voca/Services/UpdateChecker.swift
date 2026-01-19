import Foundation
import Sparkle

class UpdateChecker: NSObject, SPUUpdaterDelegate {
    static let shared = UpdateChecker()

    private(set) var isUpdateAvailable = false {
        didSet {
            if oldValue != isUpdateAvailable {
                NotificationCenter.default.post(name: .updateAvailabilityChanged, object: isUpdateAvailable)
            }
        }
    }

    private(set) var availableVersion: String?
    private weak var updater: SPUUpdater?

    private override init() {
        super.init()
    }

    func configure(with updater: SPUUpdater) {
        self.updater = updater
    }

    // MARK: - SPUUpdaterDelegate

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        DispatchQueue.main.async {
            self.isUpdateAvailable = true
            self.availableVersion = item.displayVersionString
        }
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: Error) {
        DispatchQueue.main.async {
            self.isUpdateAvailable = false
            self.availableVersion = nil
        }
    }

    func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: (any Error)?) {
        // Update cycle complete
    }

    // MARK: - Actions

    func checkForUpdates() {
        updater?.checkForUpdates()
    }
}

extension Notification.Name {
    static let updateAvailabilityChanged = Notification.Name("updateAvailabilityChanged")
}
