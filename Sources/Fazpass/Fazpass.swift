
#if os(iOS)

import UIKit
import CoreLocation
import NetworkExtension

public class Fazpass: IosTrustedDevice {
    
    private let locationManager: CLLocationManager
    private let locationUtil: LocationUtil
    
    private var publicAssetName = ""
    private var privateAssetName = ""
    private var locationEnabled = false
    private var vpnEnabled = false
    
    public static let shared: Fazpass = Fazpass()
    
    private init() {
        locationManager = CLLocationManager()
        locationUtil = LocationUtil(locationManager)
        locationManager.delegate = locationUtil
    }
    
    public func `init`(publicAssetName: String, privateAssetName: String) {
        self.publicAssetName = publicAssetName
        self.privateAssetName = privateAssetName
    }
    
    public func enableSelected(_ selected: SensitiveData...) {
        for item in selected {
            switch item {
            case .location:
                locationEnabled = true
            case .vpn:
                vpnEnabled = true
            }
        }
    }
    
    public func generateMeta(resultBlock: @escaping (String) -> Void) {
        let app = UIApplication.shared
        
        Task {
            let platform = "ios"
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
            let isJailbreak = JailbreakUtil(app).isJailbroken()
            let deviceInfo = DeviceInfoUtil().deviceInfo
            let isScreenSharing = await app.openSessions.count > 1
            let isAppCloned = false
            
            let ipAddress = IPAddressUtil.get()
            
            var isEmulator: Bool
            #if targetEnvironment(simulator)
            isEmulator = true
            #else
            isEmulator = false
            #endif
            
            var isDebug: Bool
            #if DEBUG
            isDebug = true
            #else
            isDebug = false
            #endif
            
            let simNumbers: [String] = []
            let signatures: [String] = []
            
            let isVpnOn: Bool
            if vpnEnabled {
                isVpnOn = await withCheckedContinuation { continuation in
                    let vpnManager = NEVPNManager.shared()
                    vpnManager.loadFromPreferences { error in
                        guard error == nil else {
                            continuation.resume(returning: false)
                            return
                        }
                        continuation.resume(returning: vpnManager.connection.status == .connected)
                    }
                }
            } else {
                isVpnOn = false
            }
            
            var metaData = MetaData(
                platform: platform,
                bundleIdentifier: bundleIdentifier,
                isJailbroken: isJailbreak,
                isVpn: isVpnOn,
                isAppCloned: isAppCloned,
                isScreenSharing: isScreenSharing,
                isEmulator: isEmulator,
                isDebug: isDebug,
                deviceInfo: deviceInfo,
                simNumbers: simNumbers,
                signatures: signatures,
                ipAddress: ipAddress,
                coordinate: Coordinate(lat: String(0.0), lng: String(0.0)),
                isCoordinateFake: false
            )
            
            if locationEnabled {
                locationUtil.getLocation { [self] location, isSuspectedMock in
                    if let loc = location {
                        metaData.coordinate = Coordinate(lat: String(loc.coordinate.latitude), lng: String(loc.coordinate.longitude))
                        metaData.isCoordinateFake = isSuspectedMock
                    }
                    
                    resultBlock(self.encryptMetaData(metaData))
                }
            } else {
                resultBlock(encryptMetaData(metaData))
            }
        }
    }
    
    public func getFazpassId(response: String) -> String {
        guard let data = response.data(using: .utf8, allowLossyConversion: false) else { return "" }
        guard let mapper = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject] else { return "" }
        
        guard let meta = mapper["data"]?["meta"] as? String else { return "" }
        
        let jsonMeta = decryptMetaData(meta)
        if (!jsonMeta.isEmpty) {
            guard let data2 = jsonMeta.data(using: .utf8, allowLossyConversion: false) else { return "" }
            guard let mapper2 = try? JSONSerialization.jsonObject(with: data2, options: .mutableContainers) as? [String:AnyObject] else { return "" }
            
            return mapper2["fazpass_id"] as? String ?? ""
        }
        
        return ""
    }
    
    private func encryptMetaData(_ metaData: MetaData) -> String {
        guard let publicKeyFile = NSDataAsset(name: publicAssetName) else {
            print("Key not found!")
            return ""
        }
        
        guard let jsonMetaData = metaData.toJsonString() else {
            print("Error encoding meta data to json")
            return ""
        }
        
        guard var key = String(data: publicKeyFile.data, encoding: String.Encoding.utf8) else {
            print("Failed to convert public key file to string")
            return ""
        }
        
        key = key.replacingOccurrences(of: "-----BEGIN RSA PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END RSA PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
        
        guard let base64Key = Data(base64Encoded: key) else {
            print("Failed to encode key to base64")
            return ""
        }
        
        let options: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 2048,
            kSecReturnPersistentRef as String: true
        ]

        var error: Unmanaged<CFError>?
        guard let publicKey = SecKeyCreateWithData(base64Key as CFData,
                                                options as CFDictionary,
                                                &error) else {
            print(String(describing: error))
            return ""
        }
        
        // Encrypt json metadata with public key
        var bufferSize = SecKeyGetBlockSize(publicKey)
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        let plainTextData = jsonMetaData.data(using: .utf8)!

        let status = plainTextData.withUnsafeBytes { plainTextBytes in
            guard let plainTextBaseAddress = plainTextBytes.baseAddress else {
                return errSecIO
            }
            
            return SecKeyEncrypt(publicKey,
                                 SecPadding.PKCS1,
                                 plainTextBaseAddress.assumingMemoryBound(to: UInt8.self),
                                 plainTextData.count,
                                 &buffer,
                                 &bufferSize)
        }

        guard status == errSecSuccess else {
            print("Encryption failed")
            return ""
        }

        // encode to base64 string then return
        return Data(bytes: buffer, count: bufferSize).base64EncodedString()
    }
    
    private func decryptMetaData(_ encryptedMetaData: String) -> String {
        guard let data = Data(base64Encoded: encryptedMetaData) else {
            print("Failed to encode encryted meta data!")
            return ""
        }
        
        guard let privateKeyFile = NSDataAsset(name: privateAssetName) else {
            print("Key not found!")
            return ""
        }
        
        guard var key = String(data: privateKeyFile.data, encoding: String.Encoding.utf8) else {
            print("Failed to convert private key file to string")
            return ""
        }
        
        key = key.replacingOccurrences(of: "-----BEGIN RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
        
        guard let base64Key = Data(base64Encoded: key) else {
            print("Failed to encode key to base64")
            return ""
        }
        
        let options: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: 2048
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateWithData(base64Key as CFData,
                                                options as CFDictionary,
                                                &error) else {
            print(String(describing: error))
            return ""
        }
        
        var keySize = SecKeyGetBlockSize(privateKey)
        var keyBuffer = [UInt8](repeating: 0, count: keySize)
        
        // Decrypted data will be written to keyBuffer
        guard SecKeyDecrypt(privateKey, .PKCS1, [UInt8](data), data.count, &keyBuffer, &keySize) == errSecSuccess else {
            return ""
        }
            
        return String(bytes: keyBuffer, encoding: .utf8)?.replacingOccurrences(of: "\u{0000}", with: "", options: NSString.CompareOptions.literal, range: nil).trimmingCharacters(in: .whitespaces) ?? ""
    }
}
#else
#error("This package doesn't support platforms other than ios")
#endif
