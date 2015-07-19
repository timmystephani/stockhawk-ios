//
//  ViewController.swift
//  StockSum
//
//  Created by Tim Stephani on 6/17/15.
//  Copyright (c) 2015 Tim Stephani. All rights reserved.
//

import UIKit

class StockListViewController: UITableViewController, StockDetailViewControllerDelegate {

    var stocks: [Stock]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        refresh()
    }
    
    @IBAction func refresh() {
        var symbols = [String]()
        for stock in stocks {
            symbols.append(stock.symbol)
        }
        
        Functions.queryYahoo(symbols) { (succeeded, response) -> () in
            
            if let query = response["query"] as? NSDictionary {
                if let results = query["results"] as? NSDictionary {
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
            
            dispatch_async(dispatch_get_main_queue(), { () -> () in
                self.tableView.reloadData()
            })
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        stocks = [Stock]()
        
        var stock = Stock()
        stock.symbol = "YHOO"
        stock.numShares = 5
        stocks.append(stock)
        
        stock = Stock()
        stock.symbol = "AAPL"
        stock.numShares = 7
        stocks.append(stock)
        
        super.init(coder: aDecoder)
    }
    
    func getStockFromSymbol(symbol: String) -> Stock {
        for stock in stocks {
            if stock.symbol == symbol {
                return stock
            }
        }
        return Stock() // TODO: throw error
    }
    
  
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stocks.count + 1 // summary cell
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func stockDetailViewControllerDidCancel(controller: StockDetailViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func stockDetailViewController(controller: StockDetailViewController, didFinishAddingItem item: Stock) {
        let newRowIndex = stocks.count
        stocks.append(item)
        
        let indexPath = NSIndexPath(forRow: newRowIndex, inSection: 0)
        let indexPaths = [indexPath]
        
        tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        
        if indexPath.row < stocks.count {
            cell = tableView.dequeueReusableCellWithIdentifier("Stock") as! UITableViewCell
            
            let stock = stocks[indexPath.row]
            
            let symbol = cell.viewWithTag(1000) as! UILabel
            symbol.text = stock.symbol
            
            let price = cell.viewWithTag(1001) as! UILabel
            price.text = "$" + String(format:"%.2f", stock.lastTradePriceOnly) +
                " (" +  (stock.change >= 0 ? "+" : "") + String(format:"%.2f", stock.change) + ")"
            
            let name = cell.viewWithTag(1002) as! UILabel
            name.text = stock.name
            
            let gainLoss = cell.viewWithTag(1003) as! UILabel
            gainLoss.text = String(format:"%.2f", stock.change * Double(stock.numShares))
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier("Summary") as! UITableViewCell
            
            var gainLoss = 0.0
            var currentValue = 0.0
            var dayStartValue = 0.0
            for stock in stocks {
                currentValue += Double(stock.numShares) * stock.lastTradePriceOnly
                dayStartValue += Double(stock.numShares) * (stock.lastTradePriceOnly - stock.change)
                gainLoss += Double(stock.numShares) * stock.change
            }
            
            let summary = cell.viewWithTag(1004) as! UILabel
            summary.text = "Today's change: $" + String(format:"%.2f", gainLoss) + " (" +
                String(format:"%.2f", ((currentValue / dayStartValue) - 1) * 100) + "%" + ")"
            summary.textColor = UIColor(red: 0.04, green: 0.8, blue: 0.04, alpha: 1.0)

            let totalValue = cell.viewWithTag(1005) as! UILabel
            totalValue.text = "Total value: $" + String(format: "%.2f", currentValue)
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("AddEditStock", sender: self)
        
        //tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

        stocks.removeAtIndex(indexPath.row)

        let indexPaths = [indexPath]
        
        tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "AddEditStock" {
        
            let navigationController = segue.destinationViewController as! UINavigationController

            let controller = navigationController.topViewController as! StockDetailViewController

            controller.delegate = self
        }
    }


}

