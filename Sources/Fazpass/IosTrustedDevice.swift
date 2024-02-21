
import UIKit
import CoreLocation

internal protocol IosTrustedDevice {
    /// Initializes everything.
    ///
    /// Required to be called once at the start of application, otherwise unexpected error may occur.
    /// Call this method inside your app delegate `didFinishLaunchingWithOptions`.
    /// Reference the public key in your XCode project assets as data set.
    ///
    /// Parameters:
    ///  - publicAssetName: Your public key asset name which you reference in your assets (Example: "FazpassPublicKey").
    ///  - application: `application` parameter from your app delegate `didFinishLaunchingWithOptions`.
    ///  - fcmAppId: Your FCM App Id that you get from fazpass after submitting your apple push notifications key.
    func `init`(publicAssetName: String, application: UIApplication, fcmAppId: String)
    
    /// Collects specific data according to settings and generate meta from it as Base64 string.
    ///
    /// You can use this meta to hit Fazpass API endpoint. Calling this method will automatically launch
    /// local authentication (biometric / password). Any rules that have been set in method `Fazpass.setSettings`
    /// will be applied according to the `accountIndex` parameter.
    ///
    /// - Parameters:
    ///  - accountIndex: Apply settings for this account index if settings have been set. Default to -1.
    ///  - resultBlock: Will be invoked when meta is ready as Base64 string. If an error occured, error won't be nil and meta will be
    ///  empty string.
    func generateMeta(accountIndex: Int, resultBlock: @escaping (String, FazpassError?) -> Void)
    
    /// Generates new secret key for high level biometric settings.
    ///
    /// Before generating meta with "High Level Biometric" settings, You have to generate secret key first by
    /// calling this method. This secret key will be invalidated when there is a new biometric enrolled or all
    /// biometric is cleared, which makes your active fazpass id to get revoked when you hit Fazpass Check API
    /// using meta generated with "High Level Biometric" settings. When secret key has been invalidated, you have
    /// to call this method to generate new secret key and enroll your device with Fazpass Enroll API to make
    /// your device trusted again.
    ///
    /// IMPORTANT: Before calling this method, make sure user has set a passcode and enrolled at least one biometry in their device.
    ///
    /// - Throws: If generate new secret key is failed. Report this exception as a bug when that happens.
    func generateNewSecretKey() throws
    
    /// Sets rules for data collection in `Fazpass.generateMeta` method.
    ///
    /// Sets which sensitive information is collected in `Fazpass.generateMeta` method
    /// and applies them according to `accountIndex` parameter. Settings will be stored in UserDefaults, so it will
    /// not persist when application data is cleared / application is uninstalled. To delete stored settings, pass nil on `settings` parameter.
    ///
    ///  - Parameters:
    ///   - accountIndex: Which account index to save settings into.
    ///   - settings: `FazpassSettings` object that will be saved. If nil, the currently saved settings will be deleted.
    func setSettings(accountIndex: Int, settings: FazpassSettings?)
    
    /// Retrieves the rules that has been set in `Fazpass.setSettings` method.
    ///
    /// - Parameter accountIndex: Which account index to get settings from.
    /// - returns: stored `FazpassSettings` object based on the `accountIndex` parameter. Otherwise nil if
    /// there is no stored settings for this `accountIndex`.
    func getSettings(accountIndex: Int) -> FazpassSettings?
    
    func registerDeviceToken(deviceToken: Data)
    
    /// Retrieves the stream instance of cross device request.
    ///
    /// Before you listen to cross device login request stream, make sure these requirements
    /// have been met:
    /// - Device has been enrolled.
    /// - Device is currently trusted (See Fazpass documentation for the definition of "trusted").
    /// - Application is in "Logged In" state.
    ///
    /// - returns: `CrossDeviceRequestStream` instance.
    func getCrossDeviceRequestStreamInstance() -> CrossDeviceRequestStream
    
    /// Retrieves a `CrossDeviceRequest` object obtained from notification.
    ///
    /// Call this method inside your app delegate `didReceiveRemoteNotification`.
    /// If user launched the application from notification, this method will return data
    /// contained in that notification. Will return nil if user launched the application normally.
    ///
    /// - Parameter userInfo: `userInfo` parameter from your app delegate `didReceiveRemoteNotification`.
    /// - returns: `CrossDeviceRequest` object if userInfo contains data from cross device login. Otherwise nil. If you passed nil
    /// in `userInfo` parameter, will return the previously returned `CrossDeviceRequest` object from this method.
    func getCrossDeviceRequestFromNotification(userInfo: [AnyHashable: Any]?) -> CrossDeviceRequest?
}
