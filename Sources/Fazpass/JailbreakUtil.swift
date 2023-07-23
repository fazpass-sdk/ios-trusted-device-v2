
import UIKit

internal struct JailbreakUtil {
    
    private let prohibitedDirList = [
        "/var/cache/apt",
        "/var/lib/apt",
        "/var/lib/cydia",
        "/var/log/syslog",
        "/var/tmp/cydia.log",
        "/private/var/stash",
        "/private/var/lib/apt",
        "/private/var/tmp/cydia.log",
        "/private/var/lib/cydia",
        "/private/var/mobile/Library/SBSettings/Themes",
        "/Applications/Cydia.app",
        "/Applications/RockApp.app",
        "/Applications/Icy.app",
        "/Applications/WinterBoard.app",
        "/Applications/SBSetttings.app",
        "/Applications/blackra1n.app",
        "/Applications/IntelliScreen.app",
        "/Applications/Snoop-itConfig.app",
        "/Applications/MxTube.app",
        "/Applications/FakeCarrier.app",
        "/bin/sh",
        "/bin/bash",
        "/etc/apt",
        "/etc/ssh/sshd_config",
        "/usr/libexec/sftp-server",
        "/usr/libexec/ssh-keysign",
        "/usr/bin/sshd",
        "/usr/sbin/sshd",
        "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
        "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
        "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
        "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
        "/Library/MobileSubstrate/MobileSubstrate.dylib"
    ]
    
    private let app: UIApplication
    private let fileManager: FileManager
    
    init(_ app: UIApplication) {
        self.app = app
        self.fileManager = FileManager.default
    }
    
    func isJailbroken() -> Bool {
        return hasAnyProhibitedDir() || canWriteToProtectedDir()
    }
    
    private func hasAnyProhibitedDir() -> Bool {
        prohibitedDirList.contains { s in
            return fileManager.fileExists(atPath: s)
        }
    }
    
    private func canWriteToProtectedDir() -> Bool {
        let jailBreakTestText = "Test for JailBreak"
        do {
            try jailBreakTestText.write(toFile:"/private/jailBreakTestText.txt", atomically:true, encoding:String.Encoding.utf8)
            return true
        } catch {
            return false
        }
    }
}
