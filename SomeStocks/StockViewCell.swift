//
//  StockViewCell.swift
//  SomeStocks
//
//  Created by Lyubomir Marinov on 10/9/15.
//  Copyright (c) 2015 Lyubomir Marinov. All rights reserved.
//

import UIKit

class StockViewCell: UITableViewCell {
    
    @IBOutlet weak var stockSymbolLabel:UILabel!;
    @IBOutlet weak var stockNameLabel:UILabel!;
    @IBOutlet weak var stockPriceLabel:UILabel!;
    @IBOutlet weak var stockDifferenceLabel:UILabel!;

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
