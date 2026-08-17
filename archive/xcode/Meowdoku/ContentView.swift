//
//  ContentView.swift
//  Meowdoku
//
//  Created by the god unkn0wn on 2026/8/17.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("Meowdoku")
                .font(.largeTitle.bold())

            Picker("Board Size", selection: Binding(
                get: { viewModel.size },
                set: { viewModel.newPuzzle(size: $0) }
            )) {
                // 8+ isn't offered: PuzzleGenerator's random layout search stops
                // reliably finding a unique-solution puzzle above size 7 (see its
                // doc comment) - this crashed on launch when it was in this list.
                ForEach([4, 5, 6, 7], id: \.self) { size in
                    Text("\(size)×\(size)").tag(size)
                }
            }
            .pickerStyle(.segmented)

            ZStack {
                BoardView(viewModel: viewModel)
                    .disabled(viewModel.isSolved)
                    .blur(radius: viewModel.isSolved ? 3 : 0)

                if viewModel.isSolved {
                    SolvedOverlay()
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.isSolved)

            HStack(spacing: 12) {
                Button("Hint") {
                    viewModel.requestHint()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isSolved)

                Button("New Puzzle") {
                    viewModel.newPuzzle()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .sensoryFeedback(.success, trigger: viewModel.isSolved) { _, newValue in newValue }
    }
}

#Preview {
    ContentView()
}
