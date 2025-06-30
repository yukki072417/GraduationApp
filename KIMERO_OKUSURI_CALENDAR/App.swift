import SwiftUI
import UserNotifications

@main
struct MedicineCalendarApp: App {
    @StateObject private var medicineManager = MedicineManager()
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(medicineManager)
                .environmentObject(notificationManager)
                .onAppear {
                    requestNotificationPermission()
                }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知許可が得られました")
            } else {
                print("通知許可が拒否されました")
            }
        }
    }
}
