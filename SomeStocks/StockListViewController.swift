//
//  StockListViewController.swift
//  SomeStocks
//
//  Created by Lyubomir Marinov on 10/9/15.
//  Copyright (c) 2015 Lyubomir Marinov. All rights reserved.
//

import Foundation
import UIKit

class StockListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // IBOutlets
    @IBOutlet weak var stockTable:UITableView!;
    
    // Operation Manager
    let operationManager = OperationManager();
    
    // list of companies to fetch their stock prices
    var stockCompanies = [
        "Apple":"https://www.shareville.se/api/v1/marketflow/instruments/apple-inc", // full url demo
        "Microsoft":"microsoft-corporation",
        "Facebook":"facebook-inc-class-a",
        "Yahoo":"yahoo-inc",
        "Netflix":"https://www.shareville.se/api/v1/marketflow/instruments/netflix-inc", // full url demo
        "Disney":"disney-walt-co-the",
        "Google":"google-inc-class-a", // NOTE: This seems to be wrong.....
        "Amazon":"amazoncom-inc"
    ]; // add more by supplying key-value pair with "Company name":"full url/slug" for ShareVille.se API
    
    // create array to store the Stock objects
    var dataSource = [Stock]();
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupDataSource();
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: TableView delegate and data source methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count;
    }
    
