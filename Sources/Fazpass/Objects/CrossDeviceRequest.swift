
public struct CrossDeviceRequest {
    let merchantAppId: String
    let expired: Int
    let deviceReceive: String
    let deviceRequest: String
    let deviceIdReceive: String
    let deviceIdRequest: String
    
    internal init(data: [AnyHashable: Any]) throws {
        merchantAppId = data["merchant_app_id"] as! String
        expired = data["expired"] as! Int
        deviceReceive = data["device_receive"] as! String
        deviceRequest = data["device_request"] as! String
        deviceIdReceive = data["device_id_receive"] as! String
        deviceIdRequest = data["device_id_request"] as! String
    }
}
