
import UIKit
import Fazpass

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        Fazpass.shared.`init`(assetName: "FazpassPublicKey")
        
        Fazpass.shared.enableSelected(
            SensitiveData.location,
            SensitiveData.vpn
        )
        
        Task {
            await Fazpass.shared.generateMeta { meta in
                print(meta)
            }
        }
        
        return true
    }
}