//    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        return 48.0;
//    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let stock = self.dataSource[indexPath.row];
        let cell = tableView.dequeueReusableCellWithIdentifier("stockCell", forIndexPath: indexPath) as! StockViewCell;
        
        // create loading indicator and add it as accessory view
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        indicator.hidesWhenStopped = true;
        if cell.accessoryView == nil {
            cell.accessoryView = indicator;
        }
        
        // reset the UILabel colors to black
        cell.stockSymbolLabel.textColor = UIColor.blackColor();
        cell.stockSymbolLabel.font = UIFont.boldSystemFontOfSize(16);
        cell.stockNameLabel.textColor = UIColor.blackColor();
        cell.stockPriceLabel.textColor = UIColor.blackColor();
        cell.stockDifferenceLabel.textColor = UIColor.blackColor();
        
        switch stock.status {
        case .Created:
            indicator.startAnimating();
            
            // fetch the data for the current stock
            self.fetchDataForStockAtIndexPath(stock, indexPath: indexPath);
            
        case .FetchedData:
            indicator.startAnimating();
            
            // Update Symbol and Name label
            cell.stockSymbolLabel.text = stock.symbol;
            cell.stockNameLabel.text = stock.name;
            
            // fetch the price for the current stock
            self.fetchPriceForStockAtIndexPath(stock, indexPath: indexPath);
            
        case .FetchedPrice:
            // Remove the accessory view
            cell.accessoryView = nil;
            
            // Update Symbol and Name label
            cell.stockSymbolLabel.text = stock.symbol;
            cell.stockNameLabel.text = stock.name;
            
            // Unhide the labels and set the price and the difference
            cell.stockPriceLabel.hidden = false;
            cell.stockPriceLabel.text = String(format:"%.2f ", stock.currentPrice) + stock.currency;
            
            var differenceString = String(format:"+%.2f (+%.2f%%)", stock.difference, stock.percentChange);
            var differenceColor = UIColor(red: 63/255.0, green: 163/255.0, blue: 63/255.0, alpha: 1);
            
            if stock.difference < 0 {
                differenceString = String(format:"%.2f (%.2f%%)", stock.difference, stock.percentChange);
                differenceColor = UIColor.redColor();
            }
            
            cell.stockDifferenceLabel.hidden = false;
            cell.stockDifferenceLabel.text = differenceString;
            cell.stockDifferenceLabel.textColor = differenceColor;
            
        case .DataFetchFailed:
            cell.accessoryView = nil;
            
            cell.stockSymbolLabel.text = "Failed to fetch data";
            cell.stockSymbolLabel.textColor = UIColor.redColor();
            cell.stockSymbolLabel.font = UIFont.boldSystemFontOfSize(14);
            
            cell.stockNameLabel.text = "Tap to retry";
            cell.stockNameLabel.textColor = UIColor.redColor();
            
        case .PriceFetchFailed:
            // Remove the accessory view
            cell.accessoryView = nil;
            
            // Unhide the labels and set fail messages to them
            cell.stockPriceLabel.hidden = false;
            cell.stockPriceLabel.text = "Failed";
            cell.stockPriceLabel.textColor = UIColor.redColor();
            
            cell.stockDifferenceLabel.hidden = false;
            cell.stockDifferenceLabel.text = "Tap to retry";
            cell.stockDifferenceLabel.textColor = UIColor.redColor();
        }
        
        return cell as UITableViewCell;
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true);
        
        let stock = self.dataSource[indexPath.row];
        
        switch stock.status {
        case .Created, .FetchedData:
            println("do nothing");
            
        case .FetchedPrice:
            // Everything is set. So go to details view
            self.performSegueWithIdentifier("stockDetailsSegue", sender: tableView.cellForRowAtIndexPath(indexPath));
            
        case .DataFetchFailed:
            // set the Stock Object status (directly in the dataSource array) back to StockStatus.Created and try again
            self.dataSource[indexPath.row].status = .Created;
            self.fetchDataForStockAtIndexPath(self.dataSource[indexPath.row], indexPath: indexPath);
            
        case .PriceFetchFailed:
            // set the Stock Object status (directly in the dataSource array) back to StockStatus.FetchedData and try again
            self.dataSource[indexPath.row].status = .FetchedData;
            self.fetchPriceForStockAtIndexPath(self.dataSource[indexPath.row], indexPath: indexPath);
        }

    }
    
    // MARK: - Setup Data Source
    func setupDataSource() {
        // Sort the StockCompanies array by key and store it as a temp array
        let sortedStockCompanies = sorted(self.stockCompanies) {
            $0.0 < $1.0;
        };
        
        // Create the Stock objects
        for (name, slug) in sortedStockCompanies {
            let stockObject = Stock();
            stockObject.dataUrl = slug;
            
            self.dataSource.append(stockObject);
        }
        
        self.stockTable.reloadData();
    }
    
    // MARK: - NSOperation control methods
    func fetchDataForStockAtIndexPath(stock:Stock, indexPath:NSIndexPath) {
        // check if operation for this stock exists
        if let existingDataFetchOperation = self.operationManager.activeDataDownloads[indexPath] {
            println("existingDataFetchOperation");
            return;
        }
        
        let dataFetchOperation = DataFetchOperation(stockObject: self.dataSource[indexPath.row]);
        
        // add the operation to the activeDataDownloads array
        self.operationManager.activeDataDownloads[indexPath] = dataFetchOperation;
        
        // add the operation to the download queue
        self.operationManager.dataDownloadQueue.addOperation(dataFetchOperation);
        
        dataFetchOperation.completionBlock = {
            // remove the operation from the activeDataDownloads
            self.operationManager.activeDataDownloads.removeValueForKey(indexPath);
            
            if dataFetchOperation.cancelled {
                println("cancelled");
                dispatch_async(dispatch_get_main_queue(), {
                    // set the stock object status to .DataFetchFailed by directly manipulating the dataSource array
                    self.dataSource[indexPath.row].status = .DataFetchFailed;
                
                    // reload the current cell only with FADE animation
                    self.stockTable.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade);
                });
                
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                // reload the current cell only with FADE animation
                self.stockTable.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade);
            });
            
        }
    }
    
    func fetchPriceForStockAtIndexPath(stock:Stock, indexPath:NSIndexPath) {
        if let currentPriceFetchOperation = self.operationManager.activePriceDownloads[indexPath] {
            println("currentPriceFetchOperation");
            return;
        }
        
        let priceFetchOperation = PriceFetchOperation(stockObject: stock);
        
        self.operationManager.activePriceDownloads[indexPath] = priceFetchOperation;
        
        self.operationManager.priceDownloadQueue.addOperation(priceFetchOperation);
        
        priceFetchOperation.completionBlock = {
            self.operationManager.activePriceDownloads.removeValueForKey(indexPath);
            
            if priceFetchOperation.cancelled {dispatch_async(dispatch_get_main_queue(), {
                self.dataSource[indexPath.row].status = .PriceFetchFailed;
                
                self.stockTable.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None);
            });
                
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.stockTable.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None);
            });
        }
        
    }
    
    // MARK: - Unwind segue IBAction
    @IBAction func closeDetails(sender: UIStoryboardSegue) {
        // get data from StockDetailsViewController if needed
        let sourceViewController = sender.sourceViewController as! StockDetailsViewController;
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            if let destinationController = segue.destinationViewController as? StockDetailsViewController {
                let indexPath = self.stockTable.indexPathForCell(sender as! StockViewCell);
                
                destinationController.stockObject = self.dataSource[indexPath!.row] as Stock;
            }
        }
    }

}
