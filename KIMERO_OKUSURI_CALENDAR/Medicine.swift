import Foundation

// 薬の情報を定義する構造体
struct Medicine: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    // 通知する曜日 (1:日曜, 2:月曜, ..., 7:土曜)
    var notificationWeekdays: [Int]
    // 通知する時間
    var notificationTime: DateComponents
}

// 薬の服用記録を定義する構造体
struct MedicineTakenRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    var medicineId: UUID
    var date: Date
}