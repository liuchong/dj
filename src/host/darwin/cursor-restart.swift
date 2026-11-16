// An explicit operator-authorized native App restart. No prompt/session argv.
import AppKit
import Darwin

func reply(_ value: [String: Any], _ status: Int32 = 0) -> Never {
    let bytes = try! JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
    FileHandle.standardOutput.write(bytes)
    FileHandle.standardOutput.write(Data([10]))
    exit(status)
}
let bytes = FileHandle.standardInput.readData(ofLength: 8193)
guard bytes.count <= 8192,
      let request = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any],
      let number = request["pid"] as? Int, number > 0, number <= Int(Int32.max),
      let birth = request["birth"] as? String,
      let app = NSRunningApplication(processIdentifier: pid_t(number)),
      let url = app.bundleURL, app.executableURL?.lastPathComponent == "Cursor",
      !app.isTerminated else { reply(["ok": false, "reason": "restart_target_invalid"], 1) }
var process = kinfo_proc()
var length = MemoryLayout<kinfo_proc>.size
var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, Int32(number)]
let status = mib.withUnsafeMutableBufferPointer { sysctl($0.baseAddress, u_int($0.count), &process, &length, nil, 0) }
guard status == 0, length == MemoryLayout<kinfo_proc>.size,
      process.kp_eproc.e_pcred.p_ruid == getuid(),
      birth == "\(process.kp_proc.p_starttime.tv_sec):\(process.kp_proc.p_starttime.tv_usec)" else {
    reply(["ok": false, "reason": "restart_process_changed"], 1)
}
guard app.terminate() else { reply(["ok": false, "reason": "restart_quit_refused"], 1) }
// NSRunningApplication termination KVO can lag in a command-line host.
// Confirm kernel process absence; never treat an unconfirmed timeout as exit.
func exited() -> Bool { kill(pid_t(number), 0) == -1 && errno == ESRCH }
let limit = Date().addingTimeInterval(12)
while !exited() && Date() < limit { RunLoop.current.run(until: Date().addingTimeInterval(0.05)) }
guard exited() else { reply(["ok": false, "reason": "restart_quit_pending"], 1) }
let configuration = NSWorkspace.OpenConfiguration()
configuration.activates = false
configuration.createsNewApplicationInstance = false
// Only native debugger configuration. Business input always uses the IPC API.
configuration.arguments = ["--inspect-port=127.0.0.1:9229"]
var finished = false
var result: [String: Any] = ["ok": false, "reason": "restart_launch_pending"]
NSWorkspace.shared.openApplication(at: url, configuration: configuration) { opened, error in
    if let opened, error == nil { result = ["ok": true, "pid": Int(opened.processIdentifier)] }
    finished = true
}
let deadline = Date().addingTimeInterval(12)
while !finished && Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.05)) }
reply(result, result["ok"] as? Bool == true ? 0 : 1)
