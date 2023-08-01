
import UIKit
import CoreLocation

internal protocol IosTrustedDevice {
    func `init`(publicAssetName: String, privateAssetName: String)
    func generateMeta(resultBlock: @escaping (String) -> Void)
    func enableSelected(_ selected: SensitiveData...)
    func getFazpassId(response: String) -> String
}
