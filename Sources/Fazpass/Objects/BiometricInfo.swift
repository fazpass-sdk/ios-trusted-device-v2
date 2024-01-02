
internal struct BiometricInfo: Codable {
    let level: String
    let isChanged: Bool
    
    enum CodingKeys: String, CodingKey {
        case level
        case isChanged = "is_changed"
    }
}
