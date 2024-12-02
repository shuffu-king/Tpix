//
//  ContentView.swift
//  Tpix
//
//  Created by Ayo Shafau on 11/28/24.
//

import SwiftUI
import UIKit

struct ContentView: View {
    
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var showToast = false   // State for the toast notification
    @State private var toastMessage = ""   // Message to show in the toast
    @State private var showingInstructions = false // Tracks the display state of the instructions modal

    let columns = [
        GridItem(.adaptive(minimum: 100))  // Adjust the minimum size as needed
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Library")
                    .font(.headline)
                
                // Button to add image from clipboard
                Button(action: addImageFromClipboard) {
                    Text("Add Copied Image")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.bottom)
                
                // Display stored images
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(clipboardManager.storedImages, id: \.uuid) { (image, daysLeft, uuid) in
                            VStack {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)  // Adjust height as needed
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .gesture(
                                        TapGesture()
                                            .onEnded {
                                                clipboardManager.copyImageToClipboard(image, uuid: uuid)
                                                toastMessage = "Image copied to clipboard!"
                                                showToast = true
                                            }
                                            .exclusively(before: LongPressGesture(minimumDuration: 0.8)
                                                .onEnded { _ in
                                                    showDeleteConfirmation(for: image)
                                                }
                                            )
                                    )
                                
                                // Display days left
                                Text("\(daysLeft) days left")
                                    .font(.caption)
                                    .foregroundColor(daysLeft <= 7 ? .red : .gray)
                            }
                        }
                    }
                    .padding()
                }
                .toast(isPresented: $showToast, message: toastMessage)  // Call the toast modifier here
                // Toast on image save
                .onAppear {
                    let sharedDefaults = UserDefaults(suiteName: "group.com.TpixApp.shared")
                    if sharedDefaults?.bool(forKey: "needsRefresh") == true {
                        clipboardManager.refreshImages() // Reload data in the main app
                        sharedDefaults?.setValue(false, forKey: "needsRefresh") // Reset flag
                        sharedDefaults?.synchronize() // Ensure changes propagate
                    }
                    clipboardManager.onImageSaved = {
                        toastMessage = "Image added successfully!"
                        showToast = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: clipboardManager.fetchStoredImages) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh Images")
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingInstructions.toggle()
                    }) {
                        Image(systemName: "questionmark.circle")
                            .accessibilityLabel("Instructions")
                    }
                }
            }
            .sheet(isPresented: $showingInstructions) {
                InstructionsView()
            }
        }
    }
    
    // Show delete confirmation alert for a specific image
    private func showDeleteConfirmation(for image: UIImage) {
        let confirmationAlert = UIAlertController(title: "Delete Image",
                                                  message: "Are you sure you want to delete this image?",
                                                  preferredStyle: .alert)
        confirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        confirmationAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            clipboardManager.deleteImage(image)
            toastMessage = "Image deleted successfully!"
            showToast = true  // Show toast notification
        }))
        
        if let window = UIApplication.shared.windows.first {
            window.rootViewController?.present(confirmationAlert, animated: true, completion: nil)
        }
    }
    
    // Function to add image from clipboard if available
    private func addImageFromClipboard() {
        if let clipboardImage = UIPasteboard.general.image {
            clipboardManager.saveImage(clipboardImage)
            toastMessage = "Image added successfully!"
            showToast = true
        } else {
            print("No image found in clipboard")
        }
    }
}
