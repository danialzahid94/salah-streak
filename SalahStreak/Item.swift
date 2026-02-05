//
//  Item.swift
//  SalahStreak
//
//  Created by Danial Zahid on 2026-02-05.
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
