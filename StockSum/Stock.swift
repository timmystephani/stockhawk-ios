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
}