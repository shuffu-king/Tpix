//
//  SettingsView.swift
//  Tpix
//
//  Created by Ayo Shafau on 11/28/24.
//

import SwiftUI

struct SettingsView: View {
    @State private var expirationLength: Int = 30
    let sharedDefaults = UserDefaults(suiteName: "group.com.TpixApp.shared")
    
    var body: some View {
        Form {
            Section(header: Text("Expiration Settings")) {
                Stepper(value: $expirationLength, in: 1...365) {
                    Text("Length: \(expirationLength) days")
                }
                .onChange(of: expirationLength) { newValue in
                    sharedDefaults?.set(newValue, forKey: "expirationLength")
                    sharedDefaults?.synchronize() // Ensure data propagates to the keyboard app
                    print(expirationLength)
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            expirationLength = sharedDefaults?.integer(forKey: "expirationLength") ?? 30
            sharedDefaults?.set(expirationLength, forKey: "expirationLength")
            sharedDefaults?.synchronize()
        }
    }
}

#Preview {
    SettingsView()
}
