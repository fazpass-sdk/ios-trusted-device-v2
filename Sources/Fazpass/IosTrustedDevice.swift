
import UIKit
import CoreLocation

internal protocol IosTrustedDevice {
    func `init`(publicAssetName: String)
    func generateMeta(resultBlock: @escaping (String, FazpassError?) -> Void)
    func enableSelected(_ selected: SensitiveData...)
}
