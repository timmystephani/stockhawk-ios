//
//  StockDetailViewController.swift
//  StockSum
//
//  Created by Tim Stephani on 6/17/15.
//  Copyright (c) 2015 Tim Stephani. All rights reserved.
//

import UIKit

protocol StockDetailViewControllerDelegate: class {
    func stockDetailViewControllerDidCancel(controller: StockDetailViewController)
    func stockDetailViewController(controller: StockDetailViewController, didFinishAddingItem item: Stock)
}

class StockDetailViewController: UITableViewController {

    @IBOutlet weak var symbol: UITextField!
    @IBOutlet weak var numShares: UITextField!
    
    weak var delegate: StockDetailViewControllerDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Add Stock"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        symbol.becomeFirstResponder()
    }
    
    @IBAction func save() {
        var symbols = [String]()
        symbols.append(symbol.text)
        
        Functions.queryYahoo(symbols) { (succeeded, response) -> () in
            var invalidSymbol = false
            
            if let query = response["query"] as? NSDictionary {
                if let results = query["results"] as? NSDictionary {
                    if let quote = results["quote"] as? NSDictionary {
                        if let name = quote["Name"] as? String {
                           // valid
                        } else {
                            invalidSymbol = true
                        }
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> () in
                if invalidSymbol {
                    var alert = UIAlertView(title: "Error!", message: "That symbol is not recognized by the Yahoo Finance API", delegate: nil, cancelButtonTitle: "Ok")
                    alert.show()
                } else {
                    let stock = Stock()
                    stock.symbol = self.symbol.text
                    stock.numShares = self.numShares.text.toInt()!
                    self.delegate?.stockDetailViewController(self, didFinishAddingItem: stock)
                }
            })
        }
    }
    
    @IBAction func cancel() {
        delegate?.stockDetailViewControllerDidCancel(self)
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return nil
    }

}
