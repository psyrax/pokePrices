//
//  Item.swift
//  Prices
//
//  Created by Psyrax on 01/02/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
