import SwiftUI

struct ContentView: View {
    @EnvironmentObject var medicineManager: MedicineManager
    @State private var selectedTab = 0
    
    // A single state variable to drive the sheet presentation
    @State private var dueMedicine: Medicine?

    var body: some View {
        TabView(selection: $selectedTab) {
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("カレンダー")
                }
                .tag(0)
            
            MedicineRegistrationView()
                .tabItem {
                    Image(systemName: "pills.fill")
                    Text("薬の登録")
                }
                .tag(1)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showMedicineTakenView)) { notification in
            guard let userInfo = notification.userInfo,
                  let medicineId = userInfo["medicineId"] as? UUID else { return }
            
            // 1時間以内の通知かチェック
            if let notificationDate = userInfo["notificationDate"] as? Date,
               Date().timeIntervalSince(notificationDate) > 3600 {
                print("Notification is older than 1 hour. Ignoring.")
                return
            }
            
            // Find the medicine and set it to trigger the sheet
            self.dueMedicine = medicineManager.medicines.first { $0.id == medicineId }
        }
        .sheet(item: $dueMedicine) { medicine in
            MedicineTakenView(medicineId: medicine.id, medicineName: medicine.name) {
                // Custom onDismiss action
                self.dueMedicine = nil // Dismiss the sheet
                self.selectedTab = 0   // Switch to calendar
            }
            .environmentObject(medicineManager)
        }
        .onAppear(perform: checkForDueMedicine)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            checkForDueMedicine()
        }
    }

    private func checkForDueMedicine() {
        // Prevent showing a new sheet if one is already active
        guard dueMedicine == nil else { return }

        let now = Date()
        let calendar = Calendar.current

        // Find the most recent, untaken medicine that was due in the last hour
        let dueMedicineToShow = medicineManager.medicines
            .compactMap { medicine -> (medicine: Medicine, notificationDate: Date)? in
                // Get today's notification date for this medicine
                var components = medicine.notificationTime
                components.year = calendar.component(.year, from: now)
                components.month = calendar.component(.month, from: now)
                components.day = calendar.component(.day, from: now)
                
                guard let notificationDate = calendar.date(from: components) else { return nil }
                
                // Check if the medicine is scheduled for today
                let notificationWeekday = calendar.component(.weekday, from: notificationDate)
                guard medicine.notificationWeekdays.contains(notificationWeekday) else { return nil }
                
                return (medicine, notificationDate)
            }
            .filter { (medicine, notificationDate) in
                // Filter for notifications in the last hour
                let timeSince = now.timeIntervalSince(notificationDate)
                return timeSince > 0 && timeSince <= 3600
            }
            .filter { (medicine, notificationDate) in
                // Filter for untaken medicines
                return !medicineManager.isMedicineTaken(medicineId: medicine.id, on: now)
            }
            .sorted { $0.notificationDate > $1.notificationDate } // Sort by most recent first
            .first // Get the most recent one

        // Set the medicine to trigger the sheet
        self.dueMedicine = dueMedicineToShow?.medicine
    }
}

// 通知センターでカスタム通知名を定義
extension Notification.Name {
    static let showMedicineTakenView = Notification.Name("showMedicineTakenView")
}