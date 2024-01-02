//
//  ActionData.swift
//  Dummy App
//
//  Created by Andri nova riswanto on 01/08/23.
//

import Foundation

struct ActionData: Codable {
    let type: String
    let meta: String
    let fazpassId: String?
    let challenge: String?
    
    func toJsonString() -> String? {
        if let jsonData = try? JSONEncoder().encode(self) {
            return String(data: jsonData, encoding: .utf8)
        }
        return nil
    }
    
    static func fromJsonString(_ json: String) -> ActionData? {
        if let data = json.data(using: .utf8) {
            return try? JSONDecoder().decode(self, from: data)
        }
        return nil
    }
}
