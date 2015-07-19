//
//  DataModel.swift
//  StockSum
//
//  Created by Tim Stephani on 7/19/15.
//  Copyright (c) 2015 Tim Stephani. All rights reserved.
//

import Foundation

class DataModel {
    var stocks = [Stock]()
    
    init() {
        loadStocks()
    }
    
    func documentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as! [String]
        return paths[0]
    }
    
    func dataFilePath() -> String {
            return documentsDirectory().stringByAppendingPathComponent("Stocks.plist")
    }
    
    func saveStocks() {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWithMutableData: data)
        
        archiver.encodeObject(stocks, forKey: "Stocks")
        archiver.finishEncoding()
        
        data.writeToFile(dataFilePath(), atomically: true)
    }
    
    func loadStocks() {
            let path = dataFilePath()
            
            if NSFileManager.defaultManager().fileExistsAtPath(path) {
            if let data = NSData(contentsOfFile: path) {
            let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)
            stocks = unarchiver.decodeObjectForKey("Stocks") as! [Stock]
            unarchiver.finishDecoding()
            }
            }
    }
}
