//
//  AlarmRowView.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import SwiftUI

struct AlarmRowView: View {
    let alarm: AlarmModel
    let onToggle: () -> Void
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    Image(systemName: alarm.kind == .sleep ? "bed.double.fill" : "alarm.fill")
                        .foregroundStyle(alarm.kind == .sleep ? .indigo : .orange)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(alarm.time, style: .time)
                            .font(.title3.weight(.semibold))

                        HStack(spacing: 4) {
                            if !alarm.label.isEmpty {
                                Text(alarm.label)
                            }
                            if let cycles = alarm.cycles {
                                Text("· \(cycles) cycle\(cycles > 1 ? "s" : "")")
                            }
                            Text("· \(alarm.sound.displayName)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Toggle("", isOn: Binding(get: { alarm.isEnabled },
                                     set: { _ in onToggle() }))
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        AlarmRowView(alarm: AlarmModel(time: Date(), label: "Wake up", kind: .wake, cycles: 5),
                     onToggle: {}, onSelect: {})
        AlarmRowView(alarm: AlarmModel(time: Date(), label: "Bedtime", kind: .sleep, cycles: 5),
                     onToggle: {}, onSelect: {})
    }
}
