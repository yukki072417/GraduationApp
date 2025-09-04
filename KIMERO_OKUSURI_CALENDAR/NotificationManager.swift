import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // 通知の許可をリクエストする
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
            if granted {
                print("Notification authorization granted.")
            } else if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
        }
    }

    // すべての薬の通知をスケジュールする
    func scheduleNotifications(for medicines: [Medicine]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        for medicine in medicines {
            scheduleNotification(for: medicine)
        }
    }

    // 特定の薬の通知をスケジュールする
    private func scheduleNotification(for medicine: Medicine) {
        let content = UNMutableNotificationContent()
        content.title = "お薬の時間です！"
        content.body = "\(medicine.name)を飲んでください。"
        content.sound = .defaultCritical
        content.userInfo = ["medicineId": medicine.id.uuidString, "medicineName": medicine.name]

        // 曜日ごとに通知をスケジュール
        for weekday in medicine.notificationWeekdays {
            var dateComponents = medicine.notificationTime
            dateComponents.weekday = weekday

            // 要件：LINEスタンプ連打のような通知量
            // 1秒ごとに10回通知をスケジュールする
            for i in 0..<10 {
                var notificationDateComponents = dateComponents
                notificationDateComponents.second = (dateComponents.second ?? 0) + i
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: notificationDateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: "\(medicine.id.uuidString)_weekday\(weekday)_\(i)", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // スケジュールされている通知をすべて削除する
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}