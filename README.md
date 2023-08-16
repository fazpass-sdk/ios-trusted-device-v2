# ios-trusted-device-v2
## Usage
```swift
Fazpass.shared.generateMeta { meta in 
    print(meta)
}
```
## Initializing Fazpass in your app
1. Put your fazpass public key which you get from us in your assets as Data Set
2. Call 
```swift Fazpass.shared.`init`(publicAssetName: "FazpassPublicKey")```
 and fill the publicAssetName parameter with your public key asset name
3. Declare NSFaceIDUsageDescription in your Info.plist file to use biometric
### Enable Location Usage
1. Declare NSLocationWhenInUseUsageDescription in your Info.plist file
2. Call 
```swift Fazpass.shared.enableSelected([SensitiveData.location])```
### Enable Vpn Usage
1. Follow Apple guidelines on how to enable NEVpnManager
2. When you have the permit to do so, Call 
```swift Fazpass.shared.enableSelected([SensitiveData.vpn])```
