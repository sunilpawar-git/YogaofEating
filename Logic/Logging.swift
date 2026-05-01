import OSLog

/// Centralised Logger definitions — single source of truth for all subsystem loggers.
/// Import this file to use typed loggers instead of bare print() calls (DRY + security).
///
/// Usage:
///   AppLoggers.insight.info("Insight generated")                   // non-sensitive
///   AppLoggers.healthKit.debug("\(data, privacy: .private)")        // sensitive
enum AppLoggers {
    static let insight = Logger(subsystem: "com.yogaofeating", category: "Insight")
    static let healthKit = Logger(subsystem: "com.yogaofeating", category: "HealthKit")
    static let app = Logger(subsystem: "com.yogaofeating", category: "App")
    static let auth = Logger(subsystem: "com.yogaofeating", category: "Auth")
}
