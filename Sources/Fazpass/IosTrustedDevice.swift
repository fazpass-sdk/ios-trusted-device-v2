
import UIKit
import CoreLocation

internal protocol IosTrustedDevice {
    func `init`(publicAssetName: String)
    func generateMeta(resultBlock: @escaping (String, Error?) -> Void)
    func enableSelected(_ selected: SensitiveData...)
}
