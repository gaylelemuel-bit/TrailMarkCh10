import Foundation

struct AppError: Identifiable {
    enum ID: Hashable {
        case healthUnavailable
        case healthAuthorization
        case healthRefresh
        case mediaImport
        case connectivity
    }

    enum Severity {
        case information
        case warning
        case critical
    }

    let id: ID
    let title: LocalizedStringResource
    let message: String
    let recoverySuggestion: LocalizedStringResource?
    let symbolName: String
    let severity: Severity

    static let healthUnavailable = AppError(
        id: .healthUnavailable,
        title: "Health Data Unavailable",
        message: "This device can’t provide Health data.",
        recoverySuggestion: nil,
        symbolName: "heart.slash.fill",
        severity: .warning
    )

    static let healthAuthorization = AppError(
        id: .healthAuthorization,
        title: "Health Access Needed",
        message: "Allow TrailMark to read activity data in the Health app.",
        recoverySuggestion: "Try Again",
        symbolName: "lock.fill",
        severity: .warning
    )

    static func healthRefresh(_ message: String) -> AppError {
        AppError(
            id: .healthRefresh,
            title: "Couldn’t Refresh Health Data",
            message: message,
            recoverySuggestion: "Try Again",
            symbolName: "arrow.clockwise.circle.fill",
            severity: .warning
        )
    }

    static func mediaImport(_ message: String) -> AppError {
        AppError(
            id: .mediaImport,
            title: "Couldn’t Save Media",
            message: message,
            recoverySuggestion: nil,
            symbolName: "exclamationmark.triangle.fill",
            severity: .critical
        )
    }

    static func connectivity(_ message: String) -> AppError {
        AppError(
            id: .connectivity,
            title: "Sync Problem",
            message: message,
            recoverySuggestion: "Try Again",
            symbolName: "applewatch.slash",
            severity: .information
        )
    }
}
