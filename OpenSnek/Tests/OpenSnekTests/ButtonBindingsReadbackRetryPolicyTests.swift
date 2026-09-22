import XCTest

@testable import OpenSnek

/// Covers the bounded retry bookkeeping that keeps a transient readback failure from parking a
/// hydration key forever, while still refusing to poll a silent device without bound.
final class ButtonBindingsReadbackRetryPolicyTests: XCTestCase {
    func testReleasesAttemptMarkerWhileBudgetRemains() {
        var policy = ButtonBindingsReadbackRetryPolicy()

        XCTAssertTrue(policy.recordFailure(key: "device#1#normal"), "a first failure must allow a retry")
        XCTAssertTrue(policy.recordFailure(key: "device#1#normal"), "a second failure must allow a retry")
        XCTAssertFalse(policy.recordFailure(key: "device#1#normal"), "the retry budget must eventually be exhausted")
        XCTAssertEqual(policy.failureCount(for: "device#1#normal"), ButtonBindingsReadbackRetryPolicy.failureLimit)
    }

    func testFailuresAreTrackedPerHydrationKey() {
        var policy = ButtonBindingsReadbackRetryPolicy()

        _ = policy.recordFailure(key: "device#1#normal")
        _ = policy.recordFailure(key: "device#1#hypershift")
        _ = policy.recordFailure(key: "device#1#hypershift")

        XCTAssertEqual(policy.failureCount(for: "device#1#normal"), 1)
        XCTAssertEqual(policy.failureCount(for: "device#1#hypershift"), 2, "layers must not share a retry budget")
    }

    func testSuccessRestoresTheFullBudget() {
        var policy = ButtonBindingsReadbackRetryPolicy()

        _ = policy.recordFailure(key: "device#1#normal")
        _ = policy.recordFailure(key: "device#1#normal")
        policy.recordSuccess(key: "device#1#normal")

        XCTAssertEqual(policy.failureCount(for: "device#1#normal"), 0)
        XCTAssertTrue(policy.recordFailure(key: "device#1#normal"), "a success must restore the retry budget")
    }

    func testRetainKeysDropsRemovedDevicesOnly() {
        var policy = ButtonBindingsReadbackRetryPolicy()

        _ = policy.recordFailure(key: "keep#1#normal")
        _ = policy.recordFailure(key: "drop#1#normal")
        policy.retainKeys { $0.hasPrefix("keep") }

        XCTAssertEqual(policy.failureCount(for: "keep#1#normal"), 1)
        XCTAssertEqual(policy.failureCount(for: "drop#1#normal"), 0)
    }
}
