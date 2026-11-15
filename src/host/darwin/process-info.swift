// Read-only Darwin process metadata for the existing-client host boundary.
import Darwin
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 2, let pid = Int32(arguments[1]), pid > 0 else { exit(2) }
var process = kinfo_proc()
var size = MemoryLayout<kinfo_proc>.size
var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
let result = mib.withUnsafeMutableBufferPointer { pointer in
    sysctl(pointer.baseAddress, u_int(pointer.count), &process, &size, nil, 0)
}
guard result == 0, size == MemoryLayout<kinfo_proc>.size else { exit(1) }
guard process.kp_eproc.e_pcred.p_ruid == getuid() else { exit(3) }
var path = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
guard proc_pidpath(pid, &path, UInt32(path.count)) > 0 else { exit(1) }
let record: [String: Any] = [
    "pid": pid, "uid": getuid(),
    "birth": "\(process.kp_proc.p_starttime.tv_sec):\(process.kp_proc.p_starttime.tv_usec)",
    "caught": (process.kp_proc.p_sigcatch & (1 << (SIGUSR1 - 1))) != 0,
    "executable": path.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
]
guard let data = try? JSONSerialization.data(withJSONObject: record, options: [.sortedKeys]) else { exit(1) }
FileHandle.standardOutput.write(data)
FileHandle.standardOutput.write(Data([0x0a]))
