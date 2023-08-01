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
    
    private let bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZGVudGlmaWVyIjo0fQ.WEV3bCizw9U_hxRC6DxHOzZthuJXRE8ziI3b6bHUpEI"
    
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
                            Button(type.rawValue) { apiRequest(type: type, meta: a.meta, fazpassId: a.fazpassId) }
                        }
                    }
                }
            }
            HStack {
                Button("Generate Meta", action: generateMeta)
            }
        }
    }
    
    private func generateMeta() {
        deleteItems()
        Fazpass.shared.generateMeta { meta in
            addItem(
                title: "Generated Meta",
                content: meta,
                action: ActionData(
                    type: RequestType.check.rawValue,
                    meta: meta,
                    fazpassId: nil
                ).toJsonString()
            )
        }
    }
    
    private func apiRequest(type: RequestType, meta: String, fazpassId: String? = nil) {
        let url = URL(string: "https://api.fazpas.com/v2/trusted-device/\(type)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Authorization": "Bearer \(bearerToken)",
            "Content-Type": "application/json"
        ]
        switch type {
        case .check, .enroll:
            request.httpBody = """
            {
              "merchant_app_id": "e30e8ae2-1557-46f6-ba3a-755b57ce4c44",
              "meta": "\(meta)",
              "pic_id": "anvarisy@gmail.com"
            }
            """.data(using: .utf8)
        case .validate, .remove:
            request.httpBody = """
            {
              "merchant_app_id": "e30e8ae2-1557-46f6-ba3a-755b57ce4c44",
              "meta": "\(meta)",
              "fazpass_id": "\(fazpassId ?? "")"
            }
            """.data(using: .utf8)
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if (data != nil) {
                guard let strData = String(data: data!, encoding: .utf8) else {
                    return
                }
                
                var fId = fazpassId
                if (fId == nil || fId == "") {
                    fId = Fazpass.shared.getFazpassId(response: strData)
                    if (fId != "") {
                        self.addItem(title: "fazpass id", content: fId!, action: nil)
                    }
                }
                
                var action: ActionData?
                switch type {
                case .check:
                    action = ActionData(type: RequestType.enroll.rawValue, meta: meta, fazpassId: fId)
                case .enroll:
                    action = ActionData(type: RequestType.validate.rawValue, meta: meta, fazpassId: fId)
                case .validate:
                    action = ActionData(type: RequestType.remove.rawValue, meta: meta, fazpassId: fId)
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
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems() {
        withAnimation {
            items.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
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
