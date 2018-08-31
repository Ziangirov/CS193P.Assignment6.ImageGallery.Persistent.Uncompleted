//
//  ImageViewController.swift
//  ImageGallery
//
//  Created by Evgeniy Ziangirov on 20/07/2018.
//  Copyright © 2018 Evgeniy Ziangirov. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private let containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .lead
        return containerView
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
    
    var imageURL: URL? {
        didSet {
            if image == nil {
                fetchImage()
            }
        }
    }
    
    private var scrollView: UIScrollView! {
        didSet {
            scrollView.minimumZoomScale = 0.1
            scrollView.maximumZoomScale = 3.0
            scrollView.delegate = self
            scrollView.backgroundColor = .lead
            scrollView.addSubview(imageView)
            scrollView.zoomScale = 1.0
        }
    }
    
    private lazy var scrollViewHeight: NSLayoutConstraint! = {
        let scrollViewHeight = scrollView?.heightAnchor.constraint(equalToConstant: 100)
        scrollViewHeight?.priority = .defaultLow
        scrollViewHeight?.isActive = true
        return scrollViewHeight
    }()
    
    private lazy var scrollViewWidth: NSLayoutConstraint! = {
        let scrollViewWidth = scrollView?.widthAnchor.constraint(equalToConstant: 100)
        scrollViewWidth?.priority = .defaultLow
        scrollViewWidth?.isActive = true
        return scrollViewWidth
    }()
    
    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            setup()
            imageView.image = newValue
            spinner.stopAnimating()
            let size = newValue?.size ?? CGSize.zero
            scrollView?.contentSize = size
            imageView.frame = CGRect(origin: CGPoint.zero, size: size)
            scrollViewHeight?.constant = size.height
            scrollViewWidth?.constant = size.width
            
            if size.width > 0, size.height > 0 {
                scrollView?.zoomScale = max(
                    view.bounds.size.width / size.width,
                    view.bounds.size.height / size.height
                )
            }
            scrollView?.bringSubviewToFront(imageView)
        }
    }
    
    private func setup() {
        spinner.removeFromSuperview()
        imageView.removeFromSuperview()
        scrollView?.removeFromSuperview()
        containerView.removeFromSuperview()
        
        scrollView = UIScrollView()
        containerView.addSubview(scrollView)
        containerView.addSubview(spinner)
        view.addSubview(containerView)
        
        spinner.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        spinner.centerXAnchor.constraint(
            equalTo: containerView.centerXAnchor, constant: 0).isActive = true
        spinner.centerYAnchor.constraint(
            equalTo: containerView.centerYAnchor, constant: 0).isActive = true
        
        containerView.trailingAnchor.constraint(
            equalTo: view.trailingAnchor, constant: 0).isActive = true
        containerView.leadingAnchor.constraint(
            equalTo: view.leadingAnchor, constant: 0).isActive = true
        containerView.bottomAnchor.constraint(
            equalTo: view.bottomAnchor, constant: 0).isActive = true
        containerView.topAnchor.constraint(
            equalTo: view.topAnchor, constant: 0).isActive = true
        
        scrollView.contentLayoutGuide.trailingAnchor.constraint(
            greaterThanOrEqualTo: containerView.trailingAnchor, constant: 0).isActive = true
        scrollView.contentLayoutGuide.bottomAnchor.constraint(
            greaterThanOrEqualTo: containerView.bottomAnchor, constant: 0).isActive = true
        scrollView.contentLayoutGuide.leadingAnchor.constraint(
            greaterThanOrEqualTo: containerView.leadingAnchor, constant: 0).isActive = true
        scrollView.contentLayoutGuide.topAnchor.constraint(
            greaterThanOrEqualTo: containerView.topAnchor, constant: 0).isActive = true
        
        scrollView.centerXAnchor.constraint(
            equalTo: containerView.centerXAnchor, constant: 0).isActive = true
        scrollView.centerYAnchor.constraint(
            equalTo: containerView.centerYAnchor, constant: 0).isActive = true
    }
    
    private func fetchImage() {
        if let url = imageURL {
            spinner.startAnimating()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let urlContents = try? Data(contentsOf: url)
                DispatchQueue.main.async {
                    if let imageData = urlContents, url == self?.imageURL {
                        self?.image = UIImage(data: imageData)
                    }
                }
            }
        }
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewHeight.constant = scrollView.contentSize.height
        scrollViewWidth.constant = scrollView.contentSize.width
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
}
