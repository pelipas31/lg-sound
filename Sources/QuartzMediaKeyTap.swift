import Cocoa

final class QuartzMediaKeyTap: RecoverableMediaKeyTap {
    private var port: CFMachPort?
    private var source: CFRunLoopSource?
    private let handleEvent: (NSEvent) -> Bool

    var isValid: Bool { port.map { CFMachPortIsValid($0) } ?? false }
    var isEnabled: Bool { port.map { CGEvent.tapIsEnabled(tap: $0) } ?? false }

    init?(handleEvent: @escaping (NSEvent) -> Bool) {
        self.handleEvent = handleEvent
        let mask = CGEventMask(1) << NSEvent.EventType.systemDefined.rawValue
        port = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: mask, callback: { _, type, event, context in
                let owner = Unmanaged<QuartzMediaKeyTap>.fromOpaque(context!).takeUnretainedValue()
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    owner.enable()
                    return Unmanaged.passUnretained(event)
                }
                if let ns = NSEvent(cgEvent: event), owner.handleEvent(ns) { return nil }
                return Unmanaged.passUnretained(event)
            }, userInfo: Unmanaged.passUnretained(self).toOpaque())
        guard let port else { return nil }
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0) else {
            CFMachPortInvalidate(port)
            self.port = nil
            return nil
        }
        self.source = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        enable()
    }

    func enable() { if let port, CFMachPortIsValid(port) { CGEvent.tapEnable(tap: port, enable: true) } }

    func stop() {
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let port { CFMachPortInvalidate(port) }
        source = nil
        port = nil
    }

    deinit { stop() }
}
