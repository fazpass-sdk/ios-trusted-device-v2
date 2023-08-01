
import Foundation

internal struct MetaData: Codable {
    let platform: String
    let bundleIdentifier: String
    let isJailbroken: Bool
    let isVpn: Bool
    let isAppCloned: Bool
    let isScreenSharing: Bool
    let isEmulator: Bool
    let isDebug: Bool
    let deviceInfo: DeviceInfo
    let simNumbers: [String]
    let signatures: [String]
    let ipAddress: String
    var coordinate: Coordinate
    var isCoordinateFake: Bool
    
    enum CodingKeys: String, CodingKey {
        case platform
        case bundleIdentifier = "application"
        case isJailbroken = "is_rooted"
        case isVpn = "is_vpn"
        case isAppCloned = "is_clone_app"
        case isScreenSharing = "is_screen_sharing"
        case isEmulator = "is_emulator"
        case isDebug = "is_debug"
        case deviceInfo = "device_id"
        case simNumbers = "sim_serial"
        case signatures = "signature"
        case ipAddress = "client_ip"
        case coordinate = "geolocation"
        case isCoordinateFake = "is_gps_spoof"
    }
    
    func toReadableString() -> String {
        return """
        platform: \(platform)
        bundleIdentifier: \(bundleIdentifier)
        isJailbreak: \(isJailbroken)
        isVpn: \(isVpn)
        isAppCloned: \(isAppCloned)
        isScreenSharing: \(isScreenSharing)
        isEmulator: \(isEmulator)
        isDebug: \(isDebug)
        deviceInfo: \(deviceInfo.asReadableString())
        simNumbers: \(simNumbers)
        signatures: \(signatures)
        coordinate: \(coordinate)
        isCoordinateFake: \(isCoordinateFake)
        ipAddress: \(ipAddress)
        """
    }
    
    func toJsonString() -> String? {
        let jsonEncoder = JSONEncoder()
        
        do {
            let jsonData = try jsonEncoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            print(error)
        }
        
        return nil
    }
    
    func fromJsonString(_ json: String) -> MetaData? {
        guard let data = json.data(using: .utf8, allowLossyConversion: false) else { return nil }
        guard let mapper = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject] else { return nil }
        
        return MetaData(
            platform: mapper[CodingKeys.platform.stringValue] as! String,
            bundleIdentifier: mapper[CodingKeys.bundleIdentifier.stringValue] as! String,
            isJailbroken: mapper[CodingKeys.isJailbroken.stringValue] as! Bool,
            isVpn: mapper[CodingKeys.isVpn.stringValue] as! Bool,
            isAppCloned: mapper[CodingKeys.isAppCloned.stringValue] as! Bool,
            isScreenSharing: mapper[CodingKeys.isScreenSharing.stringValue] as! Bool,
            isEmulator: mapper[CodingKeys.isEmulator.stringValue] as! Bool,
            isDebug: mapper[CodingKeys.isDebug.stringValue] as! Bool,
            deviceInfo: DeviceInfo(
                os: mapper[CodingKeys.deviceInfo.stringValue]![DeviceInfo.CodingKeys.os.stringValue] as! String,
                brand: mapper[CodingKeys.deviceInfo.stringValue]![DeviceInfo.CodingKeys.brand.stringValue] as! String,
                type: mapper[CodingKeys.deviceInfo.stringValue]![DeviceInfo.CodingKeys.type.stringValue] as! String,
                cpu: mapper[CodingKeys.deviceInfo.stringValue]![DeviceInfo.CodingKeys.cpu.stringValue] as! String
            ),
            simNumbers: [],
            signatures: [],
            ipAddress: mapper[CodingKeys.ipAddress.stringValue] as! String,
            coordinate: Coordinate(
                lat: mapper[CodingKeys.coordinate.stringValue]!["lat"] as! String,
                lng: mapper[CodingKeys.coordinate.stringValue]!["lng"] as! String
            ),
            isCoordinateFake: mapper[CodingKeys.isCoordinateFake.stringValue] as! Bool
        )
    }
}
