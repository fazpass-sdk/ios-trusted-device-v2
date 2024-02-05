//
//  ContentView.swift
//  Dummy App
//
//  Created by Andri nova riswanto on 26/06/23.
//

import SwiftUI
import CoreData
import Fazpass

struct ContentView: View {
    
    private let privateAssetName = "FazpassStagingPrivateKey"
    private let bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZGVudGlmaWVyIjozNn0.mfny8amysdJQYlCrUlYeA-u4EG1Dw9_nwotOl-0XuQ8"
    private let merchantAppId = "afb2c34a-4c4f-4188-9921-5c17d81a3b3d"
    
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ItemData.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<ItemData>

    var body: some View {
        VStack {
            List {
                ForEach(items) { item in
                    VStack {
                        Text(item.title!)
                            .bold()
                            .font(.headline)
                            .padding(EdgeInsets(top: 4.0, leading: 0.0, bottom: 8.0, trailing: 0.0))
                        Text(item.content!)
                            .padding(EdgeInsets(top: 0.0, leading: 0.0, bottom: 8.0, trailing: 0.0))
                        if (item.action != nil) {
                            let a = ActionData.fromJsonString(item.action!)!
                            let type = RequestType(rawValue: a.type)!
                            Button(type.rawValue) { apiRequest(type: type, meta: a.meta, fazpassId: a.fazpassId, challenge: a.challenge) }
                        }
                    }
                }
            }
            Button("Generate Meta", action: generateMeta)
                .padding(EdgeInsets(top: 0.0, leading: 0.0, bottom: 12.0, trailing: 0.0))
        }
    }
    
    private func generateMeta() {
        deleteItems()
        Fazpass.shared.generateMeta(accountIndex: 0) { meta, error in
            guard let error = error else {
                addItem(
                    title: "Generated Meta",
                    content: meta,
                    action: ActionData(
                        type: RequestType.check.rawValue,
                        meta: meta,
                        fazpassId: nil,
                        challenge: nil
                    ).toJsonString()
                )
                return
            }
            
            print(error)
        }
    }
    
    private func apiRequest(type: RequestType, meta: String, fazpassId: String? = nil, challenge: String? = nil) {
        let url = URL(string: "https://api.fazpas.com/v2/trusted-device/\(type)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Authorization": "Bearer \(bearerToken)",
            "Content-Type": "application/json"
        ]
        switch type {
        case .check:
            request.httpBody = """
            {
              "merchant_app_id": "\(merchantAppId)",
              "meta": "\(meta)",
              "pic_id": "anvarisy@gmail.com"
            }
            """.data(using: .utf8)
        case .enroll:
            request.httpBody = """
            {
              "merchant_app_id": "\(merchantAppId)",
              "meta": "\(meta)",
              "pic_id": "anvarisy@gmail.com",
              "challenge": "\(challenge ?? "")"
            }
            """.data(using: .utf8)
        case .validate, .remove:
            request.httpBody = """
            {
              "merchant_app_id": "\(merchantAppId)",
              "meta": "\(meta)",
              "fazpass_id": "\(fazpassId ?? "")",
              "challenge": "\(challenge ?? "")"
            }
            """.data(using: .utf8)
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if (data != nil) {
                guard let strData = String(data: data!, encoding: .utf8) else {
                    return
                }
                
                self.addItem(title: "\(type) Response", content: strData, action: nil)
                
                var fId = fazpassId
                var chal = challenge
                if type == .check {
                    print(strData)
                    let fIdAndChal = getFazpassIdAndChallenge(response: strData)
                    print(fIdAndChal)
                    if ((fId == nil || fId == "") && fIdAndChal.isEmpty == false) {
                        fId = fIdAndChal[0]
                        if (fId != "") {
                            self.addItem(title: "fazpass id", content: fId!, action: nil)
                        }
                    }
                    if ((chal == nil || chal == "") && fIdAndChal.isEmpty == false) {
                        chal = fIdAndChal[1]
                        if (chal != "") {
                            self.addItem(title: "challenge", content: chal!, action: nil)
                        }
                    }
                }
                
                var action: ActionData?
                switch type {
                case .check:
                    action = ActionData(type: RequestType.enroll.rawValue, meta: meta, fazpassId: fId, challenge: chal)
                case .enroll:
                    action = ActionData(type: RequestType.validate.rawValue, meta: meta, fazpassId: fId, challenge: chal)
                case .validate:
                    action = ActionData(type: RequestType.remove.rawValue, meta: meta, fazpassId: fId, challenge: chal)
                default:
                    action = nil
                }
                
                self.addItem(
                    title: "\(type.rawValue) response",
                    content: strData,
                    action: action?.toJsonString()
                )
            } else {
                self.addItem(
                    title: "\(type.rawValue) response",
                    content: error.debugDescription,
                    action: nil
                )
            }
        }.resume()
    }

    private func addItem(title: String, content: String, action: String?) {
        withAnimation {
            let newItem = ItemData(context: viewContext)
            newItem.title = title
            newItem.content = content
            newItem.action = action
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems() {
        withAnimation {
            items.forEach(viewContext.delete)

            do {
                try PersistenceController.shared.container.viewContext.save()
                viewContext.refreshAllObjects()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func getFazpassIdAndChallenge(response: String) -> [String] {
        guard let data = response.data(using: .utf8, allowLossyConversion: false) else { return [] }
        guard let mapper = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject] else { return [] }
        
        guard let meta = mapper["data"]?["meta"] as? String else { return [] }
        
        let jsonMeta = decryptMetaData(meta)
        print(jsonMeta)
        if (!jsonMeta.isEmpty) {
            guard let data2 = jsonMeta.data(using: .utf8, allowLossyConversion: false) else { return [] }
            guard let mapper2 = try? JSONSerialization.jsonObject(with: data2, options: .mutableContainers) as? [String:AnyObject] else { return [] }

            print("biometric: \(mapper2["biometric"] as? [String:Any] ?? [:])")

            return [ mapper2["fazpass_id"] as? String ?? "",
                     mapper2["challenge"] as? String ?? "" ]
        }
        
        return []
    }
    
    private func decryptMetaData(_ encryptedMetaData: String) -> String {
        guard let data = Data(base64Encoded: encryptedMetaData) else {
            print("Failed to encode encryted meta data!")
            return ""
        }
        
        guard let privateKeyFile = NSDataAsset(name: privateAssetName) else {
            print("Key not found!")
            return ""
        }
        
        guard var key = String(data: privateKeyFile.data, encoding: String.Encoding.utf8) else {
            print("Failed to convert private key file to string")
            return ""
        }
        
        key = key.replacingOccurrences(of: "-----BEGIN RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
        
        guard let base64Key = Data(base64Encoded: key) else {
            print("Failed to encode key to base64")
            return ""
        }
        
        let options: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: 2048
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateWithData(base64Key as CFData,
                                                options as CFDictionary,
                                                &error) else {
            print(String(describing: error))
            return ""
        }
        
        var keySize = SecKeyGetBlockSize(privateKey)
        var keyBuffer = [UInt8](repeating: 0, count: keySize)
        
        // Decrypted data will be written to keyBuffer
        guard SecKeyDecrypt(privateKey, .PKCS1, [UInt8](data), data.count, &keyBuffer, &keySize) == errSecSuccess else {
            return ""
        }
            
        return String(bytes: keyBuffer, encoding: .utf8)?.replacingOccurrences(of: "\u{0000}", with: "", options: NSString.CompareOptions.literal, range: nil).trimmingCharacters(in: .whitespaces) ?? ""
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

enum RequestType: String {
    case check, enroll, validate, remove
}
