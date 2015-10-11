//
//  Stock.swift
//  SomeStocks
//
//  Created by Lyubomir Marinov on 10/8/15.
//  Copyright (c) 2015 Lyubomir Marinov. All rights reserved.
//

import Foundation

enum StockStatus {
    case Created
    case FetchedData
    case FetchedPrice
    case DataFetchFailed
    case PriceFetchFailed
}

class Stock {
    // URL to fetch the stock data from ShareVille.se
    var dataUrl:String! {
        didSet {
            let urlPrefix = "https://www.shareville.se/api/v1/marketflow/instruments/";
            
            // check if url is full url or slug only
            if dataUrl.rangeOfString(urlPrefix, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) == nil {
                dataUrl = urlPrefix + dataUrl;
            }
        }
    }
    
    // URL to fetch the stock price from Yahoo.com
    var priceUrl:String!;
    
    //
    var name:String!;
    var symbol:String! {
        didSet {
            // set Yahoo.com URL parts as $_GET["q"] and $_GET["env"] parameters should be URLEncoded
            let yahooQuery = "select LastTradePriceOnly, Currency, Change, PercentChange from yahoo.finance.quotes where symbol = \"\(symbol)\"".stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding);
            let yahooEnv = "http://datatables.org/alltables.env".stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding);
            self.priceUrl = "http://query.yahooapis.com/v1/public/yql?q=\(yahooQuery!)&env=\(yahooEnv!)&format=json";
        }
    }
    var currency:String!;
    var currentPrice:Float!;
    var difference:Float!;
    var percentChange:Float!;
    var status = StockStatus.Created;
}