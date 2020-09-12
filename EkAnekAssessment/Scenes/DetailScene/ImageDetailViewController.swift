//
//  ImageDetailViewController.swift
//  EkAnekAssessment
//
//  Created by Ankit Batra on 12/09/20.
//  Copyright © 2020 EkAnek. All rights reserved.
//

import UIKit

class ImageDetailViewController: UIViewController {

    var imageObj : ImageDataModel?

    @IBOutlet weak var detailImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.navigationItem.title = imageObj!.title ?? "No Title"
        if let cachedImage =  ImageDownloadManager.sharedInstance.imageCache.object(forKey: imageObj!.imageUrl().absoluteString as NSString)
        {
            detailImageView.image = cachedImage
        }
        else{
            //add to download queue with highest priority
            let downloader = DownloadOperation(url: imageObj!.imageUrl())
            downloader.queuePriority = .high
            downloader.completionBlock = {
                if downloader.isCancelled {
                    return
                }
                DispatchQueue.main.async {
                    //Also saving it to NSCache as requested.
                    do {
                        let manager = FileManager.default
                        let documents = try manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                        let destinationURL = documents.appendingPathComponent("\(self.imageObj!.imageId!)_\(self.imageObj!.secretId!)_m.jpg")
                        let imageDownloaded =  UIImage(contentsOfFile: destinationURL.path)!
                        self.detailImageView.image = imageDownloaded
                        ImageDownloadManager.sharedInstance.imageCache.setObject(imageDownloaded, forKey: self.imageObj!.imageUrl().absoluteString as NSString)
                    }
                    catch
                    {
                        NSLog("Error")
                    }
                    self.imageObj!.imageState = .Downloaded
                }
            }
            ImageDownloadManager.sharedInstance.downloadQueue.addOperation(downloader)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
