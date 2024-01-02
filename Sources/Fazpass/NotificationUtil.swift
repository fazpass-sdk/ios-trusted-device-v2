
import UIKit
import FirebaseCore
import FirebaseMessaging

internal class NotificationUtil: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    let crossDeviceRequestStream: CrossDeviceRequestStream
    
    init(crossDeviceRequestStream: CrossDeviceRequestStream) {
        self.crossDeviceRequestStream = crossDeviceRequestStream
    }
    
    func configure(_ application: UIApplication, _ appId: String) {
        let firebaseOptions = FirebaseOptions(
            googleAppID: appId,
            gcmSenderID: "762638394860")
        firebaseOptions.apiKey = "AIzaSyCLghGa0eIVOy8_Jhaks7QDBx8qHnhwNsM"
        firebaseOptions.projectID = "seamless-notification"
        FirebaseApp.configure(options: firebaseOptions)
        
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: { authorized, _ in }
        )
        Messaging.messaging().delegate = self
        
        application.registerForRemoteNotifications()
    }
    
    func registerDeviceToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func getFcmToken() async -> String {
        var fcmToken: String
        do {
            fcmToken = try await Messaging.messaging().token()
        } catch {
            fcmToken = ""
        }
        return fcmToken
    }
    
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken token: String?) {
        let dataDict: [String: String] = ["token": token ?? ""]
        NotificationCenter.default.post(
          name: Notification.Name("FCMToken"),
          object: nil,
          userInfo: dataDict
        )
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo

        // Print full message.
        print("willPresent: \(userInfo)")
        
        do {
            try crossDeviceRequestStream.send(crossDeviceRequest: CrossDeviceRequest(data: userInfo))
        } catch {}

        // Change this to your preferred presentation option
        return [[.alert, .sound, .badge]]
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo

        print("didReceive: \(userInfo)")
        
        do {
            try crossDeviceRequestStream.send(crossDeviceRequest: CrossDeviceRequest(data: userInfo))
        } catch {}
    }
}
