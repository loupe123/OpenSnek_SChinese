import Foundation

/// Bounded retry bookkeeping for button-binding readback hydration.
///
/// Hydration is guarded by a one-shot attempt marker so a single refresh does not loop against the
/// device. That marker used to be permanent, so one transient failure parked the workspace forever
/// and left the editor showing defaults for a layer the device never answered for. This policy keeps
/// the retry bounded instead: failures release the marker while a budget remains, and once the budget
/// is exhausted the key stays parked until the next explicit refresh.
struct ButtonBindingsReadbackRetryPolicy: Equatable {
    /// Consecutive failures tolerated before a key stays parked until the next explicit refresh.
    static let failureLimit = 3

    private(set) var failureCounts: [String: Int] = [:]

    /// Records a failure and reports whether the caller should release its one-shot attempt marker.
    @discardableResult mutating func recordFailure(key: String) -> Bool {
        let failures = (failureCounts[key] ?? 0) + 1
        failureCounts[key] = failures
        return failures < Self.failureLimit
    }

    mutating func recordSuccess(key: String) { failureCounts.removeValue(forKey: key) }

    func failureCount(for key: String) -> Int { failureCounts[key] ?? 0 }

    /// Drops bookkeeping for keys whose device is gone.
    mutating func retainKeys(where isRetained: (String) -> Bool) { failureCounts = failureCounts.filter { isRetained($0.key) } }
}
