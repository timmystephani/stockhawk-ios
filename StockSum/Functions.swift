//
//  Functions.swift
//  StockSum
//
//  Created by Tim Stephani on 7/19/15.
//  Copyright (c) 2015 Tim Stephani. All rights reserved.
//
import UIKit

class Functions {
    static let YQL_URL = "https://query.yahooapis.com/v1/public/yql?format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&q="
    
    
    static func queryYahoo(symbols: [String], postCompleted : (succeeded: Bool, response: NSDictionary) -> ()) {
        
        var yqlQuery = "select * from yahoo.finance.quote where symbol in ('" + "','".join(symbols) + "')"
        
        yqlQuery = yqlQuery.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        
        //println(yqlUrl + yqlQuery)
        
        var request = NSMutableURLRequest(URL: NSURL(string: YQL_URL + yqlQuery)!)
        var session = NSURLSession.sharedSession()
        request.HTTPMethod = "GET"
        
        var err: NSError?
        
        var task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in

            var strData = NSString(data: data, encoding: NSUTF8StringEncoding)

            var err: NSError?
            var json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves, error: &err) as? NSDictionary
            
            if(err != nil) {
                postCompleted(succeeded: false, response: NSDictionary())
            }
            else {
                if let parseJSON = json {
                    postCompleted(succeeded: true, response: parseJSON)
                }
                else {
                    postCompleted(succeeded: false, response: NSDictionary())
                }
            }
        })
        
        task.resume()
    }
}
