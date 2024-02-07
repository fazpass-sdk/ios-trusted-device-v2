
import Foundation
import CommonCrypto

internal class SecureUtil {
    
    private static _const let SECURE_KEY_LABEL = "FazpassSecureKey"
    
    private static let accessControl = SecAccessControlCreateWithFlags(
        kCFAllocatorDefault,
        kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
        [.biometryCurrentSet, .and, .biometryAny],
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
    
    func encrypt(_ plainText: String) -> String? {
        guard let publicKey = getPublicKey() else {
            return nil
        }
        
        let plainData = plainText.data(using: .utf8)!

        var error: Unmanaged<CFError>?
        let cipherData = SecKeyCreateEncryptedData(publicKey, .rsaEncryptionPKCS1, plainData as CFData, &error)
        guard error == nil && cipherData != nil else {
            print("encrypt error: \(error!.takeRetainedValue())")
            return nil
        }

        // encode to base64 string then return
        return (cipherData! as Data).base64EncodedString()
    }
    
    func decrypt(_ cipherText: String) -> String? {
        guard let privateKey = getPrivateKey() else {
            return nil
        }
        
        guard let cipherData = Data(base64Encoded: cipherText.data(using: .utf8)!) else {
            return nil
        }

        var error: Unmanaged<CFError>?
        let plainData = SecKeyCreateDecryptedData(privateKey, .rsaEncryptionPKCS1, cipherData as CFData, &error)
        guard error == nil && plainData != nil else {
            print("decrypt error: \(error!.takeRetainedValue())")
            return nil
        }

        // decode to original string then return
        return String(data: plainData! as Data, encoding: .utf8)
    }
    
    private func getPrivateKey() -> SecKey? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching(queryKeyAttributes as CFDictionary, &item)
        guard status == errSecSuccess else {
            let message = SecCopyErrorMessageString(status, nil)
            print("Failed to get private key with status: \(String(describing: message))")
            return nil
        }
        
        return (item as! SecKey)
    }
    
    private func getPublicKey() -> SecKey? {
        guard let privateKey = getPrivateKey() else {
            return nil
        }
        
        return SecKeyCopyPublicKey(privateKey)
    }
}
