//
//  NetworkManager.swift
//  EkAnekAssessment
//
//  Created by Ankit Batra on 12/09/20.
//  Copyright © 2020 EkAnek. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

class NetworkManager: NSObject {
    
    static let sharedInstance = NetworkManager()
    
    fileprivate override init()
    {
        super.init()
    }
    

    func searchFlickrForImagesWith(keyword keywordText:String ,imagesPerPage limit:Int, andPageNumber page:Int, completionClosure: @escaping ([ImageDataModel])->())
    {
        let searchUrl = URL(string: "https://api.flickr.com/services/rest/?method=flickr.photos.search&format=json&nojsoncallback=1")
        let params : [String:String] = ["api_key" : "7309810eb979d515e18829505e627bd8",
                                        "text" : keywordText,
                                        "per_page" : "\(limit)",
                                        "page" : "\(page)"]
            _ = Alamofire.request(searchUrl!, parameters: params, encoding: URLEncoding.default).responseJSON
                { (response) in
            if let data  = response.data
            {
                do
                {
                    let result = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
                    let responseDict = result as! [String:AnyObject]
                    print("Response : \(responseDict)")
                    if (responseDict["stat"] as! String) != "fail"
                    {
                        let photosDictionary = responseDict["photos"] as! [String:AnyObject]
                        let photosArray = photosDictionary["photo"] as! [AnyObject]
                        var modelArray : [ImageDataModel] = []
                        for item in photosArray
                        {
                            let photoDict = item as! [String:Any]
                            let title = photoDict["title"] as? String ?? "No Title"
                            let farm = (photoDict["farm"] as! NSNumber).intValue
                            let server = (photoDict["server"] as! NSString).integerValue
                            let imageId = photoDict["id"] as! String
                            let secretId = photoDict["secret"] as! String
                            let imageModel = ImageDataModel(title, farmId: farm, imageId: imageId, serverId:server, secretId:secretId)!
                            modelArray.append(imageModel)
                        }
                        completionClosure(modelArray)

                    }
                }
                catch
                {
                    print("Error serializing")
                }
            }
        }
    }
}
