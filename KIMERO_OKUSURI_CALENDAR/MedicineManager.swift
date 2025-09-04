import Foundation

class MedicineManager: ObservableObject {
    @Published var medicines: [Medicine] = []
    @Published var takenRecords: [MedicineTakenRecord] = []

    private let medicinesKey = "medicines_v2"
    private let takenRecordsKey = "takenRecords_v2"

    init() {
        loadMedicines()
        loadTakenRecords()
    }

    // MARK: - Medicine Management
    func addMedicine(name: String, weekdays: [Int], time: DateComponents) {
        let newMedicine = Medicine(name: name, notificationWeekdays: weekdays, notificationTime: time)
        medicines.append(newMedicine)
        saveMedicines()
    }

    func deleteMedicine(at offsets: IndexSet) {
        medicines.remove(atOffsets: offsets)
        saveMedicines()
    }

    // MARK: - Taken Record Management
    func addTakenRecord(medicineId: UUID) {
        let newRecord = MedicineTakenRecord(medicineId: medicineId, date: Date())
        takenRecords.append(newRecord)
        saveTakenRecords()
    }

    // 指定した日付の服用記録を取得する
    func getTakenRecords(for date: Date) -> [MedicineTakenRecord] {
        return takenRecords.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    // 指定した薬が指定した日に服用されたかチェックする
    func isMedicineTaken(medicineId: UUID, on date: Date) -> Bool {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return takenRecords.contains { record in
            return record.medicineId == medicineId && record.date >= startOfDay && record.date < endOfDay
        }
    }

    // MARK: - Persistence
    private func saveMedicines() {
        if let encoded = try? JSONEncoder().encode(medicines) {
            UserDefaults.standard.set(encoded, forKey: medicinesKey)
        }
    }

    private func loadMedicines() {
        if let data = UserDefaults.standard.data(forKey: medicinesKey),
           let decoded = try? JSONDecoder().decode([Medicine].self, from: data) {
            medicines = decoded
        }
    }

    private func saveTakenRecords() {
        if let encoded = try? JSONEncoder().encode(takenRecords) {
            UserDefaults.standard.set(encoded, forKey: takenRecordsKey)
        }
    }

    private func loadTakenRecords() {
        if let data = UserDefaults.standard.data(forKey: takenRecordsKey),
           let decoded = try? JSONDecoder().decode([MedicineTakenRecord].self, from: data) {
            takenRecords = decoded
        }
    }
}