import Foundation
import UIKit

enum CrashSeverity {
    case low
    case medium
    case high
    case critical
}

final class CrashReporter {
    static let shared = CrashReporter()
    private let logger = AppLogger.shared
    
    private init() {
        setupCrashHandling()
    }
    
    private func setupCrashHandling() {
        // Set up crash signal handlers
        NSSetUncaughtExceptionHandler { exception in
            CrashReporter.shared.handleException(exception)
        }
    }
    
    func handleException(_ exception: NSException) {
        let crashLog = generateCrashLog(from: exception)
        saveCrashLog(crashLog)
        logger.critical("App crashed: \(exception.name.rawValue)", category: .error)
    }
    
    func reportError(_ error: Error, severity: CrashSeverity, context: String) {
        let errorLog = generateErrorLog(from: error, severity: severity, context: context)
        saveErrorLog(errorLog)
        
        switch severity {
        case .low:
            logger.warning("Error occurred: \(error.localizedDescription)", category: .error)
        case .medium:
            logger.error("Error occurred: \(error.localizedDescription)", category: .error)
        case .high, .critical:
            logger.critical("Critical error occurred: \(error.localizedDescription)", category: .error)
        }
    }
    
    private func generateCrashLog(from exception: NSException) -> [String: Any] {
        let crashLog: [String: Any] = [
            "name": exception.name.rawValue,
            "reason": exception.reason ?? "Unknown reason",
            "userInfo": exception.userInfo ?? [:],
            "callStackSymbols": exception.callStackSymbols,
            "callStackReturnAddresses": exception.callStackReturnAddresses,
            "timestamp": Date(),
            "deviceInfo": deviceInfo()
        ]
        return crashLog
    }
    
    private func generateErrorLog(from error: Error, severity: CrashSeverity, context: String) -> [String: Any] {
        let errorLog: [String: Any] = [
            "error": error.localizedDescription,
            "severity": String(describing: severity),
            "context": context,
            "timestamp": Date(),
            "deviceInfo": deviceInfo()
        ]
        return errorLog
    }
    
    private func deviceInfo() -> [String: String] {
        var info: [String: String] = [:]
        info["systemName"] = UIDevice.current.systemName
        info["systemVersion"] = UIDevice.current.systemVersion
        info["model"] = UIDevice.current.model
        info["appVersion"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        info["buildNumber"] = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return info
    }
    
    private func saveCrashLog(_ log: [String: Any]) {
        // Here you would typically send to your crash reporting service
        // For now, we'll just log it
        #if DEBUG
        print("Crash Log: \(log)")
        #endif
    }
    
    private func saveErrorLog(_ log: [String: Any]) {
        // Here you would typically send to your error reporting service
        // For now, we'll just log it
        #if DEBUG
        print("Error Log: \(log)")
        #endif
    }
} 