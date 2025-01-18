import Foundation
import OSLog

enum LogCategory: String {
    case video = "Video"
    case network = "Network"
    case userInterface = "UI"
    case portfolio = "Portfolio"
    case error = "Error"
}

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
}

final class AppLogger {
    static let shared = AppLogger()
    private let logger: Logger
    
    private init() {
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.clccollective", category: "CLCcollective")
    }
    
    func log(_ message: String, category: LogCategory, level: LogLevel, file: String = #file, function: String = #function, line: Int = #line) {
        let sourceInfo = "\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)"
        let formattedMessage = "[\(category.rawValue)][\(level.rawValue)] \(message) | \(sourceInfo)"
        
        switch level {
        case .debug:
            logger.debug("\(formattedMessage)")
        case .info:
            logger.info("\(formattedMessage)")
        case .warning:
            logger.warning("\(formattedMessage)")
        case .error:
            logger.error("\(formattedMessage)")
        case .critical:
            logger.critical("\(formattedMessage)")
        }
        
        #if DEBUG
        print(formattedMessage)
        #endif
    }
    
    // Convenience methods
    func debug(_ message: String, category: LogCategory, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .debug, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: LogCategory, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .info, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: LogCategory, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .warning, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: LogCategory, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .error, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, category: LogCategory, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .critical, file: file, function: function, line: line)
    }
} 