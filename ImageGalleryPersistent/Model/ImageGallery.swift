//
//  ImageGalleryModel.swift
//  ImageGallery
//
//  Created by Evgeniy Ziangirov on 31/07/2018.
//  Copyright © 2018 Evgeniy Ziangirov. All rights reserved.
//

import UIKit

struct ImageGallery: Codable {
    struct Image: Codable {
        var imagePath: URL?
        var aspectRatio: Double
        
        init(imagePath: URL, aspectRatio: Double) {
            self.imagePath = imagePath
            self.aspectRatio = aspectRatio
        }

        private enum CodingKeys: String, CodingKey {
            case imagePath = "image_path"
            case aspectRatio = "aspect_ratio"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            imagePath = try container.decode(URL?.self, forKey: .imagePath)
            aspectRatio = try container.decode(Double.self, forKey: .aspectRatio)
        }
    }
    
    let identifier: String
    
    var images: [Image]
    var title: String
    
    init() {
        identifier = UUID().uuidString
        images = [Image]()
        title = String()
    }
    
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    
    init?(json: Data) {
        if let newValue = try? JSONDecoder().decode(ImageGallery.self, from: json) {
            self = newValue
        } else {
            return nil
        }
    }
}

extension ImageGallery: Equatable {
    static func == (lhs: ImageGallery, rhs: ImageGallery) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

extension ImageGallery: Hashable {
    var hashValue: Int { return identifier.hashValue }
    init(images: [Image], title: String) {
        self.init()
    }
}

extension ImageGallery.Image: Equatable {
    static func ==(lhs: ImageGallery.Image, rhs: ImageGallery.Image) -> Bool {
        return lhs.imagePath == rhs.imagePath
    }
}

extension ImageGallery.Image: Hashable {
    var hashValue: Int { return imagePath?.hashValue ?? 0 }
}


