import Foundation
import OSLog

enum LogLevel: String {
    case debug = "🔍 DEBUG"
    case info = "ℹ️ INFO"
    case warning = "⚠️ WARNING"
    case error = "❌ ERROR"
    case critical = "🔥 CRITICAL"
    
    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        case .critical:
            return .fault
        }
    }
}

@MainActor
class Logger {
    static let shared = Logger()
    
    private let osLogger: OSLog
    private let dateFormatter: DateFormatter
    
    private init() {
        // Initialize OSLog with your app's bundle identifier
        self.osLogger = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.subtrack", category: "App")
        
        // Configure date formatter
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }
    
    private func log(_ level: LogLevel, message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(timestamp)] \(level.rawValue) [\(fileName):\(line)] \(function): \(message)"
        
        // Log to OSLog
        os_log("%{public}@", log: osLogger, type: level.osLogType, logMessage)
        
        #if DEBUG
        // In debug builds, also print to console
        print(logMessage)
        #endif
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message: message, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message: message, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message: message, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message: message, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.critical, message: message, file: file, function: function, line: line)
    }
    
    // Convenience method for logging errors
    func error(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message: error.localizedDescription, file: file, function: function, line: line)
    }
} 