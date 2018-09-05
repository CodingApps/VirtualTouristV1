//
//  Pin+CoreDataClass.swift
//  VirtualTouristV1
//
//  Created by Rick Mc on 9/4/18.
//  Copyright © 2018 Rick Mc. All rights reserved.
//
//

import Foundation
import CoreData
import MapKit

@objc(Pin)

public class Pin: NSManagedObject {
    var coordinate: CLLocationCoordinate2D{
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    convenience init(_ lat:Double,_ lon: Double,_ context: NSManagedObjectContext ){
        let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context)!
        self.init(entity: entity, insertInto: context)
        self.latitude = lat
        self.longitude = lon
    }
    
}
