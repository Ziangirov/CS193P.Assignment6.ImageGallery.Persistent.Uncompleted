//
//  ImageCell.swift
//  ImageGallery
//
//  Created by Evgeniy Ziangirov on 18/07/2018.
//  Copyright © 2018 Evgeniy Ziangirov. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let ImageCellDidChange = Notification.Name("ImageCellDidChange")
}

class BaseCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
//        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() { }
}

final class ImageCell: BaseCell {
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.text = "Couldn't download image"
        label.textAlignment = .center
        label.textColor = .red
        return label
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        return imageView
    }()
    
    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.hidesWhenStopped = true
        spinner.style = .white
        return spinner
    }()
    
    var fetchFailed = false { didSet { addErrorLabel(); spinner.stopAnimating() } }
    
    var imageURL: URL? {
        didSet {
            spinner.startAnimating()
            NotificationCenter.default.post(name: .ImageCellDidChange, object: self)
        }
    }
    
    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            spinner.stopAnimating()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        errorLabel.removeFromSuperview()
        image = nil
        imageURL = nil
        spinner.stopAnimating()
    }
    
    override func setupViews() {
        super.setupViews()
        contentView.addSubview(spinner)
        contentView.addSubview(imageView)
        contentView.activateConstraints(withVisualFormat: "H:|-2-[v0]-2-|", for: imageView)
        contentView.activateConstraints(withVisualFormat: "V:|-2-[v0]-2-|", for: imageView)
        contentView.activateConstraints(withVisualFormat: "H:|-[v0]-|", for: spinner)
        contentView.activateConstraints(withVisualFormat: "V:|-[v0]-|", for: spinner)
    }
    
    private func addErrorLabel() {
        contentView.addSubview(errorLabel)
        contentView.activateConstraints(withVisualFormat: "H:|-[v0]-|", for: errorLabel)
        contentView.activateConstraints(withVisualFormat: "V:|-[v0]-|", for: errorLabel)
    }
    
}
