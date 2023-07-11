
struct DeviceInfo: Codable {
    let os: String
    let brand: String
    let type: String
    let cpu: String
    
    enum CodingKeys: String, CodingKey {
        case os = "os_version"
        case brand = "name"
        case type = "series"
        case cpu
    }
    
    func asReadableString() -> String {
        return "os: \(os), brand: \(brand), type: \(type), cpu: \(cpu)"
    }
}
