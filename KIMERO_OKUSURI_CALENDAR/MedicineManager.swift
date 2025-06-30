import Foundation
import UIKit
import Combine

class MedicineManager: ObservableObject {
    @Published var medicines: [Medicine] = []
    @Published var records: [MedicineRecord] = []
    @Published var pendingMedicines: [PendingMedicine] = []
    
    private let medicinesKey = "SavedMedicines"
    private let recordsKey = "MedicineRecords"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadMedicines()
        loadRecords()
        scheduleNotifications()
        startPendingMedicineCheck()
    }
    
    // MARK: - Medicine Management
    func addMedicine(_ medicine: Medicine) {
        medicines.append(medicine)
        saveMedicines()
        scheduleNotifications()
    }
    
    func deleteMedicine(_ medicine: Medicine) {
        medicines.removeAll { $0.id == medicine.id }
        saveMedicines()
        scheduleNotifications()
    }
    
    // MARK: - Record Management
    func addRecord(for medicine: Medicine, with image: UIImage?) {
        // Intel Macでのメモリ効率を考慮して画像圧縮率を調整
        #if targetEnvironment(simulator)
        let compressionQuality: CGFloat = 0.5  // シミュレーター用
        #else
        let compressionQuality: CGFloat = 0.8  // 実機用
        #endif
        
        let imageData = image?.jpegData(compressionQuality: compressionQuality)
        let record = MedicineRecord(
            medicineId: medicine.id,
            medicineName: medicine.name,
            date: Date(),
            photoData: imageData
        )
        records.append(record)
        saveRecords()
        
        // 該当する保留中の薬を削除
        pendingMedicines.removeAll { $0.medicine.id == medicine.id }
    }
    
    func getRecords(for date: Date) -> [MedicineRecord] {
        let calendar = Calendar.current
        return records.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func getDatesWithRecords() -> Set<Date> {
        let calendar = Calendar.current
        return Set(records.map { calendar.startOfDay(for: $0.date) })
    }
    
    // MARK: - Pending Medicine Management
    func hasPendingMedicine() -> Bool {
        return !pendingMedicines.isEmpty
    }
    
    func getCurrentPendingMedicine() -> PendingMedicine? {
        return pendingMedicines.first
    }
    
    func markMedicineAsTaken(_ pendingMedicine: PendingMedicine) {
        // 実際の記録は写真撮影後に addRecord で行う
        if let index = pendingMedicines.firstIndex(where: { $0.id == pendingMedicine.id }) {
            pendingMedicines[index] = PendingMedicine(
                medicine: pendingMedicine.medicine,
                scheduledTime: pendingMedicine.scheduledTime,
                isPhotoTaken: false
            )
        }
    }
    
    private func startPendingMedicineCheck() {
        // Intel Macでのパフォーマンスを考慮してチェック間隔を調整
        #if targetEnvironment(simulator)
        let interval: TimeInterval = 120  // シミュレーター用：2分間隔
        #else
        let interval: TimeInterval = 60   // 実機用：1分間隔
        #endif
        
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.checkForDueMedicines()
        }
    }
    
    private func checkForDueMedicines() {
        let now = Date()
        let calendar = Calendar.current
        
        for medicine in medicines where medicine.isActive {
            let today = calendar.startOfDay(for: now)
            var medicineTime = calendar.date(bySettingHour: medicine.hour, minute: medicine.minute, second: 0, of: today) ?? now
            
            // 現在時刻を過ぎている場合は今日の予定時刻
            if medicineTime <= now {
                let timeInterval = now.timeIntervalSince(medicineTime)
                // 5分以内で、まだ記録されていない場合
                if timeInterval <= 300 && timeInterval >= 0 {
                    let alreadyTaken = records.contains { record in
                        record.medicineId == medicine.id &&
                        calendar.isDate(record.date, inSameDayAs: now) &&
                        abs(record.date.timeIntervalSince(medicineTime)) <= 1800 // 30分以内
                    }
                    
                    let alreadyPending = pendingMedicines.contains { $0.medicine.id == medicine.id }
                    
                    if !alreadyTaken && !alreadyPending {
                        let pending = PendingMedicine(
                            medicine: medicine,
                            scheduledTime: medicineTime,
                            isPhotoTaken: false
                        )
                        pendingMedicines.append(pending)
                    }
                }
            }
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
    
    private func saveRecords() {
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: recordsKey)
        }
    }
    
    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([MedicineRecord].self, from: data) {
            records = decoded
        }
    }
    
    // MARK: - Notifications (簡易実装)
    private func scheduleNotifications() {
        // 実際の通知スケジューリング処理
        // ここでは基本的な実装のみ
        print("通知をスケジュールしました")
    }
}
