//
//  DataOperations.swift
//  SomeStocks
//
//  Created by Lyubomir Marinov on 10/8/15.
//  Copyright (c) 2015 Lyubomir Marinov. All rights reserved.
//

import Foundation

//
// Data Fetch NSOperation class
//
class DataFetchOperation:NSOperation {
    var stockObject:Stock;
    
    init(stockObject:Stock) {
        self.stockObject = stockObject;
    }
    
    override func main() {
        // check if canceled before the data fetch
        if self.cancelled {
            return;
        }
        
        // get the JSON data from ShareVille.se
        OperationManager.getJsonData(self.stockObject.dataUrl, completionHandler: { (stockData) -> () in
            // populate the Stock object data
            if let currency = stockData["currency"] as? String {
                self.stockObject.currency = currency;
            }
            
            if let name = stockData["name"] as? String {
                self.stockObject.name = name;
            }
            
            if let symbol = stockData["symbol"] as? String {
                self.stockObject.symbol = symbol;
            }
            
            self.stockObject.status = .FetchedData;
        }) { (error) -> () in
            println(error.localizedDescription);
            self.stockObject.status = .DataFetchFailed;
            
            self.cancel();
        }
        
        if self.cancelled {
            return;
        }
    }
}

//
// Price Fetch NSOperation class
//
class PriceFetchOperation:NSOperation {
    var stockObject:Stock;
    
    init(stockObject:Stock) {
        self.stockObject = stockObject;
    }
    
    override func main() {
        // check if canceled before the data fetch
        if self.cancelled {
            return;
        }
        
        // get the JSON data from ShareVille.se
        OperationManager.getJsonData(self.stockObject.priceUrl, completionHandler: { (stockPrice) -> () in
            if let query = stockPrice["query"] as? NSDictionary {
                if let results = query["results"] as? NSDictionary {
                    if let quote = results["quote"] as? NSDictionary {
                        // populate the Stock Price data
                        if let price = quote["LastTradePriceOnly"] as? NSString {
                            self.stockObject.currentPrice = price.floatValue;
                        }
                        
                        if let currency = quote["Currency"] as? String {
                            self.stockObject.currency = currency;
                        }
                        
                        if let difference = quote["Change"] as? String {
                            self.stockObject.difference = (difference as NSString).floatValue;
                        }
                        
                        if let percent = quote["PercentChange"] as? String {
                            self.stockObject.percentChange = (dropLast(percent) as NSString).floatValue;
                        }
                        
                        self.stockObject.status = .FetchedPrice;
                    } else {
                        self.stockObject.status = .PriceFetchFailed;
                        println("Missing \"quote\" value.");
                    }
                } else {
                    self.stockObject.status = .PriceFetchFailed;
                    println("Missing \"results\" value.");
                }
            } else {
                self.stockObject.status = .PriceFetchFailed;
                println("Missing \"query\" value.");
            }
            }) { (error) -> () in
                println(error.localizedDescription);
                self.stockObject.status = .PriceFetchFailed;
        }
        
        if self.cancelled {
            return;
        }
    }
}