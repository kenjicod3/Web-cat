//
//  Item.swift
//  Webcat
//
//  Created by Hoang Le Minh on 14/4/25.
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
