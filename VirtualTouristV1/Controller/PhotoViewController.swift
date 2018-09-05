//
//  PhotoViewController.swift
//  VirtualTouristV1
//
//  Created by Rick Mc on 9/4/18.
//  Copyright © 2018 Rick Mc. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController,MKMapViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newButton: UIButton!
    
    var pin: Pin?
    let flickr = FlickrClient.sharedInstance()
    let delegate = UIApplication.shared.delegate as! AppDelegate
    let numImagestoDisplay = 15
    var insertIndexCache: [NSIndexPath]!
    var deleteIndexCache: [NSIndexPath]!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    
    func initializeFlowLayout()
    {
        collectionView?.contentMode = UIViewContentMode.scaleAspectFit
        collectionView?.backgroundColor = UIColor.white
        let space : CGFloat = 7.5
        let dimension = (self.view.frame.width - (2 * space)) / 3.5
        collectionViewFlowLayout.minimumInteritemSpacing = space
        collectionViewFlowLayout.minimumLineSpacing = space
        collectionViewFlowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = (pin!.latitude)
        annotation.coordinate.longitude = (pin!.longitude)
        mapView.addAnnotation(annotation)
        initializeFlowLayout()
        debugPrint("LoadPhotosCount : ",loadPhotosFromDatabase().count)
        if loadPhotosFromDatabase().count == 0 {
            searchPhoto()
        }
        mapView.centerCoordinate = (pin?.coordinate)!
        mapView.camera.altitude = 125
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        delegate.stack.save()
    }
    
    @IBAction func newCollection(_ sender: Any) {
        deleteAll()
        searchPhoto()
    }
    
    func deleteAll(){
        for photo in fetchedResultsController?.fetchedObjects as! [Photo] {
            delegate.stack.context.delete(photo)
        }
        
    }
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            fetchedResultsController?.delegate = self
            executeSearch()
            collectionView.reloadData()
        }
    }
    
    func loadPhotosFromDatabase() -> [Photo]{
        var photos = [Photo]()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "photo = %@", pin!)
        fetchRequest.sortDescriptors = []
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: delegate.stack.context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController?.delegate = self
        
        do
        {
            try fetchedResultsController?.performFetch()
            if let result = fetchedResultsController?.fetchedObjects as? [Photo]{
                photos = result
            }
        }catch{
            print("error fetch photos")
        }
        return photos
    }
    
    func searchPhoto(){
        flickr.getImageURL(pin!.latitude, lon: pin!.longitude){ (data,error) in
            if let photos = data!["photos"] as! [String:Any]? {
                if let photo = photos["photo"] as! Array<Any>?{
                    let count = photo.count
                    debugPrint("Count ", count)
                    debugPrint("Location ", photo)
                    guard count != 0 else{
                        return
                    }
                    let urlIndex  =  self.shuffleArray(Array(0...(count - 1)))
                    let range = count < self.numImagestoDisplay ? count : self.numImagestoDisplay
                    debugPrint("Range : ",range)
                    let selectedURL = Array(urlIndex.prefix(range))
                    var url = [String]()
                    for item in selectedURL{
                        let temp = photo[item] as! [String:Any]
                        url.append(temp["url_m"] as! String)
                        self.collectionView.updateConstraints()
                    }
                    for item in url{
                        let photo = Photo(context: self.delegate.stack.context)
                        photo.photo = self.pin
                        debugPrint(item)
                        photo.url = item
                    }}}else{
                print(error!)
            }
        }
    }
    
    private func shuffleArray<T>(_ array: Array<T>) -> Array<T>
    {
        var array = array
        for index in ((0 + 1)...array.count - 1).reversed()
        {
            let j = Int(arc4random_uniform(UInt32(index-1)))
            //      swap(&array[index], &array[j])
            array.swapAt(index, j)
            
            
        }
        return array
    }
    
    
}
extension PhotoViewController {
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        delegate.stack.context.delete(photo)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        debugPrint("Col # Objects : ", fetchedResultsController!.sections![section].numberOfObjects)
        return fetchedResultsController!.sections![section].numberOfObjects
        //        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        cell.activityIndicator.isHidden = true
        cell.imageView.image = nil
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        if photo.imageData == nil{
            cell.activityIndicator.isHidden = false
            cell.imageView.image = UIImage(named: "defaultImage")
            cell.activityIndicator.startAnimating()
            debugPrint(photo.url)
            DispatchQueue.main.async{
                self.flickr.downloadPhotos(photo.url!){ (image, error) in
                    photo.imageData = image
                    cell.imageView.image = UIImage(data: image as! Data)
                    cell.activityIndicator.isHidden = true
                }
            }
        }else{
            cell.imageView.image = UIImage(data: photo.imageData as! Data)
        }
        return cell
    }
    
    
}

extension PhotoViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        insertIndexCache = [NSIndexPath]()
        deleteIndexCache = [NSIndexPath]()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        collectionView.performBatchUpdates(
            {
                self.collectionView.insertItems(at: self.insertIndexCache as [IndexPath])
                self.collectionView.deleteItems(at: self.deleteIndexCache as [IndexPath])
        }, completion: nil)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        switch type
        {
        case .insert:   insertIndexCache.append(newIndexPath! as NSIndexPath)
        case .delete:   deleteIndexCache.append(indexPath! as NSIndexPath)
        default: break
        }
    }
}

