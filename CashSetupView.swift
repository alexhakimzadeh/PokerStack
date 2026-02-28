//
//  CashSetupView.swift
//  PokerHostHelper
//
//  Created by Alex Hakimzadeh on 2/27/26.
//

import SwiftUI

struct CashSetupView: View {
    @State private var players: Int = 8
    @State private var buyInText: String = "20"     // dollars input
    @State private var reservePercent: Double = 0.30
    @State private var smallBlindText: String = "0.10"
    @State private var bigBlindText: String = "0.20"
    @State private var blindError: String? = nil

    @State private var chips: [ChipType] = [
        ChipType(colorName: "White", denominationCents: 25, quantity: 300),  // $0.25
        ChipType(colorName: "Red", denominationCents: 100, quantity: 300),   // $1
        ChipType(colorName: "Blue", denominationCents: 500, quantity: 200),  // $5
        ChipType(colorName: "Green", denominationCents: 2500, quantity: 120) // $25
    ]

    @State private var denomText: [UUID: String] = [:]
    @State private var qtyText: [UUID: String] = [:]

    @State private var result: AllocationResult?

    var body: some View {
        NavigationStack {
            Form {
                Section("Game") {
                    Stepper("Players: \(players)", value: $players, in: 1...50)

                    HStack {
                        Text("Buy-in")
                        Spacer()
                        TextField("20", text: $buyInText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    VStack(alignment: .leading) {
                        Text("Reserve: \(Int(reservePercent * 100))%")
                        Slider(value: $reservePercent, in: 0...0.70, step: 0.05)
                    }
                }
                
                Section("Blinds") {
                    HStack {
                        Text("Small Blind")
                        Spacer()
                        TextField("0.10", text: $smallBlindText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    HStack {
                        Text("Big Blind")
                        Spacer()
                        TextField("0.20", text: $bigBlindText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    if let blindError {
                        Text(blindError)
                            .foregroundStyle(.red)
                    }
                }

                Section("Chips (Denom in $)") {
                    ForEach($chips) { $chip in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(chip.colorName).font(.headline)

                            HStack {
                                Text("Denom")
                                Spacer()
                                TextField("0.25", text: Binding(
                                    get: {
                                        denomText[chip.id] ?? Money.format(cents: chip.denominationCents).replacingOccurrences(of: "$", with: "")
                                    },
                                    set: { denomText[chip.id] = $0 }
                                ))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                            }

                            HStack {
                                Text("Qty")
                                Spacer()
                                TextField("0", text: Binding(
                                    get: { qtyText[chip.id] ?? String(chip.quantity) },
                                    set: { qtyText[chip.id] = $0 }
                                ))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                            }
                        }
                    }
                }

                Button("Calculate") {
                    // Push text fields into model
                    for i in chips.indices {
                        let id = chips[i].id

                        if let dText = denomText[id], let cents = Money.cents(from: dText) {
                            chips[i].denominationCents = cents
                        }
                        if let qText = qtyText[id], let q = Int(qText.trimmingCharacters(in: .whitespacesAndNewlines)) {
                            chips[i].quantity = max(0, q)
                        }
                    }

                    guard let buyInCents = Money.cents(from: buyInText) else {
                        result = AllocationResult(perPlayer: [:], bankLeft: [:], perPlayerTotalCents: 0, feasible: false,
                                                  message: "Invalid buy-in amount.")
                        return
                    }

                    blindError = nil

                    guard let sbCents = Money.cents(from: smallBlindText),
                          let bbCents = Money.cents(from: bigBlindText) else {
                        blindError = "Invalid blind format. Examples: 0.10, 0.25, 1.00"
                        return
                    }

                    guard sbCents > 0, bbCents > 0 else {
                        blindError = "Blinds must be greater than $0.00"
                        return
                    }

                    guard bbCents >= sbCents else {
                        blindError = "Big Blind must be greater than or equal to Small Blind."
                        return
                    }
                    
                    result = ChipAllocator.allocate(
                        chips: chips,
                        players: players,
                        buyInCents: buyInCents,
                        reservePercent: reservePercent
                    )
                }

                if let result {
                    Section("Per Player") {
                        Text("Total: \(result.perPlayerTotalString)")
                            .font(.headline)

                        ForEach(chips.sorted(by: { $0.denominationCents > $1.denominationCents }), id: \.self) { t in
                            let count = result.perPlayer[t] ?? 0
                            if count > 0 {
                                HStack {
                                    Text("\(t.colorName) (\(Money.format(cents: t.denominationCents)))")
                                    Spacer()
                                    Text("\(count)")
                                }
                            }
                        }

                        Text(result.message)
                            .foregroundStyle(result.feasible ? .green : .orange)
                    }

                    Section("Bank Left") {
                        ForEach(chips.sorted(by: { $0.denominationCents > $1.denominationCents }), id: \.self) { t in
                            let left = result.bankLeft[t] ?? t.quantity
                            HStack {
                                Text("\(t.colorName) (\(Money.format(cents: t.denominationCents)))")
                                Spacer()
                                Text("\(left)")
                            }
                        }
                    }
                    Section("Blinds") {
                        Text("SB: \(Money.format(cents: Money.cents(from: smallBlindText) ?? 0))  •  BB: \(Money.format(cents: Money.cents(from: bigBlindText) ?? 0))")
                    }
                }
            }
            .navigationTitle("Cash Game Hosting")
        }
    }
}
