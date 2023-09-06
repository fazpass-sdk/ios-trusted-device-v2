# ios-trusted-device-v2

This is the Official ios package for Fazpass Trusted Device V2.
For android counterpart, you can find it here: https://github.com/fazpass-sdk/android-trusted-device-v2 <br>
Visit [official website](https://fazpass.com) for more information about the product and see documentation at [online documentation](https://doc.fazpass.com) for more technical details.

## Minimum OS

iOS 13.0

## Installation

You can add this package into your project by either swift package or podspec.

### Using swift package

1. Open Xcode, click File > Add Packages...
2. Enter this package URL: https://github.com/fazpass-sdk/ios-trusted-device-v2.git
3. Click Add Package

### Using podspec

In your podspec file, add the dependency:
```podspec
Pod::Spec.new do |s|
    # Rest of podspec file...
    s.dependency 'ios-trusted-device-v2'
end
```

## Getting Started

Before using our product, make sure to contact us first to get keypair of public key and private key.
after you have each of them, reference the public key into Assets.

1. In your Xcode project, open Assets.
2. Add new asset as Data Set.
3. Reference your public key into this asset.
4. Name your asset.

This package main purpose is to generate meta which you can use to communicate with Fazpass rest API. But
before calling generate meta method, you have to initialize it first by calling this method:
```swift
Fazpass.shared.`init`(this, "YOUR_PUBLIC_KEY_ASSET_NAME")
```

## Usage

Call `generateMeta(resultBlock: @escaping (String, FazpassError?) -> Void)` method to generate meta. This method
collects specific information and generates meta data as Base64 string.
You can use this meta to hit Fazpass API endpoint. **Will launch biometric authentication before
generating meta**. Meta will be empty string if error is present.
```swift
Fazpass.shared.generateMeta { meta, error in 
    guard let error = error else {
        print(meta)
    }
    
    switch (error) {
    case .biometricNoneEnrolled:
        // code...
    case .biometricAuthFailed:
        // code...
    case .biometricNotAvailable:
        // code...
    case .biometricNotInteractive:
        // code...
    case .encryptionError(let message):
        // code...
    case .publicKeyNotExist:
        // code...
    case .uninitialized:
        // code...
    case .unknownError(let error):
        // code...
    }
}
```

## Errors

* biometricNoneEnrolled<br>
Produced when device can't start biometric authentication because there is no biometry or device passcode enrolled.
* biometricAuthFailed<br>
Produced when biometric authentication is finished with an error (e.g. User cancelled biometric auth, etc).
* biometricNotAvailable<br>
Produced when device can't start biometric authentication because biometry (Touch ID or Face ID) is unavailable.
* biometricNotInteractive<br>
Produced when device can't start biometric authentication because displaying the required authentication user interface is forbidden. To fix this, you have to permit the display of the authentication UI by setting the interactionNotAllowed property to false.
* encryptionError<br>
Produced when encryption went wrong because you used the wrong public key. Gives you string message of what went wrong.
* publicKeyNotExist<br>
Produced when public key with the name registered in init method doesn't exist as an asset.
* uninitialized<br>
Produced when fazpass init method hasn't been called once.
* unknownError<br>
Produced when an unknown error has been occured when trying to generate meta. Gives you an error object of what went wrong. Less likely to happen if you followed the procedure correctly.

## Data Collection

Data collected and stored in generated meta. Based on data sensitivity, data type is divided into two: General data and Sensitive data.
General data is always collected while Sensitive data requires more complicated procedures to enable it.

To enable Sensitive data collection, after calling fazpass init method, you need to call `enableSelected(sensitiveData: SensitiveData)` method and
specifies which sensitive data you want to collect.
```swift
Fazpass.shared.enableSelected(
    SensitiveData.location,
    SensitiveData.vpn
)
```
After enabling specified Sensitive data, you have to follow the procedure for each of them as described in their own segment down below.

### General data collected

* Your device platform name (Value will always be "ios").
* Your app bundle identifier.
* Your app debug status.
* Your device jailbroken status.
* Your device emulator/simulator status.
* Your device mirroring or projecting status.
* Your device information (iOS version, phone model, phone type, phone cpu).
* Your network IP Address.

### Sensitive data collected

#### Your device location (X and Y coordinate, mock location status)

To collect location data, declare NSLocationWhenInUseUsageDescription in your Info.plist file.
When it's enabled, user will be automatically asked to permit the LocationWhenInUse permission when fazpass generate meta method is called.
Location data is collected if the user permit it, otherwise it won't be collected and no error will be produced.

#### Your device vpn status

To collect vpn status data, you have to add Network Extensions Entitlement to your project.
To add this entitlement to an iOS app or a Mac App Store app, enable the Network Extensions capability in Xcode.
To add this entitlement to a macOS app distributed outside of the Mac App Store, perform the following steps:
1. In the Certificates, Identifiers and Profiles section of the developer site, enable the Network Extension capability for your Developer ID–signed app. Generate a new provisioning profile and download it.
2. On your Mac, drag the downloaded provisioning profile to Xcode to install it.
3. In your Xcode project, enable manual signing and select the provisioning profile downloaded earlier and its associated certificate.
4. Update the project’s entitlements.plist to include the com.apple.developer.networking.networkextension key and the values of the entitlement.

[Apple documentation of network extensions entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_networking_networkextension)
