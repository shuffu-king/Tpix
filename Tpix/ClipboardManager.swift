//
//  ClipboardManager.swift
//  Tpix
//
//  Created by Ayo Shafau on 11/28/24.
//

import CoreData
import UIKit
import SwiftData

class ClipboardManager: ObservableObject {
    
    @Published var storedImages: [(image: UIImage, daysLeft: Int, uuid: String)] = []
    
    let appGroupID = "group.com.TpixApp.shared"  // Replace with your actual App Group ID
    var onImageSaved: (() -> Void)?
    
    let sharedDefaults = UserDefaults(suiteName: "group.com.TpixApp.shared")

    private let context = PersistenceController.shared.context
    
    init(onImageSaved: (() -> Void)? = nil) {
        self.onImageSaved = onImageSaved
        fetchStoredImages()
        removeExpiredImages()
    }
    
    // Fetch stored images from Core Data
    func fetchStoredImages() {
        context.perform {
                let fetchRequest: NSFetchRequest<StoredImage> = StoredImage.fetchRequest()
                let sortDescriptor = NSSortDescriptor(key: "expirationDate", ascending: false)
                fetchRequest.sortDescriptors = [sortDescriptor]
                
                do {
                    let results = try self.context.fetch(fetchRequest)
                    DispatchQueue.main.async {
                        self.storedImages = results.compactMap { storedImage in
                            guard
                                let data = storedImage.imageData,
                                let uiImage = UIImage(data: data),
                                let expirationDate = storedImage.expirationDate
                            else { return nil }
                            let daysLeft = max(0, Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0)
                            return (image: uiImage, daysLeft: daysLeft, uuid: storedImage.uuid ?? "")
                        }
                    }
                } catch {
                    print("Failed to fetch stored images: \(error)")
                }
            }
    }
    
    // Calculate remaining days until expiration
    private func calculateDaysLeft(from expirationDate: Date?) -> Int {
        guard let expirationDate = expirationDate else { return 0 }
        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
        return max(0, daysLeft)
    }
    
    func saveImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else { return }
        
        let newStoredImage = StoredImage(context: context)
        newStoredImage.imageData = imageData
        
        // Get expiration length from UserDefaults or fallback to a default value
        let expirationLength = sharedDefaults?.integer(forKey: "expirationLength") ?? 30
        let daysToAdd = expirationLength > 0 ? expirationLength : 30
        
        newStoredImage.expirationDate = Calendar.current.date(byAdding: .day, value: daysToAdd, to: Date())
        newStoredImage.uuid = UUID().uuidString  // Assign a new UUID
        
        do {
            try context.save()
            storedImages.append((image: image, daysLeft: expirationLength, uuid: newStoredImage.uuid!))  // Assume 30 days for demo
            onImageSaved?()  // Trigger the onImageSaved closure to notify ContentView
            fetchStoredImages()  // Refresh images after saving
        } catch {
            print("Failed to save image: \(error)")
        }
    }
    
    // Delete a specific image
    func deleteImage(_ image: UIImage) {
        let fetchRequest: NSFetchRequest<StoredImage> = StoredImage.fetchRequest()
        do {
            let results = try context.fetch(fetchRequest)
            if let storedImage = results.first(where: { storedImage in
                guard let data = storedImage.imageData else { return false }
                return UIImage(data: data)?.pngData() == image.pngData()
            }) {
                context.delete(storedImage)  // Delete the matching image
                try context.save()
                fetchStoredImages()  // Refresh the stored images list
            }
        } catch {
            print("Failed to delete image: \(error)")
        }    }
    
    // Remove all expired images
    func removeExpiredImages() {
        let fetchRequest: NSFetchRequest<StoredImage> = StoredImage.fetchRequest()
        do {
            let results = try context.fetch(fetchRequest)
            for storedImage in results {
                if let expirationDate = storedImage.expirationDate, expirationDate < Date() {
                    context.delete(storedImage)
                }
            }
            try context.save()
            fetchStoredImages()
        } catch {
            print("Failed to remove expired images: \(error)")
        }
    }
    
    // Reset the expiration for a given image
    func resetExpiration(for uuid: String) {
        let fetchRequest: NSFetchRequest<StoredImage> = StoredImage.fetchRequest()
        
        do {
            let results = try context.fetch(fetchRequest)
            
            // Find the matching stored image using UUID
            if let storedImage = results.first(where: { $0.uuid == uuid }) {
                //                storedImage.expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())
                
                // Get expiration length from UserDefaults or fallback to a default value
                let expirationLength = sharedDefaults?.integer(forKey: "expirationLength") ?? 30
                let daysToAdd = expirationLength > 0 ? expirationLength : 30
                storedImage.expirationDate = Calendar.current.date(byAdding: .day, value: daysToAdd, to: Date())
                
                try context.save()
                fetchStoredImages()
                
                print("Expiration reset successfully for the image.")
            } else {
                print("No matching stored image found for the provided UUID.")
            }
        } catch {
            print("Failed to reset expiration: \(error)")
        }
    }
    
    func copyImageToClipboard(_ image: UIImage, uuid: String) -> Bool {
        UIPasteboard.general.image = image  // Copy image to clipboard
        resetExpiration(for: uuid)  // Reset expiration timer
        return UIPasteboard.general.image == image  // Return success to indicate copy was successful
    }
    
    func refreshImages() {
        let context = PersistenceController.shared.context
        do {
            try context.save()
        } catch {
            print("Failed to refresh images: \(error.localizedDescription)")
        }
    }
}

extension Date {
    func daysUntil() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: self)
        return components.day ?? 0
    }
}
