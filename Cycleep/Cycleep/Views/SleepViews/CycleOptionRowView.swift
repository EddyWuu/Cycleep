//
//  CycleOptionRowView.swift
//  Cycleep
//
//  Reusable row showing a time + cycle count with a "Set" button.
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
                Text("\(option.cycles) cycle\(option.cycles > 1 ? "s" : "") · \(option.durationText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onSet) {
                Text("Set")
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        CycleOptionRowView(option: SleepCycleOption(cycles: 5, time: Date())) {}
    }
}
