import Foundation

/// Unified error type for the Yoga of Eating app.
/// All service layers must throw `AppError` cases instead of ad-hoc `NSError` constructions.
/// User-facing `errorDescription` values never expose internal details (Firebase, tokens, UIDs).
/// Detailed context lives in `failureReason` for server-side logging only.
enum AppError: LocalizedError {
    // MARK: - Auth domain

    /// The operation requires an authenticated user but none is present.
    case authRequired

    /// The external auth provider (e.g. Google Sign-In) failed.
    case authProviderFailed(underlying: Error)

    /// Restoring a previous sign-in session failed.
    case sessionRestoreFailed

    // MARK: - Sync domain

    /// Serializing a snapshot to JSON for upload failed.
    case syncSerializationFailed

    /// An upload to the cloud sync backend failed.
    case syncUploadFailed(underlying: Error)

    /// Sync was attempted without an authenticated user.
    case syncAuthRequired

    // MARK: - Analysis domain

    /// The AI analysis service is not available (e.g. not an AIAnalysisProvider).
    case analysisUnavailable

    /// The AI analysis request timed out.
    case analysisTimeout

    // MARK: - HealthKit domain

    /// HealthKit is not available on this device or access was denied.
    case healthKitUnavailable

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .authRequired, .syncAuthRequired:
            "Please sign in to continue."
        case .authProviderFailed:
            "Sign-in failed. Please try again."
        case .sessionRestoreFailed:
            "We couldn't restore your session. Please sign in again."
        case .syncSerializationFailed:
            "We couldn't sync your data. Please try again later."
        case .syncUploadFailed:
            "Sync failed. Please check your connection and try again."
        case .analysisUnavailable:
            "Meal analysis is temporarily unavailable."
        case .analysisTimeout:
            "Meal analysis took too long. Please try again."
        case .healthKitUnavailable:
            "Health data is unavailable on this device."
        }
    }

    var failureReason: String? {
        switch self {
        case .authRequired:
            "authRequired: no authenticated user found"
        case let .authProviderFailed(underlying):
            "authProviderFailed: \(underlying)"
        case .sessionRestoreFailed:
            "sessionRestoreFailed: could not restore previous sign-in"
        case .syncSerializationFailed:
            "syncSerializationFailed: JSON encoding or dictionary cast failed"
        case let .syncUploadFailed(underlying):
            "syncUploadFailed: \(underlying)"
        case .syncAuthRequired:
            "syncAuthRequired: userId was nil at sync time"
        case .analysisUnavailable:
            "analysisUnavailable: logicService does not conform to AIAnalysisProvider"
        case .analysisTimeout:
            "analysisTimeout: AI request exceeded time limit"
        case .healthKitUnavailable:
            "healthKitUnavailable: HealthKit not supported or access denied"
        }
    }
}
