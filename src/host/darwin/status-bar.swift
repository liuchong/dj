// AppKit projection only. Service control belongs to the Eliscript backend.
import AppKit
import CoreServices
import Darwin

func menuIcon() -> NSImage {
    let image = NSImage(size: NSSize(width: 20, height: 20), flipped: true) { bounds in
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        let scale = NSAffineTransform()
        scale.scaleX(by: bounds.width / 128, yBy: bounds.height / 128)
        scale.concat()
        NSColor.black.setStroke()
        NSColor.black.setFill()
        let links = NSBezierPath()
        links.lineWidth = 7
        links.lineCapStyle = .round
        links.lineJoinStyle = .round
        for points: [NSPoint] in [[.init(x: 14, y: 18), .init(x: 29, y: 18), .init(x: 99, y: 110), .init(x: 114, y: 110)],
                                  [.init(x: 14, y: 110), .init(x: 29, y: 110), .init(x: 99, y: 18), .init(x: 114, y: 18)]] {
            links.move(to: points[0])
            for point in points.dropFirst() { links.line(to: point) }
        }
        links.stroke()
        let discs = NSBezierPath()
        discs.lineWidth = 3
        discs.appendOval(in: NSRect(x: 9, y: 40, width: 48, height: 48))
        discs.appendOval(in: NSRect(x: 71, y: 40, width: 48, height: 48))
        discs.stroke()
        let letters = NSBezierPath()
        letters.lineWidth = 6
        letters.lineCapStyle = .round
        letters.lineJoinStyle = .round
        letters.move(to: .init(x: 22, y: 49)); letters.line(to: .init(x: 31, y: 49))
        letters.curve(to: .init(x: 48, y: 64), controlPoint1: .init(x: 41, y: 49), controlPoint2: .init(x: 48, y: 54))
        letters.curve(to: .init(x: 31, y: 79), controlPoint1: .init(x: 48, y: 74), controlPoint2: .init(x: 41, y: 79))
        letters.line(to: .init(x: 22, y: 79)); letters.close()
        letters.move(to: .init(x: 88, y: 49)); letters.line(to: .init(x: 105, y: 49))
        letters.line(to: .init(x: 105, y: 67))
        letters.curve(to: .init(x: 90, y: 82), controlPoint1: .init(x: 105, y: 77), controlPoint2: .init(x: 100, y: 82))
        letters.line(to: .init(x: 84, y: 82)); letters.stroke()
        let junction = NSBezierPath()
        junction.move(to: .init(x: 64, y: 54)); junction.line(to: .init(x: 74, y: 64))
        junction.line(to: .init(x: 64, y: 74)); junction.line(to: .init(x: 54, y: 64))
        junction.close(); junction.fill()
        return true
    }
    image.isTemplate = true
    return image
}

final class DJControlView: NSView {
    weak var popover: NSPopover?
    override var acceptsFirstResponder: Bool { true }
    override func cancelOperation(_ sender: Any?) { popover?.performClose(nil) }
}

