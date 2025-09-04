
import SwiftUI

struct MedicineRegistrationView: View {
    @EnvironmentObject var medicineManager: MedicineManager
    @State private var isShowingAddSheet = false

    var body: some View {
        NavigationView {
            VStack {
                if medicineManager.medicines.isEmpty {
                    Text("登録された薬はありません。")
                        .foregroundColor(.gray)
                } else {
                    List {
                        ForEach(medicineManager.medicines) { medicine in
                            VStack(alignment: .leading) {
                                Text(medicine.name).font(.headline)
                                Text(formatSchedule(weekdays: medicine.notificationWeekdays, time: medicine.notificationTime))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .onDelete(perform: deleteMedicine)
                    }
                }
            }
            .navigationTitle("薬の登録")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddSheet) {
                AddMedicineView()
                    .environmentObject(medicineManager)
            }
        }
    }

    private func deleteMedicine(at offsets: IndexSet) {
        medicineManager.deleteMedicine(at: offsets)
        NotificationManager.shared.scheduleNotifications(for: medicineManager.medicines)
    }
    
    private func formatSchedule(weekdays: [Int], time: DateComponents) -> String {
        let weekdaySymbols = Calendar.current.shortWeekdaySymbols
        let sortedWeekdays = weekdays.sorted()
        let days = sortedWeekdays.map { weekdaySymbols[$0 - 1] }.joined(separator: ", ")
        let hour = time.hour ?? 0
        let minute = time.minute ?? 0
        return String(format: "%@ %02d:%02d", days, hour, minute)
    }
}

struct AddMedicineView: View {
    @EnvironmentObject var medicineManager: MedicineManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var notificationTime = Date()
    @State private var selectedWeekdays = [Int]()
    
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("薬の情報")) {
                    TextField("薬の名前", text: $name)
                }
                
                Section(header: Text("通知設定")) {
                    DatePicker("時間", selection: $notificationTime, displayedComponents: .hourAndMinute)
                    
                    VStack(alignment: .leading) {
                        Text("曜日").font(.headline)
                        HStack(spacing: 10) {
                            ForEach(1...7, id: \.self) { weekday in
                                Text(weekdays[weekday - 1])
                                    .font(.subheadline)
                                    .frame(width: 35, height: 35)
                                    .foregroundColor(selectedWeekdays.contains(weekday) ? .white : .blue)
                                    .background(selectedWeekdays.contains(weekday) ? Color.blue : Color.white)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.blue, lineWidth: 1)
                                    )
                                    .onTapGesture {
                                        toggleWeekday(weekday)
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle("薬を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { saveMedicine() }
                        .disabled(name.isEmpty || selectedWeekdays.isEmpty)
                }
            }
        }
    }
    
    private func toggleWeekday(_ weekday: Int) {
        if let index = selectedWeekdays.firstIndex(of: weekday) {
            selectedWeekdays.remove(at: index)
        } else {
            selectedWeekdays.append(weekday)
        }
    }
    
    private func saveMedicine() {
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
        medicineManager.addMedicine(name: name, weekdays: selectedWeekdays, time: timeComponents)
        NotificationManager.shared.scheduleNotifications(for: medicineManager.medicines)
        dismiss()
    }
}
