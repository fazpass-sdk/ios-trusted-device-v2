
import UIKit
import CoreLocation

internal protocol IosTrustedDevice {
    func `init`(publicAssetName: String, application: UIApplication, fcmAppId: String)
    func registerDeviceToken(deviceToken: Data)
    func generateMeta(accountIndex: Int, resultBlock: @escaping (String, FazpassError?) -> Void)
    func generateSecretKeyForHighLevelBiometric() throws
    func setFazpassSettingsForAccountIndex(accountIndex: Int, settings: FazpassSettings?)
    func getFazpassSettingsForAccountIndex(accountIndex: Int) -> FazpassSettings?
    func getCrossDeviceRequestStreamInstance() -> CrossDeviceRequestStream
    func getCrossDeviceRequestFromNotification(userInfo: [AnyHashable: Any]) -> CrossDeviceRequest?
    func getCrossDeviceRequestFromNotification() -> CrossDeviceRequest?
}
