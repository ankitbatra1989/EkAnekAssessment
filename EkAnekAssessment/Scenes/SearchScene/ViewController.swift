//
//  ViewController.swift
//  EkAnekAssessment
//
//  Created by Ankit Batra on 12/09/20.
//  Copyright © 2020 EkAnek. All rights reserved.
//

import UIKit
let kImagesPerPage = 50
let kFooterHeight = 50.0

class ViewController: UIViewController,UISearchControllerDelegate{
    
   @IBOutlet weak var searchResultsCollectionView: UICollectionView!
    var searchController : UISearchController!
    var searchResultsArray : [ImageDataModel]?
    let downloadManager = ImageDownloadManager.sharedInstance
    var pagenumber = 1
    var showLoader = false
    var isLoadingNewData = false
    var currentSearchBarText = ""
    var cellsPerRow = 3
    var tappedCellFrame : CGRect = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupSearchController()
        //
        self.navigationController?.delegate = self
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK :
    func setupSearchController()
    {
        searchController = UISearchController(searchResultsController:  nil)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = true
        navigationItem.titleView = searchController.searchBar
        definesPresentationContext = true
    }
    
    //MARK : IBAction
    @IBAction func optionsButtonTapped(_ sender: UIBarButtonItem)
    {
        //Show ActionSheet
        let actionSheet = UIAlertController.init(title: "Images per row", message: "", preferredStyle: .actionSheet)
        
        let twoAction = UIAlertAction(title: "two",
                                     style: .default, handler:{ (alertAction:UIAlertAction) in
                                       self.cellsPerRow = 2
                                        self.searchResultsCollectionView.reloadData()
        })
        
        let threeAction = UIAlertAction(title: "three",
                                         style: .default, handler:{ (alertAction:UIAlertAction) in
                                            self.cellsPerRow = 3
                                            self.searchResultsCollectionView.reloadData()
        })
        let fourAction = UIAlertAction(title: "four",
                                      style: .default, handler:{ (alertAction:UIAlertAction) in
                                        self.cellsPerRow = 4
                                        self.searchResultsCollectionView.reloadData()
        })

        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .destructive, handler:{ (alertAction:UIAlertAction) in
                                            
        })
        actionSheet.addAction(twoAction)
        actionSheet.addAction(threeAction)
        actionSheet.addAction(fourAction)
        actionSheet.addAction(cancelAction)
        self.present(actionSheet, animated: true, completion: nil)
    }
    //
    func getDataFromFlickr(forSearchText searchText:String)
    {
        NetworkManager.sharedInstance.searchFlickrForImagesWith(keyword: (searchText), imagesPerPage:kImagesPerPage, andPageNumber: pagenumber, completionClosure:
            { (images) in
                
                DispatchQueue.main.async {
                    if self.searchResultsArray != nil
                    {
                        self.searchResultsArray?.append(contentsOf: images as [ImageDataModel])
                    }
                    else
                    {
                        self.searchResultsArray = images
                    }
                    self.isLoadingNewData = false
                    self.searchResultsCollectionView.reloadData()
                    
                }
        })
    }
    
}

extension ViewController : UISearchResultsUpdating
{
    func updateSearchResults(for searchController: UISearchController) {
        NSLog("updateSearchResults")
    }
}

extension ViewController : UISearchBarDelegate
{
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        NSLog("searchBar textDidChange \(searchText)")
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        NSLog("searchBarSearchButtonClicked  \(searchBar.text ?? "")")
        pagenumber = 0
        self.searchResultsArray?.removeAll()
        currentSearchBarText = searchBar.text ?? ""
        searchBar.resignFirstResponder()
        getDataFromFlickr(forSearchText: searchBar.text ?? "")
        self.searchController.isActive = false
        self.searchController.isEditing = false
        self.searchController.searchBar.text = currentSearchBarText
    }
}

