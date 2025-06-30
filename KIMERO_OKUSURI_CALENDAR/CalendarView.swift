import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var medicineManager: MedicineManager
    @State private var selectedDate = Date()
    @State private var showingDateDetail = false
    @State private var selectedDateRecords: [MedicineRecord] = []
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            VStack {
                // カスタムカレンダー
                CalendarGridView(
                    selectedDate: $selectedDate,
                    datesWithRecords: medicineManager.getDatesWithRecords(),
                    onDateTapped: { date in
                        selectedDate = date
                        selectedDateRecords = medicineManager.getRecords(for: date)
                        if !selectedDateRecords.isEmpty {
                            showingDateDetail = true
                        }
                    }
                )
                
                Spacer()
                
                // 選択した日付の情報
                VStack {
                    Text("選択日: \(dateFormatter.string(from: selectedDate))")
                        .font(.headline)
                        .padding()
                    
                    let todayRecords = medicineManager.getRecords(for: selectedDate)
                    if todayRecords.isEmpty {
                        Text("この日の記録はありません")
                            .foregroundColor(.gray)
                    } else {
                        Text("\(todayRecords.count)件の服用記録")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            }
            .navigationTitle("お薬カレンダー")
            .sheet(isPresented: $showingDateDetail) {
                DateDetailView(date: selectedDate, records: selectedDateRecords)
            }
        }
    }
}

struct CalendarGridView: View {
    @Binding var selectedDate: Date
    let datesWithRecords: Set<Date>
    let onDateTapped: (Date) -> Void
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack {
            // 月年表示
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            
            // 曜日ヘッダー
            HStack {
                ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // カレンダーグリッド
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            hasRecord: datesWithRecords.contains(calendar.startOfDay(for: date)),
                            onTap: {
                                selectedDate = date
                                onDateTapped(date)
                            }
                        )
                    } else {
                        // 空白の日
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 40)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: selectedDate)
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        let monthEnd = monthInterval.end
        
        var date = monthFirstWeek.start
        while date < monthEnd {
            if calendar.isDate(date, equalTo: selectedDate, toGranularity: .month) {
                days.append(date)
            } else {
                days.append(nil)
            }
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        // 42日（6週間）まで埋める
        while days.count < 42 {
            days.append(nil)
        }
        
        return days
    }
    
    private func previousMonth() {
        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func nextMonth() {
        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let hasRecord: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(width: 40, height: 40)
                
                if hasRecord {
                    Circle()
                        .stroke(Color.green, lineWidth: 2)
                        .frame(width: 36, height: 36)
                }
                
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : .primary)
                    .fontWeight(hasRecord ? .bold : .regular)
            }
        }
        .frame(height: 40)
    }
}

struct DateDetailView: View {
    let date: Date
    let records: [MedicineRecord]
    @Environment(\.presentationMode) var presentationMode
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(dateFormatter.string(from: date))
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ForEach(records) { record in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(record.medicineName)
                                    .font(.headline)
                                Spacer()
                                Text(timeFormatter.string(from: record.date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let image = record.uiImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 200)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("服用記録")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing:
                Button("閉じる") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
