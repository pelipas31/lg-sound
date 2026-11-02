import Foundation

final class FakeTap: RecoverableMediaKeyTap {
    var isValid = true
    var isEnabled = true
    var enableWorks = true
    var enables = 0
    var stops = 0
    func enable() { enables += 1; isEnabled = enableWorks && isValid }
    func stop() { stops += 1; isValid = false; isEnabled = false }
}

final class Rig {
    var route = AudioRoute(id: 10, name: "LG ULTRAGEAR+")
    var trusted = true
    var failInstall = false
    var createDisabled = false
    var taps: [FakeTap] = []
    lazy var recovery = MediaKeyRecovery(readRoute: { self.route }, isTrusted: { self.trusted }, makeTap: {
        if self.failInstall { return nil }
        let tap = FakeTap()
        tap.isEnabled = !self.createDisabled
        self.taps.append(tap)
        return tap
    })
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

// Reproduce listening on headphones and switching back to a monitor, including
// a newly assigned CoreAudio device ID with the same display name.
let switching = Rig()
switching.recovery.check()
expect(switching.recovery.canControlMonitor, "Initial monitor route must control LG")
let initial = switching.taps.last!
switching.route = AudioRoute(id: 20, name: "Headphones")
switching.recovery.check()
expect(!switching.recovery.canControlMonitor, "Headphone commands must pass through")
expect(initial.stops == 1, "Route transition must dispose of the old port")
switching.route = AudioRoute(id: 30, name: "LG ULTRAGEAR+")
switching.recovery.check()
expect(switching.recovery.canControlMonitor && switching.recovery.tapEnabled, "Returning to LG must reconnect")
let count = switching.taps.count
switching.route = AudioRoute(id: 31, name: "LG ULTRAGEAR+")
switching.recovery.check()
expect(switching.taps.count == count + 1, "A recreated audio device must reconnect even when its name is unchanged")
print("PASS: LG → headphones → LG, including device ID replacement")

let sleeping = Rig()
sleeping.recovery.check()
let beforeSleep = sleeping.taps.last!
sleeping.recovery.check(forceReconnect: true)
expect(beforeSleep.stops == 1 && sleeping.recovery.canControlMonitor, "Wake recovery must replace a stale session")
print("PASS: force reconnect after wake")

let disabled = Rig()
disabled.recovery.check()
let suspended = disabled.taps.last!
suspended.isEnabled = false
disabled.recovery.check()
expect(suspended.enables == 1 && disabled.recovery.tapEnabled, "Watchdog must resume disabled taps")
expect(disabled.taps.count == 1, "A resumable port need not be recreated")
suspended.isEnabled = false
suspended.enableWorks = false
disabled.recovery.check()
expect(suspended.stops == 1 && disabled.taps.count == 2 && disabled.recovery.tapEnabled,
       "A port that refuses re-enabling must be replaced")
print("PASS: silent disable and failed re-enable")

let invalid = Rig()
invalid.recovery.check()
invalid.taps.last!.isValid = false
invalid.recovery.check()
expect(invalid.taps.count == 2 && invalid.recovery.canControlMonitor, "Invalid ports must be replaced")
for _ in 0..<5 { invalid.recovery.check() }
expect(invalid.taps.count == 2, "Healthy periodic checks must not churn ports")
print("PASS: invalid port recovery without repeated healthy reconnects")

let permission = Rig()
permission.recovery.check()
let oldPort = permission.taps.last!
permission.trusted = false
permission.recovery.check()
expect(permission.recovery.state == .permissionRequired && oldPort.stops == 1, "Revocation must stop interception")
expect(!permission.recovery.canControlMonitor, "Missing permission must never report active media keys")
permission.recovery.check()
expect(permission.taps.count == 1, "Do not try to bypass missing permission")
permission.trusted = true
permission.recovery.check()
expect(permission.recovery.canControlMonitor && permission.taps.count == 2, "Grant must reconnect without restarting app")
print("PASS: permission revoke and re-grant")

let failed = Rig()
failed.failInstall = true
failed.recovery.check()
expect(failed.recovery.state == .unavailable, "Installation failure must not report ready")
failed.failInstall = false
failed.createDisabled = true
failed.recovery.check()
expect(failed.recovery.state == .unavailable && failed.taps.last!.stops == 1, "Discard an unusable new port")
failed.createDisabled = false
failed.recovery.check()
expect(failed.recovery.canControlMonitor, "Next health check must retry failed installations")
print("PASS: retry failed or unusable installation")

switching.route = .unknown
switching.recovery.check()
expect(!switching.recovery.canControlMonitor, "Unknown output must pass media commands through")
print("PASS: unknown output does not control monitor")
print("All media-key recovery regression scenarios passed.")
