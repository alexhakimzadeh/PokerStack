//
//  ModelsChipType.swift
//  PokerHostHelper
//
//  Created by Alex Hakimzadeh on 2/27/26.
//

import Foundation

struct ChipType: Identifiable, Hashable {
    let id = UUID()
    var colorName: String          // "White", "Red", etc.
    var denominationCents: Int     // e.g. 25 for $0.25, 100 for $1.00
    var quantity: Int              // total chips you own of this color
}
