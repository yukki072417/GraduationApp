import SwiftUI
import AVFoundation

struct MedicineTakenModalView: View {
    @EnvironmentObject private var medicineManager: MedicineManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showingCamera = false
    @State private var selectedResponse: MedicineResponse = .notYet
    @State private var capturedImage: UIImage?
    @State private var showingPhotoRequiredAlert = false
    @State private var notificationCount = 0
    @State private var animationOffset: CGFloat = 0
    @State private var pulseAnimation = false
    
    enum MedicineResponse {
        case yes, notYet
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景を緊急感のある色に
                LinearGradient(
                    colors: [Color.red.opacity(0.3), Color.orange.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if let pendingMedicine = medicineManager.getCurrentPendingMedicine() {
                        VStack(spacing: 20) {
                            // アニメーション付きアイコン
                            Image(systemName: "pills.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.red)
                                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: pulseAnimation)
                                .onAppear {
                                    pulseAnimation = true
                                    // アニメーションオフセットも開始
                                    withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                                        animationOffset = 5
                                    }
                                }
                            
                            // 緊急性を強調したタイトル
                            VStack(spacing: 10) {
                                Text("🚨 緊急アラート 🚨")
                                    .font(.title)
                                    .fontWeight(.black)
                                    .foregroundColor(.red)
                                    .offset(x: animationOffset)
                                
                                Text("お薬の時間です！")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            
                            // 薬の情報
                            VStack(spacing: 8) {
                                Text(pendingMedicine.medicine.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                    .multilineTextAlignment(.center)
                                
                                Text("予定時刻: \(pendingMedicine.medicine.timeString)")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                // 通知回数表示
                                Text("🔥 通知回数: \(notificationCount + 1)回目 🔥")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.yellow.opacity(0.3))
                                    .cornerRadius(8)
                            }
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(15)
                        }
                        
                        Spacer()
                        
                        // 重要な注意書き
                        VStack(spacing: 12) {
                            Text("⚠️ 重要 ⚠️")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            
                            Text("「はい」を選択すると写真撮影が必要です\n写真を撮るまで通知は止まりません")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(12)
                        
                        // 選択ボタン
                        VStack(spacing: 20) {
                            Text("薬を飲みましたか？")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            HStack(spacing: 30) {
                                // はいボタン（写真撮影必須）
                                Button(action: {
                                    selectedResponse = .yes
                                    checkCameraAndProceed()
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.green)
                                        Text("はい")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                        Text("(写真撮影)")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                    .padding()
                                    .frame(width: 120, height: 100)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(15)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.green, lineWidth: 2)
                                    )
                                }
                                
                                // まだボタン（通知継続）
                                Button(action: {
                                    selectedResponse = .notYet
                                    showingPhotoRequiredAlert = true
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.system(size: 40))
                                            .foregroundColor(.orange)
                                        Text("まだ")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.orange)
                                        Text("(継続通知)")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                    .padding()
                                    .frame(width: 120, height: 100)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(15)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.orange, lineWidth: 2)
                                    )
                                }
                            }
                        }
                        
                        // 写真撮影済みの場合の表示
                        if let image = capturedImage {
                            VStack(spacing: 10) {
                                Text("✅ 写真撮影完了")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 100)
                                    .cornerRadius(8)
                                
                                Button("記録完了") {
                                    // 通知を完全停止
                                    notificationManager.medicineWasTaken()
                                    presentationMode.wrappedValue.dismiss()
                                }
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCamera) {
                CameraView(capturedImage: $capturedImage)
            }
            .alert("通知継続", isPresented: $showingPhotoRequiredAlert) {
                Button("OK") {
                    // 通知カウントを増やして継続
                    notificationCount += 1
                    // モーダルを閉じる
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("5分後に再度通知します")
            }
        }
    }
    
    // カメラチェックとプロシージャ実行
    private func checkCameraAndProceed() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingCamera = true
                    }
                }
            }
        case .denied, .restricted:
            // カメラアクセスが拒否された場合の処理
            break
        @unknown default:
            break
        }
    }
}

// カメラビューの実装が必要
struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
