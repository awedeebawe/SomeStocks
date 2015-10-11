//
//  StockDetailsViewController.swift
//  SomeStocks
//
//  Created by Lyubomir Marinov on 10/11/15.
//  Copyright (c) 2015 Lyubomir Marinov. All rights reserved.
//

import UIKit

class StockDetailsViewController: UIViewController {
    // IBOutlets
    @IBOutlet weak var stockDetailsSymbolLabel:UILabel!;
    @IBOutlet weak var stockDetailsPriceLabel:UILabel!;
    @IBOutlet weak var stockDetailsChangeLabel:UILabel!;
    @IBOutlet weak var stockDetailsCompanyInfo:UITextView!;
    @IBOutlet weak var stockDetailsRetryButton:UIButton!;
    @IBOutlet weak var stockDetailsLoadingIndicator:UIActivityIndicatorView!;
    
    // Stock object
    var stockObject:Stock!;

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set Navigation title
        self.title = stockObject.name;
        
        // setup labels
        self.stockDetailsSymbolLabel.text = stockObject.symbol;
        self.stockDetailsPriceLabel.text = String(format:"%.2f ", stockObject.currentPrice) + stockObject.currency;
        
        var differenceString = String(format:"+%.2f (+%.2f%%)", stockObject.difference, stockObject.percentChange);
        var differenceColor = UIColor(red: 63/255.0, green: 163/255.0, blue: 63/255.0, alpha: 1);
        
        if stockObject.difference < 0 {
            differenceString = String(format:"%.2f (%.2f%%)", stockObject.difference, stockObject.percentChange);
            differenceColor = UIColor.redColor();
        }
        
        self.stockDetailsChangeLabel.text = differenceString;
        self.stockDetailsChangeLabel.textColor = differenceColor;
        
        // fetch Company details from Yahoo.com
        fetchCompanyData();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Fetch Company Data method
    func fetchCompanyData() {
        let errorMessage = "Error fetching company information";
        
        self.stockDetailsLoadingIndicator.startAnimating();
        self.stockDetailsRetryButton.hidden = true;
        
        // Build YQL query
        let query = "select * from html where url=\"https://finance.yahoo.com/q/pr?s=\(self.stockObject.symbol)\" and compat=\"html5\" and xpath='//td[contains(@class,\"yfnc_modtitlew1\")]/p'".stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding);

        let url = NSURL(string: "http://query.yahooapis.com/v1/public/yql?q=" + query! + "&format=json");
        let request = NSURLRequest(URL: url!);
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response, data, error) -> Void in
            
            self.stockDetailsLoadingIndicator.stopAnimating();
            
            if error != nil {
                self.stockDetailsCompanyInfo.text = error.localizedDescription;
                self.stockDetailsRetryButton.hidden = false;
            } else {
                var jsonError:NSError?;
                
                if let jsonResponse:NSDictionary = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: &jsonError) as? NSDictionary {
                    if jsonError != nil {
                        self.stockDetailsCompanyInfo.text = errorMessage;
                        self.stockDetailsRetryButton.hidden = false;
                    } else {
                        if let query = jsonResponse["query"] as? NSDictionary {
                            if let results = query["results"] as? NSDictionary {
                                if let paragraphs = results["p"] as? NSArray {
                                    for paragraph:Any in paragraphs {
                                        if paragraph is String {
                                            self.stockDetailsCompanyInfo.text = paragraph as? String;
                                            
                                            // Reset the UITextView color and text alignment
                                            self.stockDetailsCompanyInfo.textColor = UIColor.blackColor();
                                            self.stockDetailsCompanyInfo.textAlignment = NSTextAlignment.Justified;
                                        }
                                    }
                                } else {
                                    self.stockDetailsCompanyInfo.text = errorMessage;
                                    self.stockDetailsRetryButton.hidden = false;
                                }
                            } else {
                                self.stockDetailsCompanyInfo.text = errorMessage;
                                self.stockDetailsRetryButton.hidden = false;
                            }
                        } else {
                            self.stockDetailsCompanyInfo.text = errorMessage;
                            self.stockDetailsRetryButton.hidden = false;
                        }
                    }
                } else {
                    self.stockDetailsCompanyInfo.text = errorMessage;
                    self.stockDetailsRetryButton.hidden = false;
                }
            }
        }
    }
    
    @IBAction func retryFetching() {
        self.fetchCompanyData();
    }
    
    // MARK: - Unwind Segue IBAction
    @IBAction func closeStockDetails(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("closeStockDetailsSegue", sender: self);
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