final class DJStatusBar: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var item: NSStatusItem!
    var statusLine: NSTextField!
    var detailLine: NSTextField!
    var startItem: NSButton!
    var stopItem: NSButton!
    var controllerPanel: NSPopover!
    var backend: Process?
    var commands: Pipe?
    var buffer = Data()
    var root = ""
    var lockFD: Int32 = -1

    func showStatus(_ status: [String: Any]) {
        let statusTitle = "服务：" + (status["label"] as? String ?? "控制器异常")
        let detail = status["detail"] as? String ?? ""
        statusLine.stringValue = statusTitle
        detailLine.stringValue = detail.isEmpty ? "只控制本机 DJ，不启动 AI 客户端" : detail
        startItem.isEnabled = status["can_start"] as? Bool ?? false
        stopItem.isEnabled = status["can_stop"] as? Bool ?? false
        item.button?.toolTip = statusTitle
    }
    func panelButton(_ title: String, action: Selector, parent: NSView, y: CGFloat) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.frame = NSRect(x: 16, y: y, width: 268, height: 27)
        button.bezelStyle = .rounded
        parent.addSubview(button)
        return button
    }
    func panelLabel(_ title: String, parent: NSView, y: CGFloat, size: CGFloat) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.frame = NSRect(x: 16, y: y, width: 268, height: 23)
        label.font = .systemFont(ofSize: size)
        label.lineBreakMode = .byTruncatingTail
        parent.addSubview(label)
        return label
    }
    func sendAction(_ action: String) {
        guard backend?.isRunning == true,
              var data = try? JSONSerialization.data(withJSONObject: ["action": action]) else { return }
        data.append(0x0a)
        try? commands?.fileHandleForWriting.write(contentsOf: data)
    }
    @objc func startService(_ sender: Any?) { sendAction("start") }
    @objc func stopService(_ sender: Any?) { sendAction("stop") }
    @objc func refresh(_ sender: Any?) { sendAction("refresh") }
    func updatePanelState() { item.button?.setAccessibilityValue(controllerPanel.isShown ? "已展开" : "已收起") }
    func popoverDidShow(_ notification: Notification) { updatePanelState() }
    func popoverDidClose(_ notification: Notification) { updatePanelState() }
    @objc func closePanel(_ sender: Any?) { controllerPanel.performClose(nil) }
    @objc func toggleMenu(_ sender: Any?) {
        if controllerPanel.isShown { controllerPanel.performClose(nil); return }
        guard let button = item.button else { return }
        sendAction("refresh")
        controllerPanel.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        controllerPanel.contentViewController?.view.window?.makeKey()
        controllerPanel.contentViewController?.view.window?.makeFirstResponder(controllerPanel.contentViewController?.view)
    }
    @objc func openConfiguration(_ sender: Any?) { NSWorkspace.shared.open(URL(fileURLWithPath: root, isDirectory: true)) }
    @objc func quit(_ sender: Any?) { NSApp.terminate(nil) }
    func consume(_ data: Data) {
        buffer.append(data)
        guard buffer.count <= 65536 else { backend?.terminate(); buffer.removeAll(); return }
        while let end = buffer.firstIndex(of: 0x0a) {
            let line = Data(buffer[..<end])
            buffer.removeSubrange(...end)
            if let status = (try? JSONSerialization.jsonObject(with: line)) as? [String: Any],
               status["type"] as? String == "status", backend?.isRunning == true { showStatus(status) }
        }
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let bundle = Bundle.main
        guard let directory = bundle.object(forInfoDictionaryKey: "DJRootDirectory") as? String, !directory.isEmpty,
              let runtime = bundle.object(forInfoDictionaryKey: "DJRuntimePath") as? String, !runtime.isEmpty else {
            NSApp.terminate(nil); return
        }
        root = directory
        let lock = URL(fileURLWithPath: root).appendingPathComponent("run/controller.lock").path
        lockFD = open(lock, O_CREAT | O_RDWR | O_CLOEXEC | O_NOFOLLOW, 0o600)
        guard lockFD >= 0, flock(lockFD, LOCK_EX | LOCK_NB) == 0 else { NSApp.terminate(nil); return }
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.autosaveName = "DJ.ServiceController"
        item.isVisible = true
        item.button?.image = menuIcon()
        item.button?.setAccessibilityLabel("DJ 服务控制器")
        controllerPanel = NSPopover()
        controllerPanel.delegate = self
        controllerPanel.behavior = .applicationDefined
        controllerPanel.animates = false
        let content = NSViewController()
        let view = DJControlView(frame: NSRect(x: 0, y: 0, width: 300, height: 290))
        view.popover = controllerPanel; content.view = view
        view.setAccessibilityLabel("DJ 服务控制面板")
        _ = panelLabel("Dispatch Junction", parent: view, y: 255, size: 15)
        statusLine = panelLabel("服务：检查中", parent: view, y: 229, size: 13)
        detailLine = panelLabel("", parent: view, y: 205, size: 11)
        detailLine.textColor = .secondaryLabelColor
        startItem = panelButton("启动服务", action: #selector(startService(_:)), parent: view, y: 168)
        stopItem = panelButton("停止服务", action: #selector(stopService(_:)), parent: view, y: 135)
        _ = panelButton("立即刷新", action: #selector(refresh(_:)), parent: view, y: 102)
        _ = panelButton("打开 DJ 配置目录", action: #selector(openConfiguration(_:)), parent: view, y: 69)
        let close = panelButton("收起", action: #selector(closePanel(_:)), parent: view, y: 36)
        close.keyEquivalent = "\u{1b}"
        _ = panelButton("退出控制器（服务继续运行）", action: #selector(quit(_:)), parent: view, y: 3)
        controllerPanel.contentViewController = content
        controllerPanel.contentSize = view.frame.size
        updatePanelState()
        item.button?.target = self; item.button?.action = #selector(toggleMenu(_:))
        item.button?.sendAction(on: [.leftMouseDown, .rightMouseDown])
        let menu = NSMenu(), appMenu = NSMenu()
        let entry = NSMenuItem(title: "DJ Control", action: nil, keyEquivalent: "")
        entry.submenu = appMenu; menu.addItem(entry)
        let quit = NSMenuItem(title: "退出控制器（服务继续运行）", action: #selector(self.quit(_:)), keyEquivalent: "q")
        quit.target = self; appMenu.addItem(quit); NSApp.mainMenu = menu
        showStatus(["state": "starting", "label": "检查中"])
        let process = Process(), input = Pipe(), output = Pipe()
        backend = process; commands = input
        process.executableURL = URL(fileURLWithPath: runtime)
        process.arguments = [bundle.resourceURL!.appendingPathComponent("darwin/main.mjs").path, root]
        process.standardInput = input; process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        output.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty { handle.readabilityHandler = nil; return }
            DispatchQueue.main.async { self?.consume(data) }
        }
        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async { self?.showStatus(["state": "error", "label": "控制器后端已退出", "detail": "退出控制器后重新打开；DJ 服务不受影响"]) }
        }
        do { try process.run() }
        catch { showStatus(["state": "error", "label": "无法启动控制器后端", "detail": "请检查已安装的 Bun 运行时"]) }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        item?.isVisible = true
        return false
    }
    func applicationWillTerminate(_ notification: Notification) {
        if backend?.isRunning == true { backend?.terminate() }
        if lockFD >= 0 { Darwin.close(lockFD) }
    }
}

let applications = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask).first
let arguments = CommandLine.arguments
if arguments.count == 2 {
    switch arguments[1] {
    case "--application-directory":
        guard let applications else { exit(1) }
        print(applications.path); exit(0)
    case "--register-app":
        exit(LSRegisterURL(Bundle.main.bundleURL as CFURL, true) == noErr ? 0 : 1)
    case "--quit-controller":
        let owned = applications?.appendingPathComponent("DJ Control.app").path
        for running in NSRunningApplication.runningApplications(withBundleIdentifier: "dev.dispatch-junction.controller") {
            guard running.bundleURL?.path == owned else { continue }
            running.terminate()
            for _ in 0..<100 {
                if kill(running.processIdentifier, 0) != 0 { break }
                Thread.sleep(forTimeInterval: 0.05)
            }
            if kill(running.processIdentifier, 0) == 0 { exit(1) }
        }
        exit(0)
    default: exit(2)
    }
}
guard arguments.count == 1 else { exit(2) }
signal(SIGPIPE, SIG_IGN)
let app = NSApplication.shared
let delegate = DJStatusBar()
app.delegate = delegate
app.run()
