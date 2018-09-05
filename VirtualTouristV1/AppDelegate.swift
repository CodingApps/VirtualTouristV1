//
//  AppDelegate.swift
//  VirtualTouristV1
//
//  Created by Rick Mc on 9/4/18.
//  Copyright © 2018 Rick Mc. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let stack = CoreDataStack(modelName: "LocationPins")!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        stack.save()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        stack.save()
    }
    
    
}
