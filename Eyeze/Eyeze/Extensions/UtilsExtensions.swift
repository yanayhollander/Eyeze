//
//  UtilsExtensions.swift
//  Eyeze
//
//  Created by Yanay Hollander on 09/09/2024.
//

import UIKit

extension UIImage {
    func toBase64String() -> String? {
        guard let imageData = self.jpegData(compressionQuality: 1.0) else {
            fatalError("Failed to convert image to JPEG data")
        }
        
        let mediaType = "image/jpeg"
        let dataUrlString = "data:\(mediaType);base64,\(imageData.base64EncodedString())"
        return dataUrlString
    }
}

extension UIImage {
    convenience init?(base64String: String) {
        let components = base64String.components(separatedBy: ",")
        guard components.count == 2, let data = Data(base64Encoded: components[1]) else {
            return nil
        }
        self.init(data: data)
    }
}
