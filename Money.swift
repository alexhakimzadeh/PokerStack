//
//  UtilsMoney.swift
//  PokerHostHelper
//
//  Created by Alex Hakimzadeh on 2/27/26.
//

import Foundation

enum Money {
    /// "0.10" -> 10, "1" -> 100, "1.25" -> 125
    static func cents(from text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        // Accept "1", "1.2", "1.20", ".10"
        let normalized = trimmed.hasPrefix(".") ? "0" + trimmed : trimmed
        let parts = normalized.split(separator: ".", omittingEmptySubsequences: false)

        guard parts.count <= 2 else { return nil }

        let dollarsPart = parts[0]
        let centsPart = parts.count == 2 ? parts[1] : Substring("")

        guard let dollars = Int(dollarsPart) else { return nil }

        var cents = 0
        if !centsPart.isEmpty {
            // pad / trim to 2 digits
            let raw = String(centsPart)
            let padded = (raw + "00")
            let two = String(padded.prefix(2))
            guard let c = Int(two) else { return nil }
            cents = c
        }

        return dollars * 100 + cents
    }

    static func format(cents: Int) -> String {
        let absVal = abs(cents)
        let dollars = absVal / 100
        let c = absVal % 100
        let sign = cents < 0 ? "-" : ""
        return "\(sign)$\(dollars).\(String(format: "%02d", c))"
    }
}
