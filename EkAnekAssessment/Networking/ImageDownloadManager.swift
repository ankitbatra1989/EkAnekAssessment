//
//  ImageDownloadManager.swift
//  EkAnekAssessment
//
//  Created by Ankit Batra on 12/09/20.
//  Copyright © 2020 EkAnek. All rights reserved.
//

import Foundation
import UIKit
class ImageDownloadManager: NSObject {

    static let sharedInstance = ImageDownloadManager()
    let imageCache = NSCache<NSString,UIImage>()
    fileprivate override init()
    {
        super.init()
    }
   
    lazy var downloadsInProgress = [NSIndexPath:Operation]()
    lazy var downloadQueue:OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Image Download queue"
        return queue
    }()
    
}
