//
//  ViewController.swift
//  StockSum
//
//  Created by Tim Stephani on 6/17/15.
//  Copyright (c) 2015 Tim Stephani. All rights reserved.
//

import UIKit

class StockListViewController: UITableViewController, StockDetailViewControllerDelegate {
    
    /*
    Encapsulates functionality for saving stocks to local .plist file
    */
    var dbAccess: DBAccess!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
        Set up handler for pull to refresh functionality
        */
        self.refreshControl?.addTarget(self, action: "handleRefresh:", forControlEvents: UIControlEvents.ValueChanged)
        
        /*
        Removes empty table view cells at bottom of list
        */
        tableView.tableFooterView = UIView()
        
        /*
        Query yahoo and try to update stock prices
        */
        refresh()
    }
    
    
    /*
    Handler for pull to refresh funcationlity - delegate to refresh()
    */
    func handleRefresh(refreshControl: UIRefreshControl) {
        refresh()
    }
    
    /*
    Sort stocks alphabetically ASC
    */
    func sortStocks(stocks: [Stock]) {
        dbAccess.stocks.sort { (s1, s2) -> Bool in
            return s1.symbol < s2.symbol
        }
    }
    
    /*
    Helper function that returns stock symbols in string array -
    format accepted by queryYahoo function
    */
    func convertStockArrayToStringArray(stocks: [Stock]) -> [String] {
        var symbols = [String]()
        
        for stock in stocks {
            symbols.append(stock.symbol)
        }
        return symbols
    }
    
    func refresh() {
        sortStocks(dbAccess.stocks)
        
        var symbols = convertStockArrayToStringArray(dbAccess.stocks)
        
        Functions.queryYahoo(symbols) { (succeeded, response) -> () in
            if succeeded {
                if let query = response["query"] as? NSDictionary {
                    if let results = query["results"] as? NSDictionary {
                        if self.dbAccess.stocks.count == 1 {
                            if let quote = results["quote"] as? NSDictionary {
                                
                                let symbol = quote["symbol"] as! String
                                let stock = self.getStockFromSymbol(symbol)
                                    
                                stock.name = quote["Name"] as! String
                                stock.lastTradePriceOnly = (quote["LastTradePriceOnly"] as! NSString).doubleValue
                                    
                                var change = quote["Change"] as! String
                                if change.rangeOfString("+") != nil {
                                    change = change.stringByReplacingOccurrencesOfString("+", withString: "")
                                    stock.change = (change as NSString).doubleValue
                                } else {
                                    change = change.stringByReplacingOccurrencesOfString("-", withString: "")
                                    stock.change = -(change as NSString).doubleValue
                                }
                                
                            }
                        } else {
                            if let quote = results["quote"] as? NSArray {
                                
                                for singleQuote in quote {
                                    let symbol = singleQuote["symbol"] as! String
                                    let stock = self.getStockFromSymbol(symbol)
                                    
                                    stock.name = singleQuote["Name"] as! String
                                    stock.lastTradePriceOnly = (singleQuote["LastTradePriceOnly"] as! NSString).doubleValue
                                    
                                    var change = singleQuote["Change"] as! String
                                    if change.rangeOfString("+") != nil {
                                        change = change.stringByReplacingOccurrencesOfString("+", withString: "")
                                        stock.change = (change as NSString).doubleValue
                                    } else {
                                        change = change.stringByReplacingOccurrencesOfString("-", withString: "")
                                        stock.change = -(change as NSString).doubleValue
                                    }
                                }
                            }
                        }
                        
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> () in
                    self.tableView.reloadData()
                    self.refreshControl!.endRefreshing()
                })
            } else {
                self.refreshControl!.endRefreshing()

                var alertController = UIAlertController(title: "Error", message: "There was a problem refreshing the data. Please check your internet connection and try again.", preferredStyle: .Alert)
                var okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                    UIAlertAction in
                }
                alertController.addAction(okAction)
                self.presentViewController(alertController, animated: true, completion: nil)
            }
            
        }
    }
    
    /*
    Looks through our existing stocks trying to find 
    one with same symbol - useful when yahoo api returns
    array of records not neccessarily sorted
    */
    func getStockFromSymbol(symbol: String) -> Stock {
        for stock in dbAccess.stocks {
            if stock.symbol == symbol {
                return stock
            }
        }
        return Stock() // TODO: throw error
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dbAccess.stocks.count + 1 // summary cell
    }
    
    func stockDetailViewControllerDidCancel(controller: StockDetailViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func stockDetailViewController(controller: StockDetailViewController, didFinishAddingItem item: Stock) {
        let newRowIndex = dbAccess.stocks.count + 1
        dbAccess.stocks.append(item)
        
        let indexPath = NSIndexPath(forRow: newRowIndex, inSection: 0)
        let indexPaths = [indexPath]
        
        tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
        
        refresh()
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func stockDetailViewController(controller: StockDetailViewController, didFinishEditingItem item: Stock) {
        tableView.reloadData()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell

        if indexPath.row > 0 {
            cell = tableView.dequeueReusableCellWithIdentifier("Stock") as! UITableViewCell
            
            let stock = dbAccess.stocks[indexPath.row - 1]
            
            let symbol = cell.viewWithTag(1000) as! UILabel
            symbol.text = stock.symbol
            
            let name = cell.viewWithTag(1002) as! UILabel
            name.text = stock.name
            
            let numShares = cell.viewWithTag(1008) as! UILabel
            numShares.text = String(stock.numShares) + " shares"
            
            let price = cell.viewWithTag(1001) as! UILabel
            price.text = "$" + String(format:"%.2f", stock.lastTradePriceOnly)
                
            let change = cell.viewWithTag(1012) as! UILabel
            change.text = "$" + String(format:"%.2f", abs(stock.change)) + " "
                + String(format:"%.2f", abs(((stock.lastTradePriceOnly / (stock.lastTradePriceOnly - stock.change)) - 1) * 100)) + "%"
            
            let gainLoss = cell.viewWithTag(1003) as! UILabel
            gainLoss.text = "$" + String(format:"%.2f", abs(stock.change * Double(stock.numShares)))
            
            if stock.change > 0 {
                change.textColor = UIColor(red: 0.04, green: 0.8, blue: 0.04, alpha: 1.0)
                gainLoss.textColor = UIColor(red: 0.04, green: 0.8, blue: 0.04, alpha: 1.0)
            } else if stock.change < 0 {
                change.textColor = UIColor.redColor()
                gainLoss.textColor = UIColor.redColor()
            }
            
            
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier("Summary") as! UITableViewCell
            
            var gainLoss = 0.0
            var currentValue = 0.0
            var dayStartValue = 0.0
            for stock in dbAccess.stocks {
                currentValue += Double(stock.numShares) * stock.lastTradePriceOnly
                dayStartValue += Double(stock.numShares) * (stock.lastTradePriceOnly - stock.change)
                gainLoss += Double(stock.numShares) * stock.change
            }
            
            let todaysChange = cell.viewWithTag(1009) as! UILabel
            var percentChange = 0.0
            if dayStartValue > 0 { // avoid divide by zero (nan)
                percentChange = ((currentValue / dayStartValue) - 1) * 100
            }
            todaysChange.text = "$" + String(format:"%.2f", abs(gainLoss)) + " " +
                String(format:"%.2f", abs(percentChange)) + "%"
            if gainLoss > 0 {
                todaysChange.textColor = UIColor(red: 0.04, green: 0.8, blue: 0.04, alpha: 1.0)
            } else if gainLoss < 0 {
                todaysChange.textColor = UIColor.redColor()
            }


            let totalValue = cell.viewWithTag(1010) as! UILabel
            totalValue.text = "$" + String(format: "%.2f", currentValue)
            
            let lastUpdated = cell.viewWithTag(1011) as! UILabel
            let date = NSDate()
            let formatter = NSDateFormatter()
            formatter.dateStyle = .ShortStyle
            formatter.timeStyle = .ShortStyle
            lastUpdated.text = formatter.stringFromDate(date)
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 80
        } else {
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        dbAccess.stocks.removeAtIndex(indexPath.row - 1)

        let indexPaths = [indexPath]
        
        tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
        
        tableView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "AddStock" {
            let navigationController = segue.destinationViewController as! UINavigationController

            let controller = navigationController.topViewController as! StockDetailViewController
            
            controller.dbAccess = dbAccess
            
            controller.delegate = self
        } else if segue.identifier == "EditStock" {
            let navigationController = segue.destinationViewController as! UINavigationController
            
            let controller = navigationController.topViewController as! StockDetailViewController
            
            controller.delegate = self
            
            if let indexPath = tableView.indexPathForCell(sender as! UITableViewCell) {
                controller.stockToEdit = dbAccess.stocks[indexPath.row - 1]
            }
        }
    }
}

