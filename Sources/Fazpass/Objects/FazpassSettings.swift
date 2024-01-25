
public struct FazpassSettings {
    public let sensitiveData: [SensitiveData]
    public let isBiometricLevelHigh: Bool
    
    private init(_ sensitiveData: [SensitiveData], _ isBiometricLevelHigh: Bool) {
        self.sensitiveData = sensitiveData
        self.isBiometricLevelHigh = isBiometricLevelHigh
    }
    
    static public func fromString(_ settingsString: String) -> FazpassSettings {
        let splitter = settingsString.split(separator: ";", omittingEmptySubsequences: false)
        let sensitiveData = splitter[0].split(separator: ",", omittingEmptySubsequences: false)
            .filter { s in s != "" }
            .map { s in SensitiveData(rawValue: String(s))! }
        let isBiometricLevelHigh = Bool(String(splitter[1])) ?? false
        
        return FazpassSettings(sensitiveData, isBiometricLevelHigh)
    }
    
    public func toString() -> String {
        return "\(sensitiveData.map { s in s.rawValue }.joined(separator: ","));\(isBiometricLevelHigh)"
    }
    
    public class Builder {
        public private(set) var sensitiveDataList: [SensitiveData] = []
        public private(set) var isBiometricLevelHigh: Bool = false
        
        public init() {}
        
        public func enableSelectedSensitiveData(sensitiveData: SensitiveData...) -> Builder {
            for data in sensitiveData {
                if (self.sensitiveDataList.contains(data)) {
                    continue
                } else {
                    self.sensitiveDataList.append(data)
                }
            }
            return self
        }
        
        public func disableSelectedSensitiveData(sensitiveData: SensitiveData...) -> Builder {
            for data in sensitiveData {
                if (self.sensitiveDataList.contains(data)) {
                    self.sensitiveDataList.removeAll { d in
                        return d == data
                    }
                } else {
                    continue
                }
            }
            return self
        }
        
        public func setBiometricLevelToHigh() -> Builder {
            self.isBiometricLevelHigh = true
            return self
        }
        
        public func setBiometricLevelToLow() -> Builder {
            self.isBiometricLevelHigh = false
            return self
        }
        
        public func build() -> FazpassSettings {
            return FazpassSettings(
                sensitiveDataList,
                isBiometricLevelHigh)
        }
    }
}
