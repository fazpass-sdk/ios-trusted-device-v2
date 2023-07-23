
import Foundation

class IPAddressUtil {
    
    static let url = URL(string: "https://api.ipify.org")
    
    static func get() -> String {
        do {
            if let url = url {
                let ipAddress = try String(contentsOf: url)
                return ipAddress
            }
        } catch let error {
            print(error)
        }
        
        return ""
    }
}
