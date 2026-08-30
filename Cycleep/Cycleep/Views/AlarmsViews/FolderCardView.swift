//
//  FolderCardView.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-08-30.
//

import SwiftUI

/// A named folder holding a bedtime + wake-up pair, shown as a full-width panel
/// with the member alarms as inset boxes in two columns.
struct FolderCardView: View {
    let group: AlarmDisplayGroup
    var editing: Bool
    let onRename: () -> Void
    let onToggle: (AlarmModel) -> Void
    let onSelect: (AlarmModel) -> Void
    let onDelete: (AlarmModel) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onRename) {
                HStack(spacing: 8) {
                    Image(systemName: "moon.zzz.fill")
                        .foregroundStyle(Theme.accent)
                    Text(group.name ?? "Sleep Schedule")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(group.alarms) { alarm in
                    AlarmBoxView(alarm: alarm,
                                 fill: Theme.background,
                                 editing: editing,
                                 onToggle: { onToggle(alarm) },
                                 onSelect: { onSelect(alarm) },
                                 onDelete: { onDelete(alarm) })
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.surface.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    let gid = UUID()
    let group = AlarmDisplayGroup(
        id: gid.uuidString,
        name: "Weeknights",
        alarms: [
            AlarmModel(time: Date(), label: "Bedtime", kind: .sleep, cycles: 5,
                       groupID: gid, groupName: "Weeknights"),
            AlarmModel(time: Date(), label: "Wake up", kind: .wake, cycles: 5,
                       groupID: gid, groupName: "Weeknights")
        ],
        sortDate: Date())
    return ZStack {
        Theme.backgroundGradient.ignoresSafeArea()
        FolderCardView(group: group, editing: false, onRename: {},
                       onToggle: { _ in }, onSelect: { _ in }, onDelete: { _ in })
            .padding()
    }
}
