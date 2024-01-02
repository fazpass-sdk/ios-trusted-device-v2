
import Foundation

internal struct MetaData: Codable {
    let platform: String
    let isJailbroken: Bool
    let isEmulator: Bool
    var isCoordinateFake: Bool
    let signatures: [String]
    let isVpn: Bool
    let isAppCloned: Bool
    let isScreenSharing: Bool
    let isDebug: Bool
    let bundleIdentifier: String
    let deviceInfo: DeviceInfo
    let simNumbers: [String]
    let simOperators: [String]
    var coordinate: Coordinate
    let ipAddress: String
    let fcmToken: String
    var biometricInfo: BiometricInfo
    
    enum CodingKeys: String, CodingKey {
        case platform
        case isJailbroken = "is_rooted"
        case isEmulator = "is_emulator"
        case isCoordinateFake = "is_gps_spoof"
        case signatures = "signature"
        case isVpn = "is_vpn"
        case isAppCloned = "is_clone_app"
        case isScreenSharing = "is_screen_sharing"
        case isDebug = "is_debug"
        case bundleIdentifier = "application"
        case deviceInfo = "device_id"
        case simNumbers = "sim_serial"
        case simOperators = "sim_operator"
        case coordinate = "geolocation"
        case ipAddress = "client_ip"
        case fcmToken = "fcm_token"
        case biometricInfo = "biometric"
    }
    
    func toReadableString() -> String {
        return """
        platform
        isJailbroken: \(isJailbroken)
        isEmulator: \(isEmulator)
        isCoordinateFake: \(isCoordinateFake)
        signatures: \(signatures)
        isVpn: \(isVpn)
        isAppCloned: \(isAppCloned)
        isScreenSharing: \(isScreenSharing)
        isDebug: \(isDebug)
        bundleIdentifier: \(bundleIdentifier)
        deviceInfo: \(deviceInfo)
        simNumbers: \(simNumbers)
        simOperators: \(simOperators)
        coordinate: \(coordinate)
        ipAddress: \(ipAddress)
        fcmToken: \(fcmToken)
        biometricInfo: \(biometricInfo)
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
            isJailbroken: mapper[CodingKeys.isJailbroken.stringValue] as! Bool,
            isEmulator: mapper[CodingKeys.isEmulator.stringValue] as! Bool,
            isCoordinateFake: mapper[CodingKeys.isCoordinateFake.stringValue] as! Bool,
            signatures: [],
            isVpn: mapper[CodingKeys.isVpn.stringValue] as! Bool,
            isAppCloned: mapper[CodingKeys.isAppCloned.stringValue] as! Bool,
            isScreenSharing: mapper[CodingKeys.isScreenSharing.stringValue] as! Bool,
            isDebug: mapper[CodingKeys.isDebug.stringValue] as! Bool,
            bundleIdentifier: mapper[CodingKeys.bundleIdentifier.stringValue] as! String,
            deviceInfo: DeviceInfo(
                os: mapper[CodingKeys.deviceInfo.stringValue]![DeviceInfo.CodingKeys.os.stringValue] as! String,
                brand: mapper[CodingKeys.deviceInfo.stringValue]![DeviceInfo.CodingKeys.brand.stringValue] as! String,
                type: mapper[CodingKeys.deviceInfo.stringValue]![DeviceInfo.CodingKeys.type.stringValue] as! String,
                cpu: mapper[CodingKeys.deviceInfo.stringValue]![DeviceInfo.CodingKeys.cpu.stringValue] as! String
            ),
            simNumbers: [],
            simOperators: [],
            coordinate: Coordinate(
                lat: mapper[CodingKeys.coordinate.stringValue]!["lat"] as! String,
                lng: mapper[CodingKeys.coordinate.stringValue]!["lng"] as! String
            ),
            ipAddress: mapper[CodingKeys.ipAddress.stringValue] as! String,
            fcmToken: mapper[CodingKeys.fcmToken.stringValue] as! String,
            biometricInfo: BiometricInfo(
                level: mapper[CodingKeys.biometricInfo.stringValue]![BiometricInfo.CodingKeys.level.stringValue] as! String,
                isChanged: mapper[CodingKeys.biometricInfo.stringValue]![BiometricInfo.CodingKeys.isChanged.stringValue] as! Bool
            )
        )
    }
}