extension ViewController : UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return searchResultsArray?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing = CGFloat(10+(cellsPerRow*10))
        return CGSize(width: (self.view.bounds.size.width - spacing)/CGFloat(cellsPerRow), height:(self.view.bounds.size.width-spacing)/CGFloat(cellsPerRow))
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = "searchResultsCollectionViewCell"
        let cell: SearchResultsCollectionViewCell = (collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? SearchResultsCollectionViewCell)!
        
        let imageAtIndex = searchResultsArray![indexPath.row]
        cell.searchResultImageView.image = imageAtIndex.image
        switch (imageAtIndex.imageState){
        case .Failed:
            cell.searchResultImageView.image = UIImage(named: "placeholder.png")
            NSLog("Failed")
        case .New:
            cell.searchResultImageView.image = imageAtIndex.image
            if (!collectionView.isDragging && !collectionView.isDecelerating) {
                self.startOperationsForPhotoRecord(imageDetails: imageAtIndex, indexPath: indexPath as NSIndexPath)
            }
        case .Downloaded:
            if let cachedImage =  ImageDownloadManager.sharedInstance.imageCache.object(forKey: imageAtIndex.imageUrl().absoluteString as NSString)
                {
                     cell.searchResultImageView.image = cachedImage
                }
            else{
               //get from doc directory
                do {
                    let manager = FileManager.default
                    let documents = try manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    let destinationURL = documents.appendingPathComponent("\(imageAtIndex.imageId!)_\(imageAtIndex.secretId!)_m.jpg")
                    cell.searchResultImageView.image  = UIImage(contentsOfFile: destinationURL.path)
                    
                }
                catch
                {
                    NSLog("Error")
                    cell.searchResultImageView.image = UIImage(named: "placeholder.png")
                }
                
            }
            
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if(showLoader)
        {
            return CGSize(width: collectionView.bounds.size.width, height: CGFloat(floatLiteral: kFooterHeight) )
        }
        else{
            return CGSize.zero
        }
    }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView
    {
        let tempView: UICollectionReusableView = UICollectionReusableView();
        switch kind {
        case UICollectionView.elementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SearchResultsFooterView", for: indexPath) as! SearchResultsFooterView
            return footerView
            
        default:
            //4
            assert(false, "Unexpected element kind")
        }
        return tempView;
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
      
        collectionView.deselectItem(at: indexPath, animated: true)
        let tappedCell = collectionView.cellForItem(at: indexPath)
        
        let imageAtIndex = searchResultsArray![indexPath.row]
        tappedCellFrame = (tappedCell?.frame)!
        performSegue(withIdentifier: "PushToDetail", sender: imageAtIndex)

    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "PushToDetail"){
            let detailViewControllerObject = segue.destination as! ImageDetailViewController
            //send thumbnail and largerimageURL
            let imageObj = sender as! ImageDataModel
            detailViewControllerObject.imageObj = imageObj
        }
        
    }
    //MARK : ScrollView Delegates
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentOffset = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let diffHeight: Int = Int(contentHeight - contentOffset)
        let frameHeight : Int = Int(scrollView.bounds.size.height)
        if(diffHeight == frameHeight && isLoadingNewData == false)
        {
            isLoadingNewData = true
            pagenumber = pagenumber + 1
            //
            self.searchResultsCollectionView.reloadData()
            getDataFromFlickr(forSearchText: currentSearchBarText)
        }
    }
   
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        suspendAllOperations()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            loadImagesForOnscreenCells()
            resumeAllOperations()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        loadImagesForOnscreenCells()
        resumeAllOperations()
    }
    
    func suspendAllOperations () {
        downloadManager.downloadQueue.isSuspended = true
    }
    
    func resumeAllOperations () {
        downloadManager.downloadQueue.isSuspended = false
    }
    
    func loadImagesForOnscreenCells () {
            //1
            let pathsArray = searchResultsCollectionView.indexPathsForVisibleItems
            //2
            let allPendingOperations = Set(downloadManager.downloadsInProgress.keys)
            //3
            let toBeCancelled = allPendingOperations
            let visiblePaths = Set(pathsArray as [NSIndexPath])
            let _ = toBeCancelled.subtracting(visiblePaths)
            
            //4
            let toBeStarted = visiblePaths
            let _ = toBeStarted.subtracting(allPendingOperations)
            
            // 5
            for indexPath in toBeCancelled {
                if let pendingDownload = downloadManager.downloadsInProgress[indexPath] {
                    pendingDownload.cancel()
                }
                downloadManager.downloadsInProgress.removeValue(forKey:indexPath)
            }
            
            // 6
            for indexPath in toBeStarted {
                let indexPath = indexPath as NSIndexPath
                let recordToProcess = self.searchResultsArray![indexPath.row]
                startOperationsForPhotoRecord(imageDetails: recordToProcess, indexPath: indexPath)
            }
    }
    
    func startOperationsForPhotoRecord(imageDetails: ImageDataModel, indexPath: NSIndexPath){
        switch (imageDetails.imageState) {
        case .New:
            startDownloadForRecord(imageDetails: imageDetails, indexPath: indexPath)
        case .Downloaded:
            //Set it to view
            NSLog("do nothing")
        default:
            NSLog("do nothing")
        }
    }
    
    func startDownloadForRecord(imageDetails: ImageDataModel, indexPath: NSIndexPath){
        
        //if operation for it already exists
        if downloadManager.downloadsInProgress[indexPath] != nil {
            return
        }

        let downloader = DownloadOperation(url: imageDetails.imageUrl())
        downloader.completionBlock = {
            if downloader.isCancelled {
                return
            }
            DispatchQueue.main.async {
                self.downloadManager.downloadsInProgress.removeValue(forKey: indexPath)
                let imageDetails = self.searchResultsArray![indexPath.row] as ImageDataModel
                
                //Also saving it to NSCache as requested.
                do {
                    let manager = FileManager.default
                    let documents = try manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    let destinationURL = documents.appendingPathComponent("\(imageDetails.imageId!)_\(imageDetails.secretId!)_m.jpg")
                    self.downloadManager.imageCache.setObject(UIImage(contentsOfFile: destinationURL.path)!, forKey: imageDetails.imageUrl().absoluteString as NSString)
                }
                catch
                {
                    NSLog("Error")
                }
                
                
                imageDetails.imageState = .Downloaded
                self.searchResultsCollectionView.reloadItems(at: [indexPath as IndexPath])
            }
        }
        downloadManager.downloadsInProgress[indexPath] = downloader
        downloadManager.downloadQueue.addOperation(downloader)
    }
}

extension ViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        if (operation == UINavigationController.Operation.push)
        {
            let animator = PresentAnimator()
            animator.originFrame = tappedCellFrame //the selected cell gives us the frame origin for the reveal animation
            return animator
            
        }
        if (operation == UINavigationController.Operation.pop)
        {
            let animator = DismissAnimator()
            return animator
            
        }
        return nil
    }
}
