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
        
        Functions.addBorderToNavBar(self.navigationController!.navigationBar)
    }
    
    @IBAction func showInfo() {
        performSegueWithIdentifier("InfoSegue", sender: self)
    }
    
    /*
    Handler for pull to refresh funcationlity - delegate to refresh()
    */
    func handleRefresh(refreshControl: UIRefreshControl) {
        refresh()
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
        dbAccess.stocks.sort { (s1, s2) -> Bool in
            return s1.symbol < s2.symbol
        }
        
        var symbols = convertStockArrayToStringArray(dbAccess.stocks)
        
        Functions.queryYahoo(symbols) { (succeeded, response) -> () in
            if succeeded {
                if let query = response["query"] as? NSDictionary {
                    if let results = query["results"] as? NSDictionary {
                        if self.dbAccess.stocks.count == 1 {
                            if let quote = results["quote"] as? NSDictionary {
                                
                                let symbol = quote["symbol"] as! String
                                let stock = self.getStockFromSymbol(symbol)
                                
                                stock.bindFromYahooDict(quote)
                            }
                        } else {
                            if let quote = results["quote"] as? NSArray {
                                for singleQuote in quote {
                                    let symbol = singleQuote["symbol"] as! String
                                    let stock = self.getStockFromSymbol(symbol)
                                    
                                    stock.bindFromYahooDict(singleQuote as! NSDictionary)
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
                
                Functions.showAlert("Error", message: "There was a problem refreshing the data. Please check your internet connection and try again.", caller: self)
            }
        }
    }
    
    /*
    Looks through our existing stocks trying to find 
    one with same symbol - useful when Yahoo API returns
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
        if dbAccess.stocks.count == 0 {
            return 1 // no records found cell
        }
        
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
    
    func bindStockToStockCell(stock: Stock, cell: UITableViewCell) {
        let symbol = cell.viewWithTag(1000) as! UILabel
        symbol.text = stock.symbol
        
        let name = cell.viewWithTag(1002) as! UILabel
        name.text = stock.name
        
        let numShares = cell.viewWithTag(1008) as! UILabel
        numShares.text = String(stock.numShares) + " shares"
        
        let price = cell.viewWithTag(1001) as! UILabel
        price.text = Functions.formatNumberToCurrency(stock.lastTradePriceOnly)
        
        let change = cell.viewWithTag(1012) as! UILabel
        change.text = Functions.formatNumberToCurrency(abs(stock.change)) + " "
            + String(format:"%.2f", abs(((stock.lastTradePriceOnly / (stock.lastTradePriceOnly - stock.change)) - 1) * 100)) + "%"
        
        let gainLoss = cell.viewWithTag(1003) as! UILabel
        gainLoss.text = Functions.formatNumberToCurrency(abs(stock.change) * Double(stock.numShares))
        
        change.textColor = Functions.determineTextColorBasedOnPrice(stock.change)
        gainLoss.textColor = Functions.determineTextColorBasedOnPrice(stock.change)
    }
    
    func bindStocksToSummaryCell(stocks: [Stock], cell: UITableViewCell) {
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
        todaysChange.text = Functions.formatNumberToCurrency(abs(gainLoss)) +
            " " + String(format:"%.2f", abs(percentChange)) + "%"
        
        todaysChange.textColor = Functions.determineTextColorBasedOnPrice(gainLoss)
        
        let totalValue = cell.viewWithTag(1010) as! UILabel
        totalValue.text = Functions.formatNumberToCurrency(currentValue)
        
        let lastUpdated = cell.viewWithTag(1011) as! UILabel
        lastUpdated.text = Functions.formatDateTimeToString(NSDate())
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell

        if dbAccess.stocks.count == 0 && indexPath.row == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier("NoRecords") as! UITableViewCell
            cell.selectionStyle = .None

            let noRecords = cell.viewWithTag(1015) as! UILabel
            noRecords.text = Globals.NO_RECORDS_TEXT
        } else if indexPath.row == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier("Summary") as! UITableViewCell
            cell.selectionStyle = .None
            
            bindStocksToSummaryCell(dbAccess.stocks, cell: cell)
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier("Stock") as! UITableViewCell
            
            let stock = dbAccess.stocks[indexPath.row - 1]
            
            bindStockToStockCell(stock, cell: cell)
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        /*
        The first row (summary row) should not be able to be deleted or swiped left
        */
        if indexPath.row == 0 {
            return false
        }
        return true
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        /*
        The first row (summary row) has a slightly bigger row size than the rest of the rows
        */
        if indexPath.row == 0 && dbAccess.stocks.count > 0 {
            return 80
        } else {
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // This is needed to override the default functionality and let the row be edited
    }
    
    /*
    Create custom delete button in purple
    */
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        var deleteButton = UITableViewRowAction(style: .Default, title: "Delete", handler: { (action, indexPath) in
            self.dbAccess.stocks.removeAtIndex(indexPath.row - 1)
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            
            tableView.reloadData()
        })
        
        deleteButton.backgroundColor = Globals.UI_COLOR_LIGHT_PURPLE

        return [deleteButton]
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "AddStock" {
            let navigationController = segue.destinationViewController as! UINavigationController
            
            let controller = navigationController.topViewController as! StockDetailViewController
            
            controller.delegate = self
            
            controller.dbAccess = dbAccess
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

