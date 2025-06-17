import Foundation

// Global logging functions for easier access
func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Task { @MainActor in
        Logger.shared.debug(message, file: file, function: function, line: line)
    }
}

func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Task { @MainActor in
        Logger.shared.info(message, file: file, function: function, line: line)
    }
}

func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Task { @MainActor in
        Logger.shared.warning(message, file: file, function: function, line: line)
    }
}

func logError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Task { @MainActor in
        Logger.shared.error(message, file: file, function: function, line: line)
    }
}

func logError(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
    Task { @MainActor in
        Logger.shared.error(error, file: file, function: function, line: line)
    }
}

func logCritical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Task { @MainActor in
        Logger.shared.critical(message, file: file, function: function, line: line)
    }
} 
