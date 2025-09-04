import SwiftUI
import UserNotifications

@main
struct KIMERO_OKUSURI_CALENDARApp: App {
    @StateObject private var medicineManager = MedicineManager()
    // AppDelegateをインスタンス化
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(medicineManager)
                .onAppear {
                    // 初回起動時に通知の許可をリクエスト
                    NotificationManager.shared.requestAuthorization()
                    // 登録済みの薬から通知をスケジュール
                    NotificationManager.shared.scheduleNotifications(for: medicineManager.medicines)
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // 通知バナーがタップされたときに呼ばれる
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let medicineIdString = userInfo["medicineId"] as? String,
           let medicineId = UUID(uuidString: medicineIdString),
           let medicineName = userInfo["medicineName"] as? String {
            
            // 薬服用登録画面を表示するための通知を送信
            NotificationCenter.default.post(
                name: .showMedicineTakenView,
                object: nil,
                userInfo: [
                    "medicineId": medicineId,
                    "medicineName": medicineName,
                    "notificationDate": Date() // 通知を受け取った時刻
                ]
            )
        }
        
        completionHandler()
    }
    
    // アプリがフォアグラウンドで通知を受け取ったときに呼ばれる
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // フォアグラウンドでもアラート、サウンド、バッジを表示する
        completionHandler([.banner, .sound, .badge])
    }
}