//
//  MedicineRegistrationView.swift
//  KIMERO_OKUSURI_CALENDAR
//
//  Created by clark on 2025/06/30.
//


import SwiftUI

struct MedicineRegistrationView: View {
    @EnvironmentObject private var medicineManager: MedicineManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @State private var showingAddMedicine = false
    
    var body: some View {
        NavigationView {
            VStack {
                if medicineManager.medicines.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "pills.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("登録されたお薬がありません")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("「+」ボタンからお薬を登録してください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(medicineManager.medicines) { medicine in
                            MedicineRowView(medicine: medicine)
                        }
                        .onDelete(perform: deleteMedicine)
                    }
                }
            }
            .navigationTitle("お薬登録")
            .navigationBarItems(trailing:
                Button(action: { showingAddMedicine = true }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingAddMedicine) {
                AddMedicineView()
            }
        }
    }
    
    private func deleteMedicine(offsets: IndexSet) {
        for index in offsets {
            let medicine = medicineManager.medicines[index]
            medicineManager.deleteMedicine(medicine)
        }
        // 通知を再スケジュール
        notificationManager.scheduleRegularNotifications(for: medicineManager.medicines)
    }
}

struct MedicineRowView: View {
    let medicine: Medicine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(medicine.name)
                .font(.headline)
            
            HStack {
                Text("服用時間: \(medicine.timeString)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if medicine.isActive {
                    Text("有効")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                } else {
                    Text("無効")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddMedicineView: View {
    @EnvironmentObject private var medicineManager: MedicineManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var medicineName = ""
    @State private var selectedHour = 8
    @State private var selectedMinute = 0
    @State private var isActive = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("お薬情報")) {
                    TextField("お薬の名前", text: $medicineName)
                    
                    Toggle("有効にする", isOn: $isActive)
                }
                
                Section(header: Text("服用時間")) {
                    HStack {
                        Text("時間")
                        Spacer()
                        Picker("時", selection: $selectedHour) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)時").tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100)
                        
                        Picker("分", selection: $selectedMinute) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)分").tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100)
                    }
                }
                
                Section {
                    HStack {
                        Text("設定時間")
                        Spacer()
                        Text(String(format: "%02d:%02d", selectedHour, selectedMinute))
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
            }
            .navigationTitle("お薬を追加")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveMedicine()
                }
                .disabled(medicineName.isEmpty)
            )
        }
    }
    
    private func saveMedicine() {
        let medicine = Medicine(
            name: medicineName,
            hour: selectedHour,
            minute: selectedMinute,
            isActive: isActive
        )
        
        medicineManager.addMedicine(medicine)
        
        // 通知をスケジュール
        notificationManager.scheduleRegularNotifications(for: medicineManager.medicines)
        
        presentationMode.wrappedValue.dismiss()
    }
}