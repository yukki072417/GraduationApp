import Foundation
import UserNotifications
import UIKit
import AVFoundation

class NotificationManager: NSObject, ObservableObject {
    private var continuousTimer: Timer?
    private var alertController: UIAlertController?
    private var audioPlayer: AVAudioPlayer?
    private var systemSoundTimer: Timer?
    private var hapticTimer: Timer?
    private var flashTimer: Timer?
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    private var notificationSequenceTimer: Timer?
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var currentMedicine: Medicine?
    private var notificationCount = 0
    private var isNotifying = false
    private var notificationIntensityLevel = 1 // 1-5の段階
    private var lastNotificationTime: Date = Date.distantPast
    
    override init() {
        super.init()
        setupAudioSession()
        setupBackgroundNotifications()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("オーディオセッション設定エラー: \(error)")
        }
    }
    
    private func setupBackgroundNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        if isNotifying {
            startBackgroundTask()
            scheduleStaggeredBackgroundNotifications()
        }
    }
    
    @objc private func appWillEnterForeground() {
        endBackgroundTask()
        if isNotifying {
            // フォアグラウンドに戻ったら即座に通知再開
            if let medicine = currentMedicine {
                startContinuousNotifications(for: medicine)
            }
        }
    }
    
    private func startBackgroundTask() {
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "MedicineNotification") {
            self.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }
    }
    
    func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
            print("通知権限: \(granted)")
            if let error = error {
                print("通知権限エラー: \(error)")
            }
        }
    }
    
    func startContinuousNotifications(for medicine: Medicine) {
        print("🚨🚨🚨 超絶しつこい通知開始！逃げられません！🚨🚨🚨")
        stopContinuousNotifications()
        isNotifying = true
        currentMedicine = medicine
        notificationCount = 0
        notificationIntensityLevel = 1
        lastNotificationTime = Date.distantPast
        
        // 複数の通知手段を同時実行
        startInAppAlerts(for: medicine)
        startContinuousSystemSounds()
        startContinuousHaptics()
        startSequentialLocalNotifications(for: medicine) // 改善された通知システム
        startScreenFlashing()
        startBadgeUpdates()
        startIntensityEscalation()
        
        // SwiftUI用のアラート状態も更新
        showSwiftUIAlert(for: medicine)
    }
    
    private func showSwiftUIAlert(for medicine: Medicine) {
        let messages = [
            "💊🚨💊 \(medicine.name)を今すぐ飲んでください！💊🚨💊",
            "🔥🔥🔥 緊急！\(medicine.name)の時間です！🔥🔥🔥",
            "⚠️⚠️⚠️ まだ飲んでいません！\(medicine.name)！⚠️⚠️⚠️",
            "📢📢📢 最重要！\(medicine.name)を服用してください！📢📢📢",
            "🚨🚨🚨 \(medicine.name)！忘れないで！🚨🚨🚨"
        ]
        
        notificationCount += 1
        alertMessage = "\(messages[notificationCount % messages.count])\n\n🔥通知回数: \(notificationCount)回目🔥\n強度レベル: \(notificationIntensityLevel)"
        showAlert = true
        
        // 強度に応じて再表示間隔を調整
        let nextAlertDelay = max(1.5, 3.0 / Double(notificationIntensityLevel))
        DispatchQueue.main.asyncAfter(deadline: .now() + nextAlertDelay) {
            if self.isNotifying {
                self.showSwiftUIAlert(for: medicine)
            }
        }
    }
    
    // 段階的に通知強度を上げる（より頻繁に）
    private func startIntensityEscalation() {
        Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { _ in
            guard self.isNotifying else { return }
            
            if self.notificationIntensityLevel < 5 {
                self.notificationIntensityLevel += 1
                print("🔥 通知強度をレベル\(self.notificationIntensityLevel)に上昇！")
                
                // 強度が上がるたびに間隔を短縮
                self.restartTimersWithNewIntensity()
            }
        }
    }
    
    private func restartTimersWithNewIntensity() {
        // 既存のタイマーを停止
        systemSoundTimer?.invalidate()
        hapticTimer?.invalidate()
        flashTimer?.invalidate()
        
        // より短い間隔で再開
        let soundInterval = max(0.8, 2.5 / Double(notificationIntensityLevel))
        let hapticInterval = max(0.5, 2.0 / Double(notificationIntensityLevel))
        let flashInterval = max(0.3, 0.8 / Double(notificationIntensityLevel))
        
        startContinuousSystemSounds(interval: soundInterval)
        startContinuousHaptics(interval: hapticInterval)
        startScreenFlashing(interval: flashInterval)
    }
    
    // アプリ内連続アラート（改善版）
    private func startInAppAlerts(for medicine: Medicine) {
        showInAppAlert(for: medicine)
    }
    
    private func showInAppAlert(for medicine: Medicine) {
        guard isNotifying else { return }
        
        DispatchQueue.main.async {
            // 既存のアラートを閉じる
            self.alertController?.dismiss(animated: false)
            
            let messages = [
                "🚨💊🚨 \(medicine.name)を今すぐ飲んでください！🚨💊🚨",
                "🔥🔥🔥 緊急事態！\(medicine.name)の時間です！🔥🔥🔥",
                "⚠️⚠️⚠️ 重要！まだ飲んでいません！\(medicine.name)！⚠️⚠️⚠️",
                "📢📢📢 最優先！\(medicine.name)を服用してください！📢📢📢",
                "🚁🚁🚁 ヘリコプター級の緊急事態！\(medicine.name)！🚁🚁🚁"
            ]
            
            self.notificationCount += 1
            let message = messages[self.notificationCount % messages.count]
            
            self.alertController = UIAlertController(
                title: "🚨🚨🚨 超緊急アラート 🚨🚨🚨",
                message: "\(message)\n\n🔥通知: \(self.notificationCount)回目🔥\n強度: Lv.\(self.notificationIntensityLevel)",
                preferredStyle: .alert
            )
            
            // 飲んだボタン（写真撮影へ）
            self.alertController?.addAction(UIAlertAction(title: "✅ 飲みました（写真撮影）", style: .default) { _ in
                NotificationCenter.default.post(name: NSNotification.Name("MedicineTakenFromAlert"), object: nil)
            })
            
            // スヌーズボタン（より短い間隔で）
            self.alertController?.addAction(UIAlertAction(title: "😴 20秒後", style: .cancel) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                    if self.isNotifying {
                        self.showInAppAlert(for: medicine)
                    }
                }
                // 3秒後にも再表示
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if self.isNotifying {
                        self.showInAppAlert(for: medicine)
                    }
                }
            })
            
            // 無視すると2秒後に再表示
            let nextAlertDelay = max(2.0, 4.0 / Double(self.notificationIntensityLevel))
            DispatchQueue.main.asyncAfter(deadline: .now() + nextAlertDelay) {
                if self.isNotifying && self.alertController?.presentingViewController == nil {
                    self.showInAppAlert(for: medicine)
                }
            }
            
            // アラートを表示
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                
                var topVC = rootVC
                while let presentedVC = topVC.presentedViewController {
                    topVC = presentedVC
                }
                
                topVC.present(self.alertController!, animated: true)
            }
        }
    }
    
    // 連続システム音（改善版）
    private func startContinuousSystemSounds(interval: TimeInterval = 1.5) {
        systemSoundTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            guard self.isNotifying else { return }
            
            // システム音を段階的に再生
            let sounds: [SystemSoundID] = [1005, 1016, 1013, 1010, 1020, 1021]
            let selectedSounds = Array(sounds.prefix(min(self.notificationIntensityLevel + 1, sounds.count)))
            
            for (index, sound) in selectedSounds.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3) {
                    if self.isNotifying {
                        AudioServicesPlaySystemSound(sound)
                    }
                }
            }
        }
    }
    
    // 連続振動（改善版）
    private func startContinuousHaptics(interval: TimeInterval = 1.2) {
        hapticTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            guard self.isNotifying else { return }
            
            let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
            let mediumFeedback = UIImpactFeedbackGenerator(style: .medium)
            let errorFeedback = UINotificationFeedbackGenerator()
            
            // 強度に応じた振動パターン
            let vibrationCount = min(self.notificationIntensityLevel + 2, 6)
            
            for i in 0..<vibrationCount {
                let delay = Double(i) * 0.15
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    if self.isNotifying {
                        if i % 2 == 0 {
                            heavyFeedback.impactOccurred()
                        } else {
                            mediumFeedback.impactOccurred()
                        }
                    }
                }
            }
            
            // 最後にエラー振動
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(vibrationCount) * 0.15) {
                if self.isNotifying {
                    errorFeedback.notificationOccurred(.error)
                }
            }
        }
    }
    
    // 画面点滅効果（改善版）
    private func startScreenFlashing(interval: TimeInterval = 0.5) {
        flashTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            guard self.isNotifying else { return }
            
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    
                    let colors = [UIColor.red, UIColor.orange, UIColor.yellow]
                    let color = colors[self.notificationIntensityLevel % colors.count]
                    
                    let flashView = UIView(frame: window.bounds)
                    flashView.backgroundColor = color.withAlphaComponent(0.7)
                    window.addSubview(flashView)
                    
                    UIView.animate(withDuration: 0.2, animations: {
                        flashView.alpha = 0
                    }) { _ in
                        flashView.removeFromSuperview()
                    }
                }
            }
        }
    }
    
    // シーケンシャルな通知システム（重要な改善）
    private func startSequentialLocalNotifications(for medicine: Medicine) {
        // 既存の通知をクリア
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // 初回通知を即座に送信
        sendUrgentNotification(for: medicine, sequence: 0)
        
        // シーケンシャル通知タイマーを開始
        var sequenceCount = 1
        notificationSequenceTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { timer in
            guard self.isNotifying else {
                timer.invalidate()
                return
            }
            
            // iOSの制限（64個）に達する前にリセット
            if sequenceCount >= 60 {
                sequenceCount = 0
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
            
            self.sendUrgentNotification(for: medicine, sequence: sequenceCount)
            sequenceCount += 1
        }
    }
    
    private func sendUrgentNotification(for medicine: Medicine, sequence: Int) {
        // 最後の通知から最低限の間隔を確保
        let now = Date()
        if now.timeIntervalSince(lastNotificationTime) < 5.0 && sequence > 0 {
            return
        }
        lastNotificationTime = now
        
        let content = UNMutableNotificationContent()
        content.title = "🚨🚨🚨 超緊急お薬アラート 🚨🚨🚨"
        
        let messages = [
            "💊🔥 \(medicine.name)を今すぐ飲んでください！🔥💊",
            "⚠️ \(medicine.name) 服用忘れです！緊急対応が必要です！",
            "🚨 \(medicine.name) まだ飲んでいません！健康に影響します！",
            "📢 \(medicine.name) 重要な薬です！今すぐ確認してください！",
            "🔔 \(medicine.name) アラーム継続中！対応をお願いします！"
        ]
        
        content.body = "\(messages[sequence % messages.count])\n通知\(notificationCount + sequence + 1)回目 (強度Lv.\(notificationIntensityLevel))"
        
        // 重要度に応じて音を変更
        if notificationIntensityLevel >= 3 {
            content.sound = .defaultCritical
        } else {
            content.sound = .default
        }
        
        content.badge = NSNumber(value: notificationCount + sequence + 1)
        content.categoryIdentifier = "MEDICINE_ALERT"
        content.userInfo = ["medicineId": medicine.id.uuidString, "sequence": sequence]
        
        // 即座に通知（但し、システム制限を考慮）
        let delay = sequence == 0 ? 0.5 : 1.0
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: "urgent_medicine_\(sequence)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知エラー: \(error)")
            } else {
                print("🚨 緊急通知送信: シーケンス\(sequence)")
            }
        }
    }
    
    // バックグラウンド時の改善された通知
    private func scheduleStaggeredBackgroundNotifications() {
        guard let medicine = currentMedicine else { return }
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // より効率的な通知スケジューリング（iOSの制限内で最大効果）
        let intervals = [10, 25, 45, 70, 100, 135, 175, 220, 270, 325] // 段階的な間隔
        
        for (index, interval) in intervals.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "🚨🚨🚨 \(medicine.name) 🚨🚨🚨"
            content.body = "💊 薬を飲んでください！バックグラウンド通知\(index + 1)回目"
            content.sound = index < 3 ? .defaultCritical : .default
            content.badge = NSNumber(value: notificationCount + index + 1)
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(interval), repeats: false)
            let request = UNNotificationRequest(
                identifier: "background_urgent_\(index)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
        
        // 追加の通知（より長い間隔で）
        for i in 11...30 {
            let content = UNMutableNotificationContent()
            content.title = "📱 \(medicine.name) - 継続アラート"
            content.body = "薬の服用確認をお願いします"
            content.sound = .default
            content.badge = NSNumber(value: notificationCount + i)
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(i * 60), repeats: false) // 1分間隔
            let request = UNNotificationRequest(
                identifier: "background_extended_\(i)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    // バッジ更新（より効率的に）
    private func startBadgeUpdates() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            guard self.isNotifying else { return }
            
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = self.notificationCount
            }
        }
    }
    
    func stopContinuousNotifications() {
        print("🛑 全ての通知を停止します")
        isNotifying = false
        showAlert = false
        currentMedicine = nil
        notificationIntensityLevel = 1
        
        // 全てのタイマーを停止
        continuousTimer?.invalidate()
        continuousTimer = nil
        systemSoundTimer?.invalidate()
        systemSoundTimer = nil
        hapticTimer?.invalidate()
        hapticTimer = nil
        flashTimer?.invalidate()
        flashTimer = nil
        notificationSequenceTimer?.invalidate()
        notificationSequenceTimer = nil
        
        // アラートを閉じる
        alertController?.dismiss(animated: true)
        alertController = nil
        
        // 通知とバッジをクリア
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // バックグラウンドタスクを終了
        endBackgroundTask()
        
        notificationCount = 0
    }
    
    // SwiftUIから呼び出すメソッド
    func medicineWasTaken() {
        print("✅ 薬を飲みました（写真撮影完了）")
        stopContinuousNotifications()
    }
    
    func snoozeNotification() {
        print("😴 スヌーズ選択（短時間後に再開）")
        showAlert = false
        
        // 20秒後に再表示（以前より短く）
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            if self.isNotifying, let medicine = self.currentMedicine {
                self.showSwiftUIAlert(for: medicine)
            }
        }
    }
    
    // 通常の定時通知
    func scheduleRegularNotifications(for medicines: [Medicine]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        for medicine in medicines where medicine.isActive {
            let content = UNMutableNotificationContent()
            content.title = "📅 お薬の時間"
            content.body = "\(medicine.name)を飲む時間です"
            content.sound = .default
            content.categoryIdentifier = "REGULAR_MEDICINE"
            
            var dateComponents = DateComponents()
            dateComponents.hour = medicine.hour
            dateComponents.minute = medicine.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "daily_medicine_\(medicine.id)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    // デバッグ用
    func testEmergencyNotification(for medicine: Medicine) {
        print("🧪 テスト用緊急通知開始")
        startContinuousNotifications(for: medicine)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // フォアグラウンドでも通知を表示
        completionHandler([.alert, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("通知がタップされました: \(response.notification.request.identifier)")
        
        // 通知から薬の情報を取得して処理
        if let medicineId = response.notification.request.content.userInfo["medicineId"] as? String {
            print("薬ID: \(medicineId) の通知がタップされました")
        }
        
        completionHandler()
    }
}
