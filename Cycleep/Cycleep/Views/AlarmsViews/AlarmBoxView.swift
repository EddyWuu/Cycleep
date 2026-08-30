//
//  AlarmBoxView.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-08-30.
//

import SwiftUI

/// A single alarm rendered as a compact card ("box") for the Alarms grid.
struct AlarmBoxView: View {
    let alarm: AlarmModel
    /// Fill color of the card. Standalone alarms use `Theme.surface`; inside a
    /// folder they use a darker inset fill for depth.
    var fill: Color = Theme.surface
    /// When true, shows a delete badge instead of the enable toggle.
    var editing: Bool = false
    var onToggle: () -> Void
    var onSelect: () -> Void
    var onDelete: () -> Void

    private var isSleep: Bool { alarm.kind == .sleep }

    private var accentColor: Color { isSleep ? Theme.sleep : Theme.wake }

    private var iconName: String { isSleep ? "moon.stars.fill" : "sun.max.fill" }

    /// Compact one-line detail beneath the time.
    private var detail: String {
        var parts: [String] = []
        if !alarm.label.isEmpty { parts.append(alarm.label) }
        if let cycles = alarm.cycles { parts.append("\(cycles) cyc") }
        parts.append(alarm.isRepeating ? alarm.repeatSummary : "Once")
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .font(.headline)
                    .foregroundStyle(accentColor)
                Spacer()
                if editing {
                    // Affordance only — a single tap anywhere on the box deletes it.
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.red)
                        .symbolRenderingMode(.hierarchical)
                } else {
                    Toggle("", isOn: Binding(get: { alarm.isEnabled },
                                             set: { _ in onToggle() }))
                        .labelsHidden()
                        .tint(Theme.accent)
                }
            }

            Text(alarm.time, style: .time)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(detail)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)

            Text(alarm.sound.displayName)
                .font(.caption2.weight(.medium))
                .foregroundStyle(accentColor.opacity(0.9))
                .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Theme.accent.opacity(0.28), lineWidth: 1)
        )
        .opacity(alarm.isEnabled || editing ? 1 : 0.45)
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onTapGesture { editing ? onDelete() : onSelect() }
    }
}

#Preview {
    ZStack {
        Theme.backgroundGradient.ignoresSafeArea()
        HStack(spacing: 14) {
            AlarmBoxView(alarm: AlarmModel(time: Date(), label: "Wake up", kind: .wake, cycles: 5),
                         onToggle: {}, onSelect: {}, onDelete: {})
            AlarmBoxView(alarm: AlarmModel(time: Date(), label: "Bedtime", kind: .sleep,
                                           repeatDays: Weekday.weekdays),
                         onToggle: {}, onSelect: {}, onDelete: {})
        }
        .padding()
    }
}
