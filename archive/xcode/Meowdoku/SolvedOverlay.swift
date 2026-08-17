//
//  SolvedOverlay.swift
//  Meowdoku
//

import SwiftUI

/// The card shown over the board once a puzzle is solved.
struct SolvedOverlay: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("Solved!")
                .font(.title2.bold())
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8)
    }
}

#Preview {
    SolvedOverlay()
}
