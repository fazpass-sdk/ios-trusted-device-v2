
import UIKit

internal class UserDefaultsUtil {
    
    private let defs = UserDefaults.standard
    
    private let KEY_ACCOUNT_INDEX_LIST = "fazpass:account_index_list"
    
    private let KEY_ENCRYPTED_STRING = "fazpass:encrypted_string"
    private let KEY_SETTINGS = "fazpass:settings"
    private func formatKey(_ key: String, _ accountIndex: Int) -> String {
        return "\(key):\(accountIndex)"
    }
    
    private func saveAccountIndex(_ accountIndex: Int) {
        let oldArr = getAccountIndexArray()
        var newArr: [Int] = []
        newArr.append(accountIndex)
        for item in oldArr {
            newArr.append(item)
        }
        defs.set(newArr, forKey: KEY_ACCOUNT_INDEX_LIST)
    }
    
    private func removeAccountIndex(_ accountIndex: Int) {
        var arr = getAccountIndexArray()
        arr.removeAll() { index in accountIndex == index }
        
        defs.set(arr, forKey: KEY_ACCOUNT_INDEX_LIST)
        defs.removeObject(forKey: formatKey(KEY_ENCRYPTED_STRING, accountIndex))
        defs.removeObject(forKey: formatKey(KEY_SETTINGS, accountIndex))
    }
    
    func getAccountIndexArray() -> [Int] {
        return defs.array(forKey: KEY_ACCOUNT_INDEX_LIST) as? [Int] ?? []
    }
    
    func saveEncryptedString(_ accountIndex: Int, _ encryptedString: String) {
        saveAccountIndex(accountIndex)
        let key = formatKey(KEY_ENCRYPTED_STRING, accountIndex)
        defs.set(encryptedString, forKey: key)
    }
    
    func loadEncryptedString(_ accountIndex: Int) -> String? {
        let key = formatKey(KEY_ENCRYPTED_STRING, accountIndex)
        return defs.string(forKey: key)
    }
    
    func removeEncryptedString(_ accountIndex: Int) {
        let key = formatKey(KEY_ENCRYPTED_STRING, accountIndex)
        defs.removeObject(forKey: key)
    }
    
    func saveFazpassSettings(_ accountIndex: Int, _ fazpassSettings: FazpassSettings?) {
        let key = formatKey(KEY_SETTINGS, accountIndex)
        if fazpassSettings != nil {
            saveAccountIndex(accountIndex)
            defs.set(fazpassSettings!.toString(), forKey: key)
        } else {
            removeAccountIndex(accountIndex)
        }
    }
    
    func getFazpassSettings(_ accountIndex: Int) -> FazpassSettings? {
        let key = formatKey(KEY_SETTINGS, accountIndex)
        guard let settingsString = defs.string(forKey: key) else {
            return nil
        }
        return FazpassSettings.fromString(settingsString)
    }
}
