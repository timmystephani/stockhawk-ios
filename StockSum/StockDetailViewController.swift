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
    func stockDetailViewController(controller: StockDetailViewController, didFinishEditingItem item: Stock)
}

class StockDetailViewController: UITableViewController {

    var dataModel: DataModel!
    
    @IBOutlet weak var symbol: UITextField!
    @IBOutlet weak var numShares: UITextField!
    
    
    weak var delegate: StockDetailViewControllerDelegate?
    
    var stockToEdit: Stock?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Add Stock"
        if let item = stockToEdit {
            title = "Edit Stock"
            symbol.text = stockToEdit!.symbol
            numShares.text = String(stockToEdit!.numShares)
            symbol.enabled = false
            // NOT WORKING
            /*
            if let symbolView = tableView.viewWithTag(1007) {
                symbolView.backgroundColor = UIColor.lightGrayColor()
            }
            */
            
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        symbol.becomeFirstResponder()
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        textField.text = (textField.text as NSString).stringByReplacingCharactersInRange(range, withString: string.uppercaseString)

        return false
    }
    
    @IBAction func save() {
        if symbol.text == "" {
            showAlert("Error", message: "Please enter a symbol or click Cancel.")
            return
        } else if numShares.text == "" {
            numShares.text = "0"
        }
        
        if let stock = stockToEdit {
            stock.numShares = self.numShares.text.toInt()!
            self.delegate?.stockDetailViewController(self, didFinishEditingItem: stock)
        } else {
            if stockAlreadyExists(symbol.text) {
                self.showAlert("Error", message: "You already have that stock in your list.")
                return
            }
            
            var symbols = [String]()
            symbols.append(symbol.text)

            Functions.queryYahoo(symbols) { (succeeded, response) -> () in
                if succeeded {
                    var invalidSymbol = false
                    if self.hasNullResult(response) {
                        invalidSymbol = true
                    }

                    dispatch_async(dispatch_get_main_queue(), { () -> () in
                        if invalidSymbol {
                            self.showAlert("Error", message: "That symbol is not recognized by the Yahoo Finance API.")
                        } else {
                            let stock = Stock()
                            stock.symbol = self.symbol.text
                            stock.numShares = self.numShares.text.toInt()!
                            self.delegate?.stockDetailViewController(self, didFinishAddingItem: stock)
                        }
                    })
                } else {
                    self.showAlert("Error", message: "There was a problem refreshing the data. Please check your internet connection and try again.")
                }
            }
        }
    }
    
    /*
    Checks yahoo response to see if the "Name" value
    is null, which indicates the symbol is invalid 
    (not recognized by Yahoo API)
    */
    func hasNullResult(response: NSDictionary) -> Bool {
        if let query = response["query"] as? NSDictionary {
            if let results = query["results"] as? NSDictionary {
                if let quote = results["quote"] as? NSDictionary {
                    if let name = quote["Name"] as? String {
                        // valid
                    } else {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    func stockAlreadyExists(symbol: String) -> Bool {
        for stock in dataModel.stocks {
            if stock.symbol == symbol {
                return true
            }
        }
        
        return false
    }
    
    func showAlert(title: String, message: String) {
        var alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        var okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
            UIAlertAction in
        }
        alertController.addAction(okAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func cancel() {
        delegate?.stockDetailViewControllerDidCancel(self)
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return nil
    }

}
