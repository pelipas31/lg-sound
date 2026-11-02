import Foundation

struct AudioRoute: Equatable {
    let id: UInt32
    let name: String
    var isMonitor: Bool { name == "LG ULTRAGEAR+" }
    static let unknown = AudioRoute(id: 0, name: "")
}

protocol RecoverableMediaKeyTap: AnyObject {
    var isValid: Bool { get }
    var isEnabled: Bool { get }
    func enable()
    func stop()
}

// Main-thread state machine. Its dependencies also let regression tests exercise
// device switches and failed event taps without changing the machine's audio.
final class MediaKeyRecovery {
    enum State: String { case starting, permissionRequired, unavailable, ready }
    private let readRoute: () -> AudioRoute
    private let isTrusted: () -> Bool
    private let makeTap: () -> RecoverableMediaKeyTap?
    private var tap: RecoverableMediaKeyTap?
    private(set) var route = AudioRoute.unknown
    private(set) var state = State.starting
    private(set) var connectionCount = 0
    private(set) var resumeCount = 0
    var canControlMonitor: Bool { state == .ready && route.isMonitor }
    var tapEnabled: Bool { tap?.isValid == true && tap?.isEnabled == true }

    init(readRoute: @escaping () -> AudioRoute, isTrusted: @escaping () -> Bool,
         makeTap: @escaping () -> RecoverableMediaKeyTap?) {
        self.readRoute = readRoute
        self.isTrusted = isTrusted
        self.makeTap = makeTap
    }

    @discardableResult func check(forceReconnect: Bool = false) -> Bool {
        let newRoute = readRoute()
        let changed = route != newRoute
        route = newRoute
        guard isTrusted() else {
            stop()
            state = .permissionRequired
            return changed
        }
        if changed || forceReconnect || tap?.isValid == false { stop() }
        if let tap, !tap.isEnabled {
            tap.enable()
            resumeCount += 1
            if !tap.isEnabled { stop() }
        }
        if tap == nil {
            tap = makeTap()
            if tap != nil { connectionCount += 1 }
        }
        state = tapEnabled ? .ready : .unavailable
        // A factory may return an already invalid/disabled port. Discard it so
        // the next health check can actually retry instead of keeping a corpse.
        if state == .unavailable { stop() }
        return changed
    }

    func stop() {
        tap?.stop()
        tap = nil
    }
}
