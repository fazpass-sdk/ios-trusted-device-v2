
import UIKit
import CoreLocation

internal protocol IosTrustedDevice {
    func generateMeta(_ app: UIApplication, resultBlock: @escaping (String) -> Void) async
    func enableSelected(_ selected: SensitiveData...)
}
