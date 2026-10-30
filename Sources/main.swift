import Cocoa
import CoreAudio
import ServiceManagement

func L(_ key: String) -> String { NSLocalizedString(key, comment: "") }

// All DDC traffic is serialized off the UI thread. A process timeout also covers
// an unresponsive monitor after sleep or a cable disconnect.
enum DDC {
    static func run(_ args: [String]) throws -> String {
        let p = Process()
        p.executableURL = Bundle.main.resourceURL!.appendingPathComponent("m1ddc")
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        try p.run()
        let timeout = DispatchWorkItem { if p.isRunning { p.terminate() } }
        DispatchQueue.global().asyncAfter(deadline: .now() + 3, execute: timeout)
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        timeout.cancel()
        guard p.terminationStatus == 0 else {
            throw NSError(domain: "DDC", code: Int(p.terminationStatus))
        }
        return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

func outputName() -> String {
    var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    var device = AudioDeviceID(0)
    var size = UInt32(MemoryLayout.size(ofValue: device))
    guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device) == noErr else { return "" }
    address.mSelector = kAudioObjectPropertyName
    var name: Unmanaged<CFString>?
    size = UInt32(MemoryLayout.size(ofValue: name))
    guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &name) == noErr else { return "" }
    return name?.takeRetainedValue() as String? ?? ""
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let queue = DispatchQueue(label: "LGSound.DDC")
    var item: NSStatusItem!
    let menu = NSMenu()
    let slider = NSSlider(value: 0, minValue: 0, maxValue: 100, target: nil, action: nil)
    let title = NSTextField(labelWithString: "LG ULTRAGEAR+")
    let detail = NSTextField(wrappingLabelWithString: L("Ищу монитор…"))
    var permissionItem: NSMenuItem!
    var loginItem: NSMenuItem!
    var tap: CFMachPort?
    var tapSource: CFRunLoopSource?
    var uuid: String?
    var volume = 0
    var maximum = 100
    var beforeMute = 50
    var generation = 0
    var pending: DispatchWorkItem?
    var busy = false
    var timer: Timer?
    var outputTimer: Timer?
    var lgIsOutput = false
    var keyStatus = "Не подключён"
    var lastMediaEvent = "Нет событий"
    var lastDiagnostics = ""
    var controlWindow: NSWindow?
    var windowSlider: NSSlider?
    var windowDetail: NSTextField?

