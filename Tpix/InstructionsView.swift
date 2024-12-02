//
//  InstructionsView.swift
//  Tpix
//
//  Created by Ayo Shafau on 12/2/24.
//

import SwiftUI

struct InstructionsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("How to Use the App")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    // Toolbar Button Explanation
                    Text("**Toolbar Buttons**")
                        .font(.title2)
                        .padding(.top, 16)
                    
                    Text("1. **Gear Icon**: Opens the app's settings, where you can manage preferences like expiration days and more.")
                    Text("2. **Refresh Icon**: Fetches the latest stored images from your shared directory.")
                    
                    // General Usage Instructions
                    Text("**General Usage Instructions**")
                        .font(.title2)
                        .padding(.top, 16)
                    
                    Text("1. **Add Images**: Copy an image to your clipboard, then open the app or use the keyboard extension to add it.")
                    Text("2. **Manage Images**: Tap an image to copy it to the clipboard. This also resets its expiration timer.")
                    Text("3. **Expiration Timer**: Choose the number of days for images to remain in storage. When you copy an image, its timer resets.")
                    Text("4. **Refresh Images**: Use the refresh button to fetch the latest images and ensure everything is up to date.")
                }
                .padding()
            }
            .navigationBarTitle("Instructions", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        // Close the modal
                        if let window = UIApplication.shared.windows.first {
                            window.rootViewController?.dismiss(animated: true)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    InstructionsView()
}
