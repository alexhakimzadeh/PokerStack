//
//  CardView.swift
//  PokerHostHelper
//
//  Created by Alex Hakimzadeh on 3/1/26.
//

import SwiftUI

struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(AppColors.card)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}
