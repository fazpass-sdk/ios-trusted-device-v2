
import UIKit
import Fazpass

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        Fazpass.shared.`init`(publicAssetName: "FazpassPublicKey", privateAssetName: "FazpassPrivateKey")
        
//        Fazpass.shared.enableSelected(
//            SensitiveData.location,
//            SensitiveData.vpn
//        )
        
        return true
    }
}
