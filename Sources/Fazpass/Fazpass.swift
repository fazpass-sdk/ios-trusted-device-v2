
#if os(iOS)

import UIKit
import CoreLocation
import NetworkExtension
import LocalAuthentication

public class Fazpass: IosTrustedDevice {
    
    private let locationManager: CLLocationManager
    private let locationUtil: LocationUtil
    
    private var publicAssetName = ""
    private var locationEnabled = false
    private var vpnEnabled = false
    
    public static let shared: Fazpass = Fazpass()
    
    private init() {
        locationManager = CLLocationManager()
        locationUtil = LocationUtil(locationManager)
        locationManager.delegate = locationUtil
    }
    
    public func `init`(publicAssetName: String) {
        self.publicAssetName = publicAssetName
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
    
    public func generateMeta(resultBlock: @escaping (String, Error?) -> Void) {
        openBiometric { error in
            guard error == nil else {
                resultBlock("", error)
                return
            }
            
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
                if self.vpnEnabled {
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
                
                if self.locationEnabled {
                    self.locationUtil.getLocation { location, isSuspectedMock in
                        if let loc = location {
                            metaData.coordinate = Coordinate(lat: String(loc.coordinate.latitude), lng: String(loc.coordinate.longitude))
                            metaData.isCoordinateFake = isSuspectedMock
                        }
                        
                        var encryptedMeta = ""
                        var e: Error?
                        do {
                            encryptedMeta = try self.encryptMetaData(metaData)
                        } catch {
                            e = error
                        }
                        resultBlock(encryptedMeta, e)
                    }
                } else {
                    var encryptedMeta = ""
                    var e: Error?
                    do {
                        encryptedMeta = try self.encryptMetaData(metaData)
                    } catch {
                        e = error
                    }
                    resultBlock(encryptedMeta, e)
                }
            }
        }
    }
    
    private func openBiometric(_ resultBlock: @escaping (Error?) -> Void) {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        var error: NSError?
        
        // Check if the device supports biometric authentication
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Biometric Required"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        // Successful authentication
                        resultBlock(nil)
                    } else {
                        // Error handling
                        guard let authError = authenticationError else {
                            return
                        }
                        
                        switch authError {
                        case LAError.userFallback:
                            resultBlock(authError)
                        default:
                            return
                        }
                    }
                }
            }
        } else {
            // Device does not support biometric authentication
            resultBlock(error)
        }
//        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &nsError) else {
//            resultBlock(nsError)
//            return
//        }
//        Task {
//            do {
//                try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Log in to your account")
//                resultBlock(nil)
//            } catch let error {
//                resultBlock(error)
//            }
//        }
    }
    
    private func encryptMetaData(_ metaData: MetaData) throws -> String {
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
}
#else
#error("This package doesn't support platforms other than ios")
#endif
