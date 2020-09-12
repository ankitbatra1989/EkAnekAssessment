//
//  ImageDataModel.swift
//  EkAnekAssessment
//
//  Created by Ankit Batra on 12/09/20.
//  Copyright © 2020 EkAnek. All rights reserved.
//

import Foundation
import UIKit

enum ImageDownloadState {
    case New, Downloaded, Failed
}
class ImageDataModel{

    //MARK: Properties
    var title : String?
    var farmId : String?
    var imageId : String?
    var serverId : Int?
    var secretId : String?
    var imageState = ImageDownloadState.New
    var image : UIImage = UIImage(named: "placeholder")!

    //MARK: Initialization
    init?(_ title : String, farmId : Int, imageId:String, serverId:Int, secretId:String) {

        guard !imageId.isEmpty && !secretId.isEmpty else {
            return nil
        }
        self.title = title
        self.farmId = "farm\(farmId)"
        self.imageId = imageId
        self.serverId = serverId
        self.secretId = secretId
    }
}

extension ImageDataModel
{
    func imageUrl() -> URL
    {
        return URL(string: "https://\(self.farmId!).staticflickr.com/\(self.serverId!)/\(self.imageId!)_\(self.secretId!)_m.jpg")!
    }
    
    func thumbImageUrl() -> URL
    {
        return URL(string: "https://\(self.farmId!).staticflickr.com/\(self.serverId!)/\(self.imageId!)_\(self.secretId!)_s.jpg")!
    }
}
