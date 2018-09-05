//
//  MapViewController.swift
//  VirtualTouristV1
//
//  Created by Rick Mc on 9/4/18.
//  Copyright © 2018 Rick Mc. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController,MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    let delegate = UIApplication.shared.delegate as! AppDelegate
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(pressLong(_:)))
        longPressRecogniser.minimumPressDuration = 1.5
        mapView.addGestureRecognizer(longPressRecogniser)
        mapView.delegate = self
        loadPinsFromDatabase()
        
    }
    
    // Process long-presses to add pins to map
    
    @objc func pressLong(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizerState.began{
            let point = gestureRecognizer.location(in:mapView)
            let coor = mapView.convert(point, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coor
            mapView.addAnnotation(annotation)
            
            let stack = delegate.stack
            let _ = Pin(coor.latitude, coor.longitude,stack.context)
            stack.save()
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        performSegue(withIdentifier: "showPhoto", sender: nil)
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
    
    // Load current pins onto map
    
    func loadPinsFromDatabase()
    {
        var pins = [Pin]()
        let stack = delegate.stack
        var annotations = [MKAnnotation]()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        do
        {
            let results = try stack.context.fetch(fetchRequest)
            if let results = results as? [Pin]{
                pins = results
                print("Number of Pins : \(pins.count)")
            }}
        catch{
            print("Couldn't find any Pins.")
        }
        
        for (_,item) in pins.enumerated()
        {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(item.latitude),longitude: CLLocationDegrees(item.longitude))
            annotations.append(annotation)
        }
        mapView.addAnnotations(annotations)
    }
    
    // Load collectionView in PhotoViewController if pin selected
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var pin: Pin!
        let selected = mapView.selectedAnnotations.popLast()!
        do
        {
            let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
            let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [selected.coordinate.latitude, selected.coordinate.longitude])
            fetchRequest.predicate = predicate
            let pins = try delegate.stack.context.fetch(fetchRequest)
            pin = pins[0]
        }
        catch let error as NSError
        {
            print("Failed to get pin by object ID.")
            print(error.localizedDescription)
            return
        }
        let controller =  segue.destination as! PhotoViewController
        controller.pin = pin
        
    }
    
}


