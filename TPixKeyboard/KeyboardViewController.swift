//
//  KeyboardViewController.swift
//  TPixKeyboard
//
//  Created by Ayo Shafau on 11/28/24.
//

import UIKit
import CoreData

class KeyboardViewController: UIInputViewController {
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 4
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        return button
    }()
    
    private var storedImages: [(image: UIImage, daysLeft: Int, uuid: String)] = []
    private let appGroupID = "group.com.TpixApp.shared" // Replace with your app group ID
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupAddButton()
        loadStoredImages()
        print("Keyboard loaded")
    }
    
    private func setupCollectionView() {
        view.addSubview(collectionView)
        collectionView.frame = view.bounds
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.identifier)
    }
    
    private func setupAddButton() {
        view.addSubview(addButton)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 80),
            addButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        addButton.addTarget(self, action: #selector(addImageFromClipboard), for: .touchUpInside)
    }
    
    private func loadStoredImages() {
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            print("Failed to access app group container.")
            return
        }

        let context = PersistenceController.shared.context
        
        let fetchRequest: NSFetchRequest<StoredImage> = StoredImage.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "expirationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let results = try context.fetch(fetchRequest)
            storedImages = results.compactMap { storedImage in
                if let data = storedImage.imageData,
                   let uiImage = UIImage(data: data),
                   let expirationDate = storedImage.expirationDate {
                    
                    let daysLeft = max(0, Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0)
                    return (image: uiImage, daysLeft: daysLeft, uuid: storedImage.uuid ?? "")
                }
                return nil
            }
            collectionView.reloadData()
        } catch {
            print("Failed to fetch stored images: \(error)")
        }
    }
    
    private func copyImageToClipboard(image: UIImage, uuid: String) {
        UIPasteboard.general.image = image
        resetExpiration(for: uuid)
        notifyMainApp()
        showToast(message: "Image copied to clipboard!")
    }
    
    @objc private func addImageFromClipboard() {
        guard let clipboardImage = UIPasteboard.general.image else {
            showToast(message: "No image in clipboard!")
            return
        }
        let sharedDefaults = UserDefaults(suiteName: appGroupID)
        let context = PersistenceController.shared.context
        let uuid = UUID().uuidString
        let expirationLength = sharedDefaults?.integer(forKey: "expirationLength") ?? 30
        let expirationDate = Calendar.current.date(byAdding: .day, value: expirationLength, to: Date())
        
        let newImage = StoredImage(context: context)
        newImage.uuid = uuid
        newImage.imageData = clipboardImage.pngData()
        newImage.expirationDate = expirationDate
        
        do {
            try context.save()
            loadStoredImages()
            showToast(message: "Image added from clipboard!")
        } catch {
            print("Failed to save new image: \(error)")
        }
    }
    
    private func notifyMainApp() {
        let sharedDefaults = UserDefaults(suiteName: appGroupID)
        sharedDefaults?.setValue(true, forKey: "needsRefresh")
        sharedDefaults?.synchronize()
    }
    
    private func resetExpiration(for uuid: String) {
        let context = PersistenceController.shared.context
        let fetchRequest: NSFetchRequest<StoredImage> = StoredImage.fetchRequest()
        let sharedDefaults = UserDefaults(suiteName: appGroupID)

        do {
            let results = try context.fetch(fetchRequest)
            if let storedImage = results.first(where: { $0.uuid == uuid }) {
                let expirationLength = sharedDefaults?.integer(forKey: "expirationLength") ?? 30
                storedImage.expirationDate = Calendar.current.date(byAdding: .day, value: expirationLength, to: Date())
                notifyMainApp()
                try context.save()
                loadStoredImages()
            }
        } catch {
            print("Failed to reset expiration: \(error)")
        }
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension KeyboardViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return storedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.identifier, for: indexPath) as? ImageCell else {
            fatalError("Failed to dequeue ImageCell.")
        }
        
        let imageInfo = storedImages[indexPath.item]
        cell.configure(with: imageInfo.image, daysLeft: imageInfo.daysLeft, uuid: imageInfo.uuid)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let imageInfo = storedImages[indexPath.item]
        copyImageToClipboard(image: imageInfo.image, uuid: imageInfo.uuid)
    }
    
    private func showToast(message: String, duration: TimeInterval = 2.0) {
        let toast = ToastView(message: message)
        toast.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(toast)

        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            toast.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8),
        ])

        UIView.animate(withDuration: 0.3, animations: {
            toast.alpha = 1
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                UIView.animate(withDuration: 0.3, animations: {
                    toast.alpha = 0
                }) { _ in
                    toast.removeFromSuperview()
                }
            }
        }
    }

}

// MARK: - Custom UICollectionViewCell
class ImageCell: UICollectionViewCell {
    static let identifier = "ImageCell"
    
    private let imageView = UIImageView()
    private let daysLeftLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(daysLeftLabel)
        
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8 // Rounded corners
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        daysLeftLabel.font = .systemFont(ofSize: 12, weight: .medium)
        daysLeftLabel.textAlignment = .center
        daysLeftLabel.textColor = .darkGray
        daysLeftLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Image takes 70% of the cell height with padding
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            imageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.7),
            
            // Label below the image with padding
            daysLeftLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            daysLeftLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            daysLeftLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            daysLeftLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with image: UIImage, daysLeft: Int, uuid: String) {
        imageView.image = image
        daysLeftLabel.text = "\(daysLeft)"
        daysLeftLabel.textColor = daysLeft > 1 ? .darkGray : .red
    }
}

class ToastView: UIView {
    private let label = UILabel()

    init(message: String) {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        self.layer.cornerRadius = 8

        label.text = message
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0

        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
