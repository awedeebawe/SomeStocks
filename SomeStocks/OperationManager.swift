//
//  OperationManager.swift
//  SomeStocks
//
//  Created by Lyubomir Marinov on 10/8/15.
//  Copyright (c) 2015 Lyubomir Marinov. All rights reserved.
//

import Foundation
import UIKit

class OperationManager {
    //
    // typealias the completion/error closures
    //
    typealias processComplete = (NSDictionary!)->();
    typealias processError = (NSError!)->();
    
    //
    // ShareVille.se data fetch operation queue
    //
    lazy var activeDataDownloads = [NSIndexPath:NSOperation]();
    lazy var dataDownloadQueue:NSOperationQueue = {
        var queue = NSOperationQueue();
        // Set name visible in Instruments and the Debugger
        queue.name = "ShareVille.se downloads queue";
        
        return queue;
        }();
    
    //
    // Yahoo.com fetch operation queue
    //
    lazy var activePriceDownloads = [NSIndexPath:NSOperation]();
    lazy var priceDownloadQueue:NSOperationQueue = {
        var queue = NSOperationQueue();
        queue.name = "Yahoo.com downloads queue";
        
        return queue;
        }();
    
    //
    // JSON fetch method
    //
    class func getJsonData(urlString:String, completionHandler:processComplete, errorHandler:processError) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true;
        
        let url = NSURL(string:urlString);

        let request = NSURLRequest(URL: url!);
        var response: NSURLResponse?;
        var error: NSError?;
        
        var data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error);
        
        if error != nil {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false;

            errorHandler(error);
        } else {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false;

            var jsonError:NSError?;
            if let jsonResponse:NSDictionary = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: &jsonError) as? NSDictionary {
                if jsonError != nil {
                    errorHandler(jsonError);
                } else {
                    completionHandler(jsonResponse);
                }
            } else {
                let userInfo = [NSLocalizedDescriptionKey: "Response is not valid JSON string"];
                let error = NSError(domain: "SomeStocksErrorMessages", code: 200, userInfo: userInfo);
                errorHandler(error);
            }
        }
    }
}
