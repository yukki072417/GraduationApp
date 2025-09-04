import SwiftUI

struct MedicineTakenView: View {
    @EnvironmentObject var medicineManager: MedicineManager
    let medicineId: UUID
    let medicineName: String
    // 画面を閉じるためのコールバック
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Text("\(medicineName)を飲みましたか？")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Button(action: {
                // 服用を記録
                medicineManager.addTakenRecord(medicineId: medicineId)
                // 画面を閉じる
                onDismiss()
            }) {
                Text("飲みました")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 80)
                    .padding(.vertical, 20)
                    .background(Color.blue)
                    .cornerRadius(20)
            }
        }
    }
}