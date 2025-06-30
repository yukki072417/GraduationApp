import Foundation
import UIKit

// 薬の情報を保持するモデル
struct Medicine: Identifiable, Codable {
    let id = UUID()
    let name: String
    let hour: Int
    let minute: Int
    let isActive: Bool
    
    var timeString: String {
        return String(format: "%02d:%02d", hour, minute)
    }
}

// 薬を飲んだ記録を保持するモデル
struct MedicineRecord: Identifiable, Codable {
    let id = UUID()
    let medicineId: UUID
    let medicineName: String
    let date: Date
    let photoData: Data?
    
    var uiImage: UIImage? {
        guard let data = photoData else { return nil }
        return UIImage(data: data)
    }
}

// 通知のためのモデル
struct PendingMedicine: Identifiable {
    let id = UUID()
    let medicine: Medicine
    let scheduledTime: Date
    let isPhotoTaken: Bool
}
