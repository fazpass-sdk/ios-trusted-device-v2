
import DeviceKit

internal class DeviceInfoUtil {
    
    let deviceInfo: DeviceInfo
    
    init() {
        let device = Device.current
        deviceInfo = DeviceInfo(
            os: "\(device.systemVersion ?? "")",
            brand: "\(device)",
            type: "\(device.model ?? "")",
            cpu: "\(device.cpu)"
        )
    }
}
