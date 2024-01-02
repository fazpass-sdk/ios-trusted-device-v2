
import UIKit
import CoreLocation
import NetworkExtension
import LocalAuthentication

public class Fazpass: NSObject, IosTrustedDevice {
    
    private var isInitialized: Bool = false
    private let locationManager: CLLocationManager
    private let locationUtil: LocationUtil
    private let notificationUtil: NotificationUtil
    
    private var publicAssetName = ""
    private var settings: [Int: FazpassSettings] = [:]
    private let crossDeviceRequestStream = CrossDeviceRequestStream()
    private var lastCrossDeviceRequestFromNotification: CrossDeviceRequest? = nil
    
    public static let shared: Fazpass = Fazpass()
    
    private override init() {
        locationManager = CLLocationManager()
        locationUtil = LocationUtil(locationManager)
        locationManager.delegate = locationUtil
        notificationUtil = NotificationUtil(crossDeviceRequestStream: crossDeviceRequestStream)
    }
    
    public func `init`(publicAssetName: String, application: UIApplication, fcmAppId: String) {
        self.publicAssetName = publicAssetName
        notificationUtil.configure(application, fcmAppId)
        
        // load settings
        let defs = UserDefaultsUtil()
        for accountIndex in defs.getAccountIndexArray() {
            let setting = defs.getFazpassSettings(accountIndex)
            if setting != nil {
                settings[accountIndex] = setting
            }
        }
        
        isInitialized = true
    }
    
    public func registerDeviceToken(deviceToken: Data) {
        notificationUtil.registerDeviceToken(deviceToken)
    }
    
