//
//  LogicChipAllocator.swift
//  PokerHostHelper
//
//  Created by Alex Hakimzadeh on 2/27/26.
//

import Foundation

struct AllocationResult {
    var perPlayer: [ChipType: Int]
    var bankLeft: [ChipType: Int]
    var perPlayerTotalCents: Int
    var feasible: Bool
    var message: String

    var perPlayerTotalString: String { Money.format(cents: perPlayerTotalCents) }
}

enum ChipAllocator {

    /// reservePercent: 0.0 to 1.0 (e.g. 0.30 keeps 30% of each chip color in bank)
    static func allocate(
        chips: [ChipType],
        players: Int,
        buyInCents: Int,
        reservePercent: Double
    ) -> AllocationResult {

        guard players > 0, buyInCents > 0 else {
            return .init(perPlayer: [:], bankLeft: [:], perPlayerTotalCents: 0, feasible: false,
                         message: "Players and buy-in must be greater than 0.")
        }

        let sorted = chips.sorted { $0.denominationCents > $1.denominationCents }

        // Reserve
        var availablePerType: [ChipType: Int] = [:]
        for t in sorted {
            let reserved = Int(Double(t.quantity) * reservePercent)
            let available = max(0, t.quantity - reserved)
            availablePerType[t] = available
        }

        // Quick feasibility: enough value after reserving?
        let totalAvailableValue = sorted.reduce(0) { acc, t in
            acc + (availablePerType[t, default: 0] * t.denominationCents)
        }
        let required = players * buyInCents
        if totalAvailableValue < required {
            return .init(
                perPlayer: [:],
                bankLeft: computeBankLeft(total: chips, perPlayer: [:], players: players),
                perPlayerTotalCents: 0,
                feasible: false,
                message: "Not enough chips after reserve. Need \(Money.format(cents: required)), have \(Money.format(cents: totalAvailableValue))."
            )
        }

        // Soft minimums to keep cash games playable (in cents denominations):
        // If you have these denominations, try to give this many per player.
        // Tune later in Settings.
        let softMinimumsByDenom: [Int: Int] = [
            25: 12,   // $0.25 chips
            100: 10,  // $1
            500: 8    // $5
        ]

        var perPlayer: [ChipType: Int] = [:]
        var remaining = buyInCents

        // 1) Apply soft minimums (small-ish chips first)
        let minDenoms = [25, 100, 500] // order matters: smallest to larger
        for denom in minDenoms {
            guard let type = sorted.first(where: { $0.denominationCents == denom }) else { continue }
            guard let minCount = softMinimumsByDenom[denom] else { continue }

            let totalAvail = availablePerType[type, default: 0]
            let maxPerPlayerBySupply = totalAvail / players
            let give = min(minCount, maxPerPlayerBySupply)

            if give > 0 {
                perPlayer[type] = give
                availablePerType[type] = totalAvail - (give * players)
                remaining -= give * denom
            }
        }

        // If soft mins overshot, trim from smallest denom upward
        if remaining < 0 {
            for type in sorted.reversed() { // smallest -> biggest
                let denom = type.denominationCents
                while remaining < 0, (perPlayer[type] ?? 0) > 0 {
                    perPlayer[type]! -= 1
                    availablePerType[type, default: 0] += players
                    remaining += denom
                }
            }
        }

        // 2) Greedy fill remaining with large chips
        for type in sorted {
            if remaining == 0 { break }

            let denom = type.denominationCents
            let totalAvail = availablePerType[type, default: 0]
            let maxPerPlayerBySupply = totalAvail / players
            let maxNeededByValue = remaining / denom
            let give = min(maxPerPlayerBySupply, maxNeededByValue)

            if give > 0 {
                perPlayer[type, default: 0] += give
                availablePerType[type] = totalAvail - (give * players)
                remaining -= give * denom
            }
        }

        // 3) Exact-fill with smallest denom (works if you have a denom that divides remaining)
        if remaining != 0 {
            if let smallest = sorted.last {
                let denom = smallest.denominationCents
                let totalAvail = availablePerType[smallest, default: 0]
                let maxPerPlayerBySupply = totalAvail / players

                // Need exact divisibility OR we can't do it exactly
                if remaining % denom == 0 {
                    let needed = remaining / denom
                    if needed <= maxPerPlayerBySupply {
                        perPlayer[smallest, default: 0] += needed
                        availablePerType[smallest] = totalAvail - (needed * players)
                        remaining = 0
                    }
                }
            }
        }

        let totalPerPlayer = perPlayer.reduce(0) { $0 + ($1.key.denominationCents * $1.value) }

        let bankLeft = computeBankLeft(total: chips, perPlayer: perPlayer, players: players)

        if totalPerPlayer != buyInCents {
            return .init(
                perPlayer: perPlayer,
                bankLeft: bankLeft,
                perPlayerTotalCents: totalPerPlayer,
                feasible: false,
                message: "Could not hit buy-in exactly. Closest per player: \(Money.format(cents: totalPerPlayer)). Consider adding a smaller denomination (e.g., $0.25 or $1) or lowering reserve."
            )
        }

        return .init(
            perPlayer: perPlayer,
            bankLeft: bankLeft,
            perPlayerTotalCents: totalPerPlayer,
            feasible: true,
            message: "Allocation successful."
        )
    }

    private static func computeBankLeft(
        total: [ChipType],
        perPlayer: [ChipType: Int],
        players: Int
    ) -> [ChipType: Int] {
        var left: [ChipType: Int] = [:]
        for t in total {
            let used = (perPlayer[t] ?? 0) * players
            left[t] = max(0, t.quantity - used)
        }
        return left
    }
}
