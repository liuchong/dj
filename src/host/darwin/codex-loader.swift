// Deliver an existing-thread URL to an existing same-user App process only.
// No launch API, command-line prompt, model request or permission override.
import AppKit
import Darwin

func fail(_ reason: String) -> Never {
    let bytes = try! JSONSerialization.data(withJSONObject: ["ok": false, "reason": reason])
    FileHandle.standardOutput.write(bytes)
    exit(1)
}
let input = FileHandle.standardInput.readData(ofLength: 8193)
guard input.count <= 8192,
      let request = try? JSONSerialization.jsonObject(with: input) as? [String: Any],
      let pidNumber = request["pid"] as? Int, pidNumber > 0, pidNumber <= Int(Int32.max),
      let birth = request["birth"] as? String,
      let thread = request["thread"] as? String, UUID(uuidString: thread) != nil,
      let app = NSRunningApplication(processIdentifier: pid_t(pidNumber)),
      app.bundleIdentifier == "com.openai.codex", !app.isTerminated else {
    fail("receiver_load_target_invalid")
}
var process = kinfo_proc()
var size = MemoryLayout<kinfo_proc>.size
var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, Int32(pidNumber)]
let result = mib.withUnsafeMutableBufferPointer {
    sysctl($0.baseAddress, u_int($0.count), &process, &size, nil, 0)
}
guard result == 0, size == MemoryLayout<kinfo_proc>.size,
      process.kp_eproc.e_pcred.p_ruid == getuid(),
      birth == "\(process.kp_proc.p_starttime.tv_sec):\(process.kp_proc.p_starttime.tv_usec)" else {
    fail("receiver_load_process_changed")
}
// Address by PID, never by bundle launch. neverInteract prevents permission UI.
let event = NSAppleEventDescriptor(eventClass: 0x4755524c, eventID: 0x4755524c,
    targetDescriptor: NSAppleEventDescriptor(processIdentifier: pid_t(pidNumber)),
    returnID: -1, transactionID: 0)
event.setParam(NSAppleEventDescriptor(string: "codex://threads/\(thread)"), forKeyword: 0x2d2d2d2d)
do {
    _ = try event.sendEvent(options: [.noReply, .neverInteract], timeout: 2)
    FileHandle.standardOutput.write(Data("{\"ok\":true,\"state\":\"requested\"}\n".utf8))
} catch {
    fail((error as NSError).code == -1743 ? "receiver_load_permission_denied" : "receiver_load_rejected")
}