    var diagnosticsURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LG Sound/status.json")
    }

    func saveDiagnostics() {
        let info: [String: Any] = ["pid": ProcessInfo.processInfo.processIdentifier,
            "accessibility": AXIsProcessTrusted(), "tap": keyStatus,
            "output": outputName(), "monitor": uuid ?? "Нет связи", "volume": volume,
            "lastMediaEvent": lastMediaEvent,
            "menuIconVisible": item?.isVisible ?? false,
            "menuIconFrame": item?.button?.window.map { NSStringFromRect($0.frame) } ?? ""]
        guard let data = try? JSONSerialization.data(withJSONObject: info, options: [.prettyPrinted, .sortedKeys]),
              let text = String(data: data, encoding: .utf8), text != lastDiagnostics else { return }
        lastDiagnostics = text
        try? FileManager.default.createDirectory(at: diagnosticsURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: diagnosticsURL, options: .atomic)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Avoid two copies intercepting the same volume key.
        let copies = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier!)
        if copies.contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) { NSApp.terminate(nil); return }
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = "LGSound.Volume"
        item.isVisible = true
        item.button?.image = NSImage(systemSymbolName: "speaker.wave.2", accessibilityDescription: "LG Sound")
        item.button?.imagePosition = .imageLeading
        item.menu = menu
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 105))
        title.frame = NSRect(x: 18, y: 77, width: 264, height: 20)
        slider.frame = NSRect(x: 18, y: 46, width: 264, height: 24)
        detail.frame = NSRect(x: 18, y: 3, width: 264, height: 38)
        detail.font = .systemFont(ofSize: 11)
        detail.textColor = .secondaryLabelColor
        slider.isEnabled = false
        slider.target = self
        slider.action = #selector(sliderChanged)
        [title, slider, detail].forEach { view.addSubview($0) }
        let controls = NSMenuItem(); controls.view = view; menu.addItem(controls)
        add("Выключить / вернуть звук", #selector(mute))
        add("Открыть окно громкости", #selector(showControls))
        add("Обновить подключение", #selector(refresh))
        menu.addItem(.separator())
        permissionItem = add("Разрешить клавиши громкости…", #selector(requestKeys))
        loginItem = add("Запускать при входе", #selector(toggleLogin))
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        add("Открыть настройки звука…", #selector(soundSettings))
        menu.addItem(.separator())
        add("Выйти из LG Sound", #selector(quit))
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(refresh), name: NSWorkspace.didWakeNotification, object: nil)
        refresh()
        installTap()
        timer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in self?.refresh() }
        outputTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.lgIsOutput = outputName() == "LG ULTRAGEAR+"
            if self?.tap == nil { self?.installTap() }
            self?.saveDiagnostics()
        }
        lgIsOutput = outputName() == "LG ULTRAGEAR+"
        if !UserDefaults.standard.bool(forKey: "hasOpenedControls") {
            UserDefaults.standard.set(true, forKey: "hasOpenedControls")
            showControls()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        item.isVisible = true
        showControls()
        return false
    }

    @objc func showControls() {
        if controlWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 380, height: 220),
                styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = "LG Sound"
            window.delegate = self
            window.isReleasedWhenClosed = false
            window.center()
            let content = window.contentView!
            let label = NSTextField(labelWithString: "LG ULTRAGEAR+")
            label.font = .boldSystemFont(ofSize: 18)
            label.frame = NSRect(x: 24, y: 171, width: 330, height: 26)
            let volumeSlider = NSSlider(value: Double(volume), minValue: 0, maxValue: Double(maximum),
                target: self, action: #selector(windowSliderChanged))
            volumeSlider.frame = NSRect(x: 24, y: 126, width: 330, height: 28)
            let info = NSTextField(wrappingLabelWithString: detail.stringValue)
            info.frame = NSRect(x: 24, y: 67, width: 330, height: 48)
            info.font = .systemFont(ofSize: 12)
            let keys = NSButton(title: L("Разрешить клавиши громкости…"), target: self, action: #selector(requestKeys))
            keys.bezelStyle = .rounded
            keys.frame = NSRect(x: 18, y: 20, width: 232, height: 32)
            let muteButton = NSButton(title: L("Mute"), target: self, action: #selector(mute))
            muteButton.bezelStyle = .rounded
            muteButton.frame = NSRect(x: 260, y: 20, width: 96, height: 32)
            [label, volumeSlider, info, keys, muteButton].forEach { content.addSubview($0) }
            controlWindow = window
            windowSlider = volumeSlider
            windowDetail = info
        }
        windowSlider?.doubleValue = Double(volume)
        windowSlider?.maxValue = Double(maximum)
        windowSlider?.isEnabled = uuid != nil
        windowDetail?.stringValue = detail.stringValue
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        controlWindow?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    @objc func windowSliderChanged() {
        if let slider = windowSlider { setVolume(Int(slider.doubleValue.rounded())) }
    }

    @discardableResult func add(_ text: String, _ action: Selector) -> NSMenuItem {
        let entry = NSMenuItem(title: L(text), action: action, keyEquivalent: "")
        entry.target = self; menu.addItem(entry); return entry
    }

    @objc func refresh() {
        guard !busy, pending == nil else { return }
        busy = true
        let revision = generation
        queue.async {
            do {
                let list = try DDC.run(["display", "list"])
                let line = list.components(separatedBy: .newlines).first { $0.contains("LG ULTRAGEAR+") }
                guard let line, let start = line.lastIndex(of: "("), let end = line.lastIndex(of: ")") else { throw NSError(domain: "No LG", code: 1) }
                let id = String(line[line.index(after: start)..<end])
                guard let value = Int(try DDC.run(["display", id, "get", "volume"])),
                      let max = Int(try DDC.run(["display", id, "max", "volume"])),
                      max > 0, value >= 0, value <= max else { throw NSError(domain: "Invalid volume", code: 2) }
                DispatchQueue.main.async {
                    self.busy = false
                    guard revision == self.generation else { return }
                    self.uuid = id; self.maximum = max; self.volume = value
                    self.slider.maxValue = Double(max); self.slider.isEnabled = true
                    self.render()
                }
            } catch {
                DispatchQueue.main.async {
                    self.busy = false
                    guard revision == self.generation else { return }
                    self.uuid = nil; self.slider.isEnabled = false
                    self.item.button?.title = " ?"
                    self.detail.stringValue = L("LG не отвечает. Проверь кабель и DDC/CI в меню монитора.")
                    self.windowSlider?.isEnabled = false
                    self.windowDetail?.stringValue = self.detail.stringValue
                }
            }
        }
    }

    func render() {
        let percent = Int((Double(volume) / Double(maximum) * 100).rounded())
        item.button?.title = " \(percent)%"
        slider.doubleValue = Double(volume)
        detail.stringValue = String(format: L("Громкость LG: %d%%. Клавиши работают, когда звук выведен на LG."), percent)
        windowSlider?.maxValue = Double(maximum)
        windowSlider?.doubleValue = Double(volume)
        windowSlider?.isEnabled = uuid != nil
        windowDetail?.stringValue = detail.stringValue
    }

    func setVolume(_ value: Int) {
        guard let id = uuid else { return }
        volume = min(maximum, max(0, value)); generation += 1
        let revision = generation
        render()
        pending?.cancel()
        let desired = volume
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            // Only the newest slider position needs to reach the monitor.
            guard revision == self.generation else { return }
            self.pending = nil
            self.queue.async {
                do {
                    _ = try DDC.run(["display", id, "set", "volume", String(desired)])
                } catch {
                    DispatchQueue.main.async {
                        guard revision == self.generation else { return }
                        self.uuid = nil; self.slider.isEnabled = false
                        self.detail.stringValue = L("Не удалось изменить звук. Нажми «Обновить подключение».")
                        self.item.button?.title = " !"
                    }
                }
            }
        }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.07, execute: work)
    }

    @objc func sliderChanged() { setVolume(Int(slider.doubleValue.rounded())) }
    @objc func mute() {
        if volume > 0 { beforeMute = volume; setVolume(0) }
        else { setVolume(beforeMute) }
    }
    @objc func soundSettings() { NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Sound-Settings.extension")!) }
    @objc func quit() { NSApp.terminate(nil) }
    @objc func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
            loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        } catch {
            let alert = NSAlert(); alert.messageText = L("Не удалось изменить автозапуск")
            alert.informativeText = error.localizedDescription; alert.runModal()
        }
    }

    @objc func requestKeys() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        installTap()
    }

    func installTap() {
        guard tap == nil else { return }
        guard AXIsProcessTrusted() else {
            keyStatus = "Нет разрешения «Универсальный доступ»"
            permissionItem.title = L("Разрешить клавиши громкости…")
            return
        }
        let mask = CGEventMask(1) << NSEvent.EventType.systemDefined.rawValue
        guard let port = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: mask, callback: { _, type, event, context in
                let app = Unmanaged<AppDelegate>.fromOpaque(context!).takeUnretainedValue()
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let tap = app.tap { CGEvent.tapEnable(tap: tap, enable: true) }
                    return Unmanaged.passUnretained(event)
                }
                guard let ns = NSEvent(cgEvent: event), ns.subtype.rawValue == 8 else { return Unmanaged.passUnretained(event) }
                let key = (ns.data1 >> 16) & 0xffff
                guard [0, 1, 7].contains(key) else { return Unmanaged.passUnretained(event) }
                app.lastMediaEvent = "key=\(key), data=\(ns.data1), time=\(Date())"
                guard outputName() == "LG ULTRAGEAR+", app.uuid != nil else { return Unmanaged.passUnretained(event) }
                let down = ((ns.data1 >> 8) & 0xff) == 0xA
                if down {
                    let step = max(1, Int((Double(app.maximum) / 16).rounded()))
                    if key == 7 { if (ns.data1 & 1) == 0 { app.mute() } }
                    else { app.setVolume(app.volume + (key == 0 ? step : -step)) }
                }
                return nil
            }, userInfo: Unmanaged.passUnretained(self).toOpaque()) else {
                keyStatus = "macOS отказала в перехвате"
                permissionItem.title = L("Перехват не подключён — разрешить…")
                return
            }
        tap = port
        keyStatus = "Подключён"
        tapSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), tapSource, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        permissionItem.title = L("Клавиши громкости подключены ✓")
        permissionItem.isEnabled = false
    }
}

// Also useful when diagnosing a cable or permission issue without opening UI.
if CommandLine.arguments.contains("--diagnose") {
    do {
        print("Аудиовыход: \(outputName())")
        print(try DDC.run(["display", "list"]))
        print("Универсальный доступ: \(AXIsProcessTrusted())")
        exit(0)
    } catch {
        fputs("DDC: \(error)\n", stderr)
        exit(1)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
