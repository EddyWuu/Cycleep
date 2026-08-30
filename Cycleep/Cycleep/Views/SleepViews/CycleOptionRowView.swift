//
//  CycleOptionRowView.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import SwiftUI

struct CycleOptionRowView: View {
    let option: SleepCycleOption
    let onSet: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(option.time, style: .time)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("\(option.cycles) cycle\(option.cycles > 1 ? "s" : "") · \(option.durationText)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button(action: onSet) {
                Text("Set")
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .buttonBorderShape(.capsule)
            // Let the surrounding row tap handle presentation instead of the button.
            .allowsHitTesting(false)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSet)
    }
}

#Preview {
    List {
        CycleOptionRowView(option: SleepCycleOption(cycles: 5, time: Date())) {}
    }
}
