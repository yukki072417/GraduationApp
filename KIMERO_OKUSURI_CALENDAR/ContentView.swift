import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var medicineManager: MedicineManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @State private var selectedTab = 0
    @State private var showingMedicineModal = false
    
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
                    Text("お薬登録")
                }
                .tag(1)
        }
        .sheet(isPresented: $showingMedicineModal) {
            MedicineTakenModalView()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // アプリがフォアグラウンドに戻った時の処理
            checkForPendingMedicines()
        }
        .onAppear {
            checkForPendingMedicines()
        }
    }
    
    private func checkForPendingMedicines() {
        if medicineManager.hasPendingMedicine() {
            showingMedicineModal = true
        }
    }
}

#Preview{
    ContentView()
}
