import XCTest
@testable import Yoga_of_Eating

final class AppErrorTests: XCTestCase {
    // MARK: - errorDescription non-empty

    func test_authRequired_hasNonEmptyErrorDescription() {
        let error = AppError.authRequired
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    func test_authProviderFailed_hasNonEmptyErrorDescription() {
        let underlying = NSError(domain: "test", code: 1)
        let error = AppError.authProviderFailed(underlying: underlying)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    func test_sessionRestoreFailed_hasNonEmptyErrorDescription() {
        let error = AppError.sessionRestoreFailed
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    func test_syncSerializationFailed_hasNonEmptyErrorDescription() {
        let error = AppError.syncSerializationFailed
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    func test_syncUploadFailed_hasNonEmptyErrorDescription() {
        let underlying = NSError(domain: "test", code: 2)
        let error = AppError.syncUploadFailed(underlying: underlying)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    func test_syncAuthRequired_hasNonEmptyErrorDescription() {
        let error = AppError.syncAuthRequired
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    func test_analysisUnavailable_hasNonEmptyErrorDescription() {
        let error = AppError.analysisUnavailable
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    func test_analysisTimeout_hasNonEmptyErrorDescription() {
        let error = AppError.analysisTimeout
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    func test_healthKitUnavailable_hasNonEmptyErrorDescription() {
        let error = AppError.healthKitUnavailable
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    // MARK: - Auth cases expose no sensitive internals

    func test_authRequired_errorDescriptionContainsNoInternalDetails() {
        let error = AppError.authRequired
        let description = error.errorDescription ?? ""
        XCTAssertFalse(description.contains("Firebase"))
        XCTAssertFalse(description.contains("token"))
        XCTAssertFalse(description.contains("uid"))
    }

    func test_sessionRestoreFailed_errorDescriptionContainsNoInternalDetails() {
        let error = AppError.sessionRestoreFailed
        let description = error.errorDescription ?? ""
        XCTAssertFalse(description.contains("Firebase"))
        XCTAssertFalse(description.contains("idToken"))
    }

    // MARK: - Distinct cases are not equal

    func test_authRequired_isDistinctFromSyncSerializationFailed() {
        let auth = AppError.authRequired
        let sync = AppError.syncSerializationFailed
        // Verify they produce different descriptions (distinct error conditions)
        XCTAssertNotEqual(auth.errorDescription, sync.errorDescription)
    }

    func test_authRequired_isDistinctFromAnalysisUnavailable() {
        let auth = AppError.authRequired
        let analysis = AppError.analysisUnavailable
        XCTAssertNotEqual(auth.errorDescription, analysis.errorDescription)
    }

    // MARK: - LocalizedError conformance

    func test_appError_conformsToLocalizedError() {
        let error: LocalizedError = AppError.authRequired
        XCTAssertNotNil(error.errorDescription)
    }

    func test_allCases_haveNonNilFailureReason() {
        let underlying = NSError(domain: "t", code: 0)
        let cases: [AppError] = [
            .authRequired,
            .authProviderFailed(underlying: underlying),
            .sessionRestoreFailed,
            .syncSerializationFailed,
            .syncUploadFailed(underlying: underlying),
            .syncAuthRequired,
            .analysisUnavailable,
            .analysisTimeout,
            .healthKitUnavailable
        ]
        for error in cases {
            XCTAssertNotNil(error.failureReason, "failureReason should not be nil for \(error)")
        }
    }
}
