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
        queryYahoo { (succeeded, response) -> () in
            
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
    
    func queryYahoo(postCompleted : (succeeded: Bool, response: NSDictionary) -> ()) {
        var yqlUrl = "https://query.yahooapis.com/v1/public/yql?format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&q="
        
        var symbols = [String]()
        for stock in stocks {
            symbols.append(stock.symbol)
        }
        
        var yqlQuery = "select * from yahoo.finance.quote where symbol in ('" + "','".join(symbols) + "')"
        yqlQuery = yqlQuery.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!

        println(yqlUrl + yqlQuery)
        
        
        var request = NSMutableURLRequest(URL: NSURL(string: yqlUrl + yqlQuery)!)
        var session = NSURLSession.sharedSession()
        request.HTTPMethod = "GET"
        
        var err: NSError?
        
        var task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            //println("Response: \(response)")
            var strData = NSString(data: data, encoding: NSUTF8StringEncoding)
            //println("Body:")
            //println(strData)
            var err: NSError?
            var json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves, error: &err) as? NSDictionary
            
            
            // Did the JSONObjectWithData constructor return an error? If so, log the error to the console
            if(err != nil) {
                println(err!.localizedDescription)
                println("Error could not parse JSON: '\(strData)'")
                //postCompleted(succeeded: false, msg: "Error")
            }
            else {
                if let parseJSON = json {
                    postCompleted(succeeded: true, response: parseJSON)
                    return
                }
                else {
                    // Woa, okay the json object was nil, something went worng. Maybe the server isn't running?
                    let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)
                    println("Error could not parse JSON: \(jsonStr)")
                    //postCompleted(succeeded: false, msg: "Error")
                }
            }
        })
        task.resume()
        
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stocks.count
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
            let cell = tableView.dequeueReusableCellWithIdentifier("Stock") as! UITableViewCell
            
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