    public func generateMeta(accountIndex: Int = -1, resultBlock: @escaping (String, FazpassError?) -> Void) {
        if !isInitialized {
            resultBlock("", FazpassError.uninitialized)
            return
        }
        
        // declare settings for this generated meta
        var locationEnabled = false
        var vpnEnabled = false
        var isBiometricLevelHigh = false
        
        // load settings that has been set for this account index
        let setting = settings[accountIndex]
        if setting != nil {
            locationEnabled = setting!.sensitiveData.contains(SensitiveData.location)
            vpnEnabled = setting!.sensitiveData.contains(SensitiveData.vpn)
            isBiometricLevelHigh = setting!.isBiometricLevelHigh
        }
        
        openBiometric(accountIndex, isBiometricLevelHigh) { hasChanged, error in
            guard error == nil else {
                resultBlock("", error)
                return
            }
            
            let app = UIApplication.shared
            
            Task { [locationEnabled, vpnEnabled, isBiometricLevelHigh] in
                let platform = "ios"
                let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
                let isJailbreak = JailbreakUtil(app).isJailbroken()
                let deviceInfo = DeviceInfoUtil().deviceInfo
                let isScreenSharing = await app.openSessions.count > 1
                let isAppCloned = false
                
                let ipAddress = IPAddressUtil.get()
                let fcmToken = await self.notificationUtil.getFcmToken()
                
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
                let simOperators: [String] = []
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
                    isJailbroken: isJailbreak,
                    isEmulator: isEmulator,
                    isCoordinateFake: false,
                    signatures: signatures,
                    isVpn: isVpnOn,
                    isAppCloned: isAppCloned,
                    isScreenSharing: isScreenSharing,
                    isDebug: isDebug,
                    bundleIdentifier: bundleIdentifier,
                    deviceInfo: deviceInfo,
                    simNumbers: simNumbers,
                    simOperators: simOperators,
                    coordinate: Coordinate(lat: String(0.0), lng: String(0.0)),
                    ipAddress: ipAddress,
                    fcmToken: fcmToken,
                    biometricInfo: BiometricInfo(level: "LOW", isChanged: hasChanged)
                )
                
                if isBiometricLevelHigh {
                    metaData.biometricInfo = BiometricInfo(level: "HIGH", isChanged: hasChanged)
                }
                
                if locationEnabled {
                    self.locationUtil.getLocation { location, isSuspectedMock in
                        if let loc = location {
                            metaData.coordinate = Coordinate(lat: String(loc.coordinate.latitude), lng: String(loc.coordinate.longitude))
                            metaData.isCoordinateFake = isSuspectedMock
                        }
                        
                        var encryptedMeta = ""
                        var e: FazpassError?
                        do {
                            encryptedMeta = try self.encryptMetaData(metaData)
                        } catch is FazpassError {
                            e = error
                        } catch {
                            e = FazpassError.encryptionError(message: "Failed to encrypt")
                        }
                        
                        resultBlock(encryptedMeta, e)
                    }
                } else {
                    var encryptedMeta = ""
                    var e: FazpassError?
                    do {
                        encryptedMeta = try self.encryptMetaData(metaData)
                    } catch is FazpassError {
                        e = error
                    } catch {
                        e = FazpassError.encryptionError(message: "Failed to encrypt")
                    }
                    
                    resultBlock(encryptedMeta, e)
                }
            }
        }
    }
    
    public func generateSecretKeyForHighLevelBiometric() throws {
        let defs = UserDefaultsUtil()
        let accountIndexArr = defs.getAccountIndexArray()
        for i in accountIndexArr {
            defs.removeEncryptedString(i)
        }
        
        // generate new key
        try SecureUtil().generateKey()
    }
    
    public func setFazpassSettingsForAccountIndex(accountIndex: Int, settings: FazpassSettings?) {
        if settings != nil {
            self.settings[accountIndex] = settings
        } else {
            self.settings.removeValue(forKey: accountIndex)
        }
        
        UserDefaultsUtil().saveFazpassSettings(accountIndex, settings)
    }
    
    public func getFazpassSettingsForAccountIndex(accountIndex: Int) -> FazpassSettings? {
        return self.settings[accountIndex]
    }
    
    public func getCrossDeviceRequestStreamInstance() -> CrossDeviceRequestStream {
        return crossDeviceRequestStream
    }
    
    public func getCrossDeviceRequestFromNotification(userInfo: [AnyHashable: Any]) -> CrossDeviceRequest? {
        var request: CrossDeviceRequest? = nil
        do {
            request = try CrossDeviceRequest(data: userInfo)
        } catch {}
        lastCrossDeviceRequestFromNotification = request
        return request
    }
    
    func getCrossDeviceRequestFromNotification() -> CrossDeviceRequest? {
        return lastCrossDeviceRequestFromNotification
    }
    
    private func openBiometric(_ accountIndex: Int, _ isBiometricLevelHigh: Bool, _ resultBlock: @escaping (_ hasChanged: Bool, FazpassError?) -> Void) {
        var policy: LAPolicy
        if isBiometricLevelHigh {
            policy = .deviceOwnerAuthenticationWithBiometrics
        } else {
            policy = .deviceOwnerAuthentication
        }
        
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = ""
        
        // Check if the device supports biometric authentication
        var error: NSError?
        guard context.canEvaluatePolicy(policy, error: &error) else {
            switch LAError.Code(rawValue: error!.code)! {
            case .passcodeNotSet, .biometryNotEnrolled:
                resultBlock(false, FazpassError.biometricNoneEnrolled)
            case .notInteractive:
                resultBlock(false, FazpassError.biometricNotInteractive)
            default:
                resultBlock(false, FazpassError.biometricNotAvailable(message: error!.localizedDescription))
            }
            return
        }
        
        let reason = "Biometric Required"
        context.evaluatePolicy(policy, localizedReason: reason) { success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    
                    // if biometric level is low, finish local authentication immediately
                    if isBiometricLevelHigh == false {
                        resultBlock(false, nil)
                        return
                    }
                    
                    let defs = UserDefaultsUtil()
                    let plainText = DeviceInfoUtil().deviceInfo.asReadableString()
                    let cipherText = defs.loadEncryptedString(accountIndex)
                    // if cipher text is nil, do encryption
                    if cipherText == nil {
                        let newCipherText = SecureUtil().encrypt(plainText)
                        // if encryption failed, new cipher text will return nil. then passcode has changed
                        if newCipherText == nil {
                            resultBlock(true, nil)
                        }
                        // otherwise safe new cipher text to user defaults
                        else {
                            defs.saveEncryptedString(accountIndex, newCipherText!)
                            resultBlock(false, nil)
                        }
                    }
                    // otherwise do decryption
                    else {
                        let decryptedString = SecureUtil().decrypt(cipherText!)
                        // if decryption failed, decryptedString will return null. then passcode has been changed
                        // else if decryptedString isn't the same as original string, then passcode has been changed
                        if decryptedString == nil || decryptedString != plainText {
                            resultBlock(true, nil)
                        }
                        else {
                            resultBlock(false, nil)
                        }
                    }
                } else {
                    // Error handling
                    guard let authError = authenticationError else {
                        return
                    }
                    
                    switch authError {
                    case LAError.userCancel, LAError.appCancel, LAError.systemCancel, LAError.biometryLockout:
                        resultBlock(false, FazpassError.biometricAuthFailed)
                    case LAError.userFallback, LAError.authenticationFailed:
                        return
                    default:
                        resultBlock(false, FazpassError.biometricNotAvailable(message: authError.localizedDescription))
                    }
                }
            }
        }
    }
    
    private func encryptMetaData(_ metaData: MetaData) throws -> String {
        guard let publicKeyFile = NSDataAsset(name: publicAssetName) else {
            throw FazpassError.publicKeyNotExist
        }
        
        guard let jsonMetaData = metaData.toJsonString() else {
            throw FazpassError.encryptionError(message: "Error encoding meta data to json")
        }
        print(jsonMetaData)
        
        guard var key = String(data: publicKeyFile.data, encoding: String.Encoding.utf8) else {
            throw FazpassError.encryptionError(message: "Failed to convert public key file to string")
        }
        
        key = key.replacingOccurrences(of: "-----BEGIN RSA PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END RSA PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
        
        guard let base64Key = Data(base64Encoded: key) else {
            throw FazpassError.encryptionError(message: "Failed to encode key to base64")
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
            throw FazpassError.encryptionError(message: error!.takeRetainedValue().localizedDescription)
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
            throw FazpassError.encryptionError(message: "Encryption failed with status: \(status.description)")
        }

        // encode to base64 string then return
        return Data(bytes: buffer, count: bufferSize).base64EncodedString()
    }
}
