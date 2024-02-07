
import Foundation
import CommonCrypto

internal class SecureUtil {
    
    private static _const let SECURE_KEY_LABEL = "FazpassSecureKey"
    
    private static let accessControl = SecAccessControlCreateWithFlags(
        kCFAllocatorDefault,
        kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
        [.biometryCurrentSet],
        nil)
    
    private let generateKeyAttributes: [String: Any] = [
        kSecClass as String: kSecClassKey,
        kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
        kSecAttrKeySizeInBits as String: 2048,
        kSecAttrEffectiveKeySize as String: 2048,
        kSecPrivateKeyAttrs as String: [
            kSecAttrApplicationTag as String: "fazpass.\(Bundle.main.bundleIdentifier ?? "")".data(using: .utf8)!,
            kSecAttrIsPermanent as String: true,
            kSecAttrAccessControl as String: SecureUtil.accessControl as Any
        ]
    ]
    
    private let queryKeyAttributes: [String: Any] = [
        kSecClass as String: kSecClassKey,
        kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
        kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
        kSecAttrKeySizeInBits as String: 2048,
        kSecAttrEffectiveKeySize as String: 2048,
        kSecAttrApplicationTag as String: "fazpass.\(Bundle.main.bundleIdentifier ?? "")".data(using: .utf8)!,
        kSecReturnRef as String: true
    ]
    
    func generateKey() throws {
        // 1. Create Keys Access Control
        guard SecureUtil.accessControl != nil else {
            fatalError("cannot set access control")
        }
        
        // 2. Remove Existing Key
        if SecItemCopyMatching(queryKeyAttributes as CFDictionary, nil) == errSecSuccess {
            let status = SecItemDelete(queryKeyAttributes as CFDictionary)
            guard status == errSecSuccess else {
                let message = SecCopyErrorMessageString(status, nil)
                throw NSError(domain: "Delete existing key failed with status: \(String(describing: message))", code: 100)
            }
        }
        
        // 3. Generate Key Pairs
        var error: Unmanaged<CFError>?
        guard SecKeyCreateRandomKey(generateKeyAttributes as CFDictionary, &error) != nil else {
            throw error!.takeRetainedValue()
        }
    }
    
    func encrypt(_ plainText: String, callback: (_ cipherText: String?, _ status: OSStatus) -> Void) {
        retrievePublicKey { key, status in
            guard let publicKey = key else {
                callback(nil, status)
                return
            }
            
            let plainData = plainText.data(using: .utf8)!

            var error: Unmanaged<CFError>?
            guard let cipherData = SecKeyCreateEncryptedData(publicKey, .rsaEncryptionPKCS1, plainData as CFData, &error) else {
                print("encrypt error: \(error!.takeRetainedValue())")
                callback(nil, errSecInvalidEncoding)
                return
            }

            // encode to base64 string then return
            callback((cipherData as Data).base64EncodedString(), status)
        }
    }
    
    func decrypt(_ cipherText: String, callback: (_ plainText: String?, _ status: OSStatus) -> Void) {
        retrievePrivateKey { key, status in
            guard let privateKey = key else {
                callback(nil, status)
                return
            }
            
            guard let cipherData = Data(base64Encoded: cipherText.data(using: .utf8)!) else {
                callback(nil, errSecParam)
                return
            }
            
            var error: Unmanaged<CFError>?
            guard let plainData = SecKeyCreateDecryptedData(privateKey, .rsaEncryptionPKCS1, cipherData as CFData, &error) else {
                print("decrypt error: \(error!.takeRetainedValue())")
                callback(nil, errSecDecode)
                return
            }
            
            callback(String(data: plainData as Data, encoding: .utf8), status)
        }
    }
    
    private func retrievePrivateKey(callback: (_ key: SecKey?, _ status: OSStatus) -> Void) {
        var item: CFTypeRef?
        let status = SecItemCopyMatching(queryKeyAttributes as CFDictionary, &item)
        callback((item != nil) ? (item as! SecKey) : nil, status)
    }
    
    private func retrievePublicKey(callback: (_ key: SecKey?, _ status: OSStatus) -> Void) {
        retrievePrivateKey { privateKey, status in
            callback((privateKey != nil) ? SecKeyCopyPublicKey(privateKey!) : nil, status)
        }
    }
}
