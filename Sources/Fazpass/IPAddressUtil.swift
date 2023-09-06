
import Foundation

internal class IPAddressUtil {
    
    static let url = URL(string: "https://api.ipify.org")
    
    static func get() -> String {
        do {
            if let url = url {
                let ipAddress = try String(contentsOf: url)
                return ipAddress
            }
        } catch {
            print(error)
        }
        
        return ""
    }
}
