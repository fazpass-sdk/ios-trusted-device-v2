
import UIKit
import CoreLocation

internal protocol IosTrustedDevice {
    func `init`(assetName: String)
    func generateMeta(resultBlock: @escaping (String) -> Void) async
    func enableSelected(_ selected: SensitiveData...)
}
