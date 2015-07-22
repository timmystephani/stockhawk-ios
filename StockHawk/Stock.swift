//
//  Stock.swift
//  StockSum
//
//  Created by Tim Stephani on 6/17/15.
//  Copyright (c) 2015 Tim Stephani. All rights reserved.
//

import Foundation

class Stock: NSObject, NSCoding {
    var numShares = 0
    
    var symbol = ""
    var name = ""
    var lastTradePriceOnly = (0.0)
    var change = (0.0)
    
    required init(coder aDecoder: NSCoder) {
        numShares = aDecoder.decodeIntegerForKey("numShares")
        symbol = aDecoder.decodeObjectForKey("symbol") as! String
        self.name = aDecoder.decodeObjectForKey("name") as! String
        lastTradePriceOnly = aDecoder.decodeDoubleForKey("lastTradePriceOnly")
        change = aDecoder.decodeDoubleForKey("change")
        
        super.init()
    }
    
    override init() {
        super.init()
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(numShares, forKey: "numShares")
        aCoder.encodeObject(symbol, forKey: "symbol")
        aCoder.encodeObject(name, forKey: "name")
        aCoder.encodeDouble(lastTradePriceOnly, forKey: "lastTradePriceOnly")
        aCoder.encodeDouble(change, forKey: "change")
    }
    
    func bindFromYahooDict(record: NSDictionary) {
        if let name = record["Name"] as? String {
            self.name = name
        }
        
        if let lastTradePriceOnly = record["LastTradePriceOnly"] as? NSString {
            self.lastTradePriceOnly = lastTradePriceOnly.doubleValue
        }
        
        if var change = record["Change"] as? String {
            if change.rangeOfString("+") != nil {
                change = change.stringByReplacingOccurrencesOfString("+", withString: "")
                self.change = (change as NSString).doubleValue
            } else {
                change = change.stringByReplacingOccurrencesOfString("-", withString: "")
                self.change = -(change as NSString).doubleValue
            }
        }
    }
}