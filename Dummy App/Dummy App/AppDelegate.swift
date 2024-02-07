
import UIKit
import Fazpass

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        Fazpass.shared.`init`(
            publicAssetName: "FazpassStagingPublicKey",
            application: application,
            fcmAppId: "1:762638394860:ios:19b19305e8ae6a4dc90cc9"
        )
        
        do {
            //try Fazpass.shared.generateSecretKeyForHighLevelBiometric()
        } catch {
            print(error)
        }
        
        let settings = FazpassSettings.Builder()
            .setBiometricLevelToHigh()
            .build()
        
        Fazpass.shared.setFazpassSettingsForAccountIndex(accountIndex: 0, settings: settings)
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        //print("registered device token: \(String(describing: token))")
        Fazpass.shared.registerDeviceToken(deviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) async -> UIBackgroundFetchResult {
        
        // Print full message.
        print("application:didReceive: \(userInfo)")
        let request = Fazpass.shared.getCrossDeviceRequestFromNotification(userInfo: userInfo)
        if request != nil { print(request!) }
        
        return UIBackgroundFetchResult.newData
    }
}
