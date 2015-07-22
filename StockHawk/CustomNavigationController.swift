//
//  CustomNavigationController.swift
//  StockSum
//
//  Created by Tim Stephani on 7/20/15.
//  Copyright (c) 2015 Tim Stephani. All rights reserved.
//

import UIKit

class CustomNavigationController: UINavigationController {
    
    /*
    Class exists soley to change the status bar to white so
    it shows up with the dark nav bar
    */
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

}
