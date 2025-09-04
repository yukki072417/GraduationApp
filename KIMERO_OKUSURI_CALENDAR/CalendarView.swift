import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var medicineManager: MedicineManager
    @State private var selectedDate = Date()

    var body: some View {
        VStack {
            // カレンダー表示
            DatePicker(
                "日付を選択",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()

            Divider()

            // 選択した日の服用状況
            Text("\(selectedDate, formatter: dateFormatter)の服用状況")
                .font(.title2)
                .padding(.top)
            
            List {
                // その曜日に飲むべき薬をフィルタリング
                let weekday = Calendar.current.component(.weekday, from: selectedDate)
                let medicinesForDay = medicineManager.medicines.filter { $0.notificationWeekdays.contains(weekday) }
                
                if medicinesForDay.isEmpty {
                    Text("この日に飲む予定の薬はありません。")
                        .foregroundColor(.gray)
                } else {
                    ForEach(medicinesForDay) { medicine in
                        HStack {
                            Text(medicine.name)
                            Spacer()
                            if medicineManager.isMedicineTaken(medicineId: medicine.id, on: selectedDate) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("服用済み")
                            } else {
                                Image(systemName: "x.circle.fill")
                                    .foregroundColor(.red)
                                Text("未服用")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
}