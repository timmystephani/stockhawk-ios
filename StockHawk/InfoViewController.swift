//
//  InfoViewController.swift
//  StockHawk
//
//  Created by Tim Stephani on 7/23/15.
//  Copyright (c) 2015 Tim Stephani. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {

    @IBOutlet weak var infoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Functions.addBorderToNavBar(self.navigationController!.navigationBar)
        
        infoLabel.text =
            "Instructions:\nPull the list of stocks down to refresh\nSwipe a stock left to delete\n\n" +
            "StockHawk uses the Yahoo! Finance API for stock quotes.\n\n" +
            "Questions or comments? I'd love to hear them! Please send me an email at stockhawkcontact@gmail.com\n\n" +
            "Special thanks to Mike Winkelmann (beeple-crap.com) for designing the app icon."

    }
    @IBAction func done() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}