//
//  FlickrClient.swift
//  VirtualTouristV1
//
//  Created by Rick Mc on 9/4/18.
//  Copyright © 2018 Rick Mc. All rights reserved.
//

import Foundation
class FlickrClient {
    
    var session = URLSession.shared
    func getImageURL(_ lat: Double, lon: Double, completionHandlerForImage: @escaping (_ imageData: AnyObject?, _ error: NSError?) -> Void) -> URLSessionTask {
        
        let lon = Int(lon)
        let lat = Int(lat)
        debugPrint(lon)
        debugPrint(lat)
        
        let bboxString = "\(lon - 1),\(lat - 1),\(lon + 1),\(lat + 1)"
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString,
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        let request = URLRequest(url: flickrURLFromParameters(methodParameters as [String : AnyObject]))
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForImage(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            guard (error == nil) else {
                sendError("There was an error with your request: \(String(describing: error))")
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForImage)
        }
        task.resume()
        
        return task
    }
    
    func downloadPhotos(_ photoURL:String, completionHandlerForDownloadPhotos: @escaping (_ image: NSData?, _ error: NSError?) -> Void)
    {
        let url = NSURL(string: photoURL)
        let request = URLRequest(url: url! as URL)
        let task = session.dataTask(with: request){ data, response, error in
            
            guard let data = data else
            {
                return
            }
            completionHandlerForDownloadPhotos(data as NSData, nil)
        }
        task.resume()
    }
    
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        completionHandlerForConvertData(parsedResult, nil)
    }
    
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        return components.url!
    }
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
}


