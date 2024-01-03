
public struct CrossDeviceRequest {
    public let merchantAppId: String
    public let expired: Int
    public let deviceReceive: String
    public let deviceRequest: String
    public let deviceIdReceive: String
    public let deviceIdRequest: String
    
    public init(data: [AnyHashable: Any]) throws {
        merchantAppId = data["merchant_app_id"] as! String
        expired = data["expired"] as! Int
        deviceReceive = data["device_receive"] as! String
        deviceRequest = data["device_request"] as! String
        deviceIdReceive = data["device_id_receive"] as! String
        deviceIdRequest = data["device_id_request"] as! String
    }
}
