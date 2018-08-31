//
//  ImageGalleryViewController.swift
//  ImageGallery
//
//  Created by Evgeniy Ziangirov on 18/07/2018.
//  Copyright © 2018 Evgeniy Ziangirov. All rights reserved.
//

import UIKit

var imageCache = [URL: UIImage]() //wrong way %)

class ImageGalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDropDelegate, UICollectionViewDragDelegate, UIDropInteractionDelegate, UIPopoverPresentationControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupNavigationController()

        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.leftBarButtonItem = doneButton
        navigationItem.rightBarButtonItems?.append(addTrashButton())

        // TODO: - URLCache
        // TODO: - Run on an actual device
        // TODO: - Camera
        // TODO: - StopBackgroundLoading
        // TODO: - StoryBoard
        // TODO: - AddCommentsAndMarks
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Document Info" {
            if let destination = segue.destination.contents as? DocumentInfoViewController {
                document?.thumbnail = view.snapshot
                destination.document = document
                if let ppc = destination.popoverPresentationController {
                    ppc.delegate = self
                }
            }
        } else if segue.identifier == "Embed Document Info" {
            embeddedDocInfo = segue.destination.contents as? DocumentInfoViewController
        }
    }
    
    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    @IBAction func close(bySegue: UIStoryboardSegue) {
        done()
    }
    
    private var embeddedDocInfo: DocumentInfoViewController?
    @IBOutlet weak var embeddedDocInfoWidth: NSLayoutConstraint!
    @IBOutlet weak var embeddedDocInfoHeight: NSLayoutConstraint!
    
    // MARK: - ImageGallery Model
    
    var gallery: ImageGallery? {
        didSet {
            if gallery == nil { gallery = ImageGallery() }
            imageGalleryCollectionView?.reloadData()
        }
    }
    
    private let trashBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .trash, target: nil, action: nil)
    }()
    
    private var flowLayout: UICollectionViewFlowLayout? {
        return imageGalleryCollectionView?.collectionViewLayout as? UICollectionViewFlowLayout
    }
    
    private lazy var maximumCellWidth: CGFloat = {
        return defaultCellWidth / 2 - 1
    }()
    
    private lazy var minimumCellWidth: CGFloat = {
        return defaultCellWidth / 3 - 1
    }()
    
    private lazy var imageCellScale: CGFloat = {
        return 1.0
    }()
    
    private lazy var defaultCellWidth: CGFloat = {
        return view.bounds.width
    }()
    
    // MARK: - UICollectionView
    
    @IBOutlet weak var imageGalleryCollectionView: UICollectionView!
    
    private func setupCollectionView() {
        imageGalleryCollectionView?.delegate = self
        imageGalleryCollectionView?.dataSource = self
        imageGalleryCollectionView?.dragDelegate = self
        imageGalleryCollectionView?.dropDelegate = self
        imageGalleryCollectionView?.dragInteractionEnabled = true
        
        imageGalleryCollectionView?.backgroundColor = .lead
        
        imageGalleryCollectionView?.register(ImageCell.self, forCellWithReuseIdentifier: "cellId")
        imageGalleryCollectionView?.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(scaleCell(_:))))
    }
    
    private func setupNavigationController() {
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.alpha = 0
    }
    
    private func addTrashButton() -> UIBarButtonItem {
        navigationController?.navigationBar.addInteraction(UIDropInteraction(delegate: self))
        return trashBarButtonItem
    }
    
    @objc private func scaleCell(_ reconizer: UIPinchGestureRecognizer) {
        guard minimumCellWidth <= maximumCellWidth else { return }
        switch reconizer.state {
        case .changed, .ended:
            let scaledWidth = imageCellScale * reconizer.scale
            if (minimumCellWidth...maximumCellWidth).contains(minimumCellWidth * scaledWidth) {
                imageCellScale = scaledWidth
                flowLayout?.invalidateLayout()
            }
            reconizer.scale = 1
        default:
            break
        }
    }
    
    // MARK: - Document Handling
    
    var document: ImageGalleryDocument?
    
    @objc private func documentChanged() {
        document?.gallery = gallery
        if document?.gallery != nil {
            document?.updateChangeCount(.done)
        }
    }
    
    @objc private func done() {
        if let observer = imageCellObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        if document?.gallery != nil {
            document?.thumbnail = imageGalleryCollectionView.snapshot
        }
        presentingViewController?.dismiss(animated: true) {
            self.document?.close { success in
                if let observer = self.documentObserver {
                    NotificationCenter.default.removeObserver(observer)
                }
            }
        }
    }
 
    private var documentObserver: NSObjectProtocol?
    private var imageCellObserver: NSObjectProtocol?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if document?.documentState != .normal {
            documentObserver = NotificationCenter.default.addObserver(
                forName: UIDocument.stateChangedNotification,
                object: document,
                queue: OperationQueue.main,
                using: { notification in
                    print("documentState changed to \(self.document!.documentState)")
                    if self.document!.documentState == .normal, let docInfoVC = self.embeddedDocInfo {
                        docInfoVC.document = self.document
                        self.embeddedDocInfoWidth.constant = docInfoVC.preferredContentSize.width
                        self.embeddedDocInfoHeight.constant = docInfoVC.preferredContentSize.height
                    }
            })
            document?.open { success in
                if success {
                    self.title = self.document?.localizedName
                    self.gallery = self.document?.gallery
                    self.imageCellObserver = NotificationCenter.default.addObserver(
                        forName: .ImageCellDidChange,
                        object: self.transitioningDelegate,
                        queue: OperationQueue.main,
                        using: { notification in
                            self.documentChanged()
                    })
                }
            }
        }
    }
    
    // MARK: - UIContentContainer
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        defaultCellWidth = view.bounds.height
        flowLayout?.invalidateLayout()
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return gallery?.images.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath)
        if let imageCell = cell as? ImageCell {
            let image = gallery?.images[indexPath.item]
            imageCell.imageURL = image?.imagePath
            if let url = imageCell.imageURL {
                if let image = imageCache[url] {
                    imageCell.image = image
                } else {
                    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                        let urlContents = try? Data(contentsOf: url)
                        DispatchQueue.main.async {
                            guard url == imageCell.imageURL else { return }
                            
                            if let imageData = urlContents {
                                if let image = UIImage(data: imageData) {
                                    imageCell.image = image
                                    imageCache[url] = image
                                }
                            } else {
                                imageCell.image = nil
                                imageCell.fetchFailed = true
                                self?.presentBadURLWarning(for: url)
                                collectionView.performBatchUpdates({
                                    self?.gallery?.images.remove(at: indexPath.item)
                                    collectionView.deleteItems(at: [indexPath])
                                })
                            }
                        }
                    }
                }
            }
        }
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView,
                                 didSelectItemAt indexPath: IndexPath) {
        let detailVC = ImageViewController()
        let item = gallery?.images[indexPath.item]
        if let image = (collectionView.cellForItem(at: indexPath) as! ImageCell).image {
            detailVC.image = image
        } else {
            detailVC.imageURL = item?.imagePath
        }
        navigationController?.pushViewController(detailVC, animated: false)
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let cellWidth = Double((defaultCellWidth / 3 - 1) * imageCellScale)
        
        return CGSize(width: cellWidth, height: cellWidth / gallery!.images[indexPath.item].aspectRatio)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    // MARK: - UICollectionViewDragDelegate
    
    func collectionView(_ collectionView: UICollectionView,
                        itemsForBeginning session: UIDragSession,
                        at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        itemsForAddingTo session: UIDragSession,
                        at indexPath: IndexPath,
                        point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        if let imageURL = (imageGalleryCollectionView?.cellForItem(at: indexPath) as? ImageCell)?.imageURL as NSURL? {
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: imageURL))
            dragItem.localObject = imageURL
            return [dragItem]
        } else {
            return []
        }
    }
    
    // MARK: - UICollectionViewDropDelegate
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        let validValues = [
            session.canLoadObjects(ofClass: NSURL.self),
            session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
        ]
        return collectionView.hasActiveDrag ? validValues[0] : validValues[1]
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        dropSessionDidUpdate session: UIDropSession,
                        withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        performDropWith coordinator: UICollectionViewDropCoordinator
        ) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath {
                if let url = item.dragItem.localObject as? URL {
                    collectionView.performBatchUpdates({
                        let aspectRatio = gallery?.images[sourceIndexPath.item].aspectRatio
                        let image = ImageGallery.Image(imagePath: url, aspectRatio: aspectRatio ?? 1)
                        gallery?.images.remove(at: sourceIndexPath.item)
                        gallery?.images.insert(image, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                    })
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            } else {
                let placeholderContext = coordinator.drop(
                    item.dragItem,
                    to: UICollectionViewDropPlaceholder(
                        insertionIndexPath: destinationIndexPath,
                        reuseIdentifier: "cellId"
                    )
                )
                var aspectRatio = Double()
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { provider, error in
                    DispatchQueue.main.async {
                        if let image = provider as? UIImage {
                            aspectRatio = Double(image.size.aspectRatio)
                        }
                    }
                }
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { (provider, err) in
                    DispatchQueue.main.async {
                        if let imageURL = (provider as? URL)?.embeddedImageURL {
                            placeholderContext.commitInsertion(dataSourceUpdates: { insertionIndexPath in
                                let image = ImageGallery.Image(imagePath: imageURL, aspectRatio: aspectRatio)
                                self.gallery?.images.insert(image, at: insertionIndexPath.item)
                            })
                        } else {
                            placeholderContext.deletePlaceholder()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - UIDropInteractionDelegate
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: URL.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        if let view = trashBarButtonItem.value(forKey: "view") as? UIView {
            let dropPoint = session.location(in: view)
            if view.frame.contains(dropPoint) {
                return UIDropProposal(operation: .move)
            }
        }
        return UIDropProposal(operation: .cancel)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        guard let item = session.items.first else { return }
        guard let droppedImageURL = item.localObject as? URL else { return }
        var index: Int = -1
        gallery?.images.indices.forEach {
            if gallery?.images[$0].imagePath == droppedImageURL {
                index = $0
            }
        }
        imageGalleryCollectionView?.performBatchUpdates({
            let indexPath = IndexPath(item: index, section: 0)
            gallery?.images.remove(at: index)
            imageGalleryCollectionView?.deleteItems(at: [indexPath])
        })
    }
    
    // MARK: - Bad URL Warnings
    
    private func presentBadURLWarning(for: URL?) {
        if !subpressBadURLWarnings {
            let alert = UIAlertController(
                title: "Image Transfer Failed",
                message: "Couldn't transfer the dropped image from its source.\nShow this warning in the future?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(
                title: "Keep Warning",
                style: .default
            ))
            
            alert.addAction(UIAlertAction(
                title: "Stop Warning",
                style: .destructive,
                handler: { action in
                    self.subpressBadURLWarnings = true
            }
            ))
            
            present(alert, animated: true)
        }
    }
    
    private var subpressBadURLWarnings = false
    
}
