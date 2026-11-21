// Read-only Darwin process metadata and Antigravity desktop authentication.
import Darwin
import Foundation

struct ProcessIdentity: Equatable {
    let pid: pid_t
    let parent: pid_t
    let birth: String
    let executable: String
    let catchesInspectorSignal: Bool
}

func processIdentity(_ pid: pid_t) -> ProcessIdentity? {
    var process = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.size
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
    let result = sysctl(&mib, 4, &process, &size, nil, 0)
    guard result == 0, size == MemoryLayout<kinfo_proc>.size,
          process.kp_eproc.e_pcred.p_ruid == getuid() else { return nil }
    var path = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
    guard proc_pidpath(pid, &path, UInt32(path.count)) > 0 else { return nil }
    return ProcessIdentity(
        pid: pid, parent: process.kp_eproc.e_ppid,
        birth: "\(process.kp_proc.p_starttime.tv_sec):\(process.kp_proc.p_starttime.tv_usec)",
        executable: path.withUnsafeBufferPointer { String(cString: $0.baseAddress!) },
        catchesInspectorSignal: (process.kp_proc.p_sigcatch & (1 << (SIGUSR1 - 1))) != 0
    )
}

func desktopCredential(in bytes: UnsafeRawBufferPointer) -> Range<Int>? {
    // KERN_PROCARGS2 returns argc, the executable, NUL padding, argv, then env.
    let header = MemoryLayout<CInt>.size
    guard bytes.count > header else { return nil }
    let argc = Int(bytes.loadUnaligned(as: CInt.self))
    guard argc > 0 && argc <= bytes.count - header,
          let executableEnd = bytes[header...].firstIndex(of: 0) else { return nil }
    var index = executableEnd + 1
    while index < bytes.count && bytes[index] == 0 { index += 1 }
    var appDataDirectory = false
    var standalone = false
    let appDataFlag = Array("--app_data_dir".utf8)
    let appDataValue = Array("antigravity".utf8)
    let standaloneFlag = Array("--standalone".utf8)
    let appDataArgument = appDataFlag + [61] + appDataValue
    var expectAppDataValue = false
    for _ in 0..<argc {
        guard index < bytes.count, let end = bytes[index...].firstIndex(of: 0) else { return nil }
        let argument = bytes[index..<end]
        if expectAppDataValue || argument.elementsEqual(appDataArgument) {
            appDataDirectory = !expectAppDataValue || argument.elementsEqual(appDataValue)
        }
        expectAppDataValue = argument.elementsEqual(appDataFlag)
        standalone = standalone || argument.elementsEqual(standaloneFlag)
        index = end + 1
    }
    guard appDataDirectory, standalone else { return nil }

    let key = Array("ANTIGRAVITY_SERVER_CSRF_TOKEN=".utf8)
    var found: Range<Int>?
    while index < bytes.count && bytes[index] != 0 {
        guard let end = bytes[index...].firstIndex(of: 0) else { return nil }
        if bytes[index..<end].starts(with: key) {
            let value = (index + key.count)..<end
            guard found == nil, (16...256).contains(value.count),
                  bytes[value].allSatisfy({
                    (48...57).contains($0) || (65...90).contains($0)
                      || (97...122).contains($0) || $0 == 45 || $0 == 95
                  }) else { return nil }
            found = value
        }
        index = end + 1
    }
    return found
}

func writeDesktopCredential(pid: pid_t, birth: String, parentPID: pid_t, parentBirth: String) -> Bool {
    let serverSuffix = "/Contents/Resources/bin/language_server"
    guard isatty(STDOUT_FILENO) == 0,
          let server = processIdentity(pid), server.birth == birth, server.parent == parentPID,
          let parent = processIdentity(parentPID), parent.birth == parentBirth,
          server.executable.hasSuffix(serverSuffix) else { return false }
    let app = String(server.executable.dropLast(serverSuffix.count))
    guard app.hasSuffix(".app"), parent.executable == app + "/Contents/MacOS/Antigravity" else { return false }

    // Darwin's KERN_PROCARGS2 selector is not imported by all SDKs.
    let processArgumentsWithCount: Int32 = 49
    var mib: [Int32] = [CTL_KERN, processArgumentsWithCount, pid]
    var size = 0
    guard sysctl(&mib, 3, nil, &size, nil, 0) == 0,
          (MemoryLayout<CInt>.size...1_048_576).contains(size) else { return false }
    var bytes = [UInt8](repeating: 0, count: size)
    return bytes.withUnsafeMutableBytes { buffer in
        defer { _ = buffer.initializeMemory(as: UInt8.self, repeating: 0) }
        guard sysctl(&mib, 3, buffer.baseAddress, &size, nil, 0) == 0,
              size <= buffer.count,
              let value = desktopCredential(in: UnsafeRawBufferPointer(start: buffer.baseAddress, count: size)),
              processIdentity(pid) == server, processIdentity(parentPID) == parent else { return false }
        return Darwin.write(STDOUT_FILENO, buffer.baseAddress!.advanced(by: value.lowerBound), value.count) == value.count
    }
}

let arguments = CommandLine.arguments
if arguments.count == 6 && arguments[1] == "antigravity-credential" {
    guard let pid = Int32(arguments[2]), pid > 0, let parent = Int32(arguments[4]), parent > 0 else { exit(2) }
    exit(writeDesktopCredential(pid: pid, birth: arguments[3], parentPID: parent, parentBirth: arguments[5]) ? 0 : 3)
}

guard arguments.count == 2, let pid = Int32(arguments[1]), pid > 0 else { exit(2) }
guard let process = processIdentity(pid) else { exit(1) }
let record: [String: Any] = [
    "pid": pid, "uid": getuid(),
    "birth": process.birth, "caught": process.catchesInspectorSignal, "executable": process.executable
]
guard let data = try? JSONSerialization.data(withJSONObject: record, options: [.sortedKeys]) else { exit(1) }
FileHandle.standardOutput.write(data)
FileHandle.standardOutput.write(Data([0x0a]))
