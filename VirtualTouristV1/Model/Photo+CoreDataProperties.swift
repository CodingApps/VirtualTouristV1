//
//  Photo+CoreDataProperties.swift
//  VirtualTouristV1
//
//  Created by Rick Mc on 9/4/18.
//  Copyright © 2018 Rick Mc. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var imageData: NSData?
    @NSManaged public var url: String?
    @NSManaged public var photo: Pin?

}
