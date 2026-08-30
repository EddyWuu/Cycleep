//
//  AlarmsView.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import SwiftUI

struct AlarmsView: View {
    @EnvironmentObject private var alarmsViewModel: AlarmsViewModel
    @State private var editingAlarm: AlarmModel?
    @State private var isEditing = false
    @State private var renamingGroup: AlarmDisplayGroup?
    @State private var renameText = ""

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    /// Folder entries (bedtime + wake-up pairs), preserving display order.
    private var folders: [AlarmDisplayGroup] {
        alarmsViewModel.displayGroups.filter(\.isFolder)
    }

    /// Standalone alarms that fill the two-column grid, in display order.
    private var singles: [AlarmModel] {
        alarmsViewModel.displayGroups
            .filter { !$0.isFolder }
            .flatMap(\.alarms)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()

                if alarmsViewModel.alarms.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle("Alarms")
            .toolbar {
                if !alarmsViewModel.alarms.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(isEditing ? "Done" : "Edit") {
                            withAnimation(.easeInOut(duration: 0.2)) { isEditing.toggle() }
                        }
                        .foregroundStyle(Theme.textPrimary)
                    }
                }
            }
            .sheet(item: $editingAlarm) { alarm in
                AlarmConfigView(mode: .edit(alarm))
            }
            .alert("Rename Folder", isPresented: renameAlertBinding) {
                TextField("Folder name", text: $renameText)
                Button("Save") {
                    if let group = renamingGroup {
                        alarmsViewModel.renameGroup(group, to: renameText)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Give this bedtime + wake-up pair a name.")
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(folders) { group in
                    FolderCardView(
                        group: group,
                        editing: isEditing,
                        onRename: { startRename(group) },
                        onToggle: { alarmsViewModel.toggle($0) },
                        onSelect: { editingAlarm = $0 },
                        onDelete: { alarmsViewModel.delete($0) }
                    )
                }

                if !singles.isEmpty {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(singles) { alarm in
                            AlarmBoxView(
                                alarm: alarm,
                                editing: isEditing,
                                onToggle: { alarmsViewModel.toggle(alarm) },
                                onSelect: { editingAlarm = alarm },
                                onDelete: { alarmsViewModel.delete(alarm) }
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "alarm")
                .font(.system(size: 52))
                .foregroundStyle(Theme.accent)
            Text("No Alarms")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Set an alarm from the Sleep tab to see it here.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private var renameAlertBinding: Binding<Bool> {
        Binding(get: { renamingGroup != nil },
                set: { if !$0 { renamingGroup = nil } })
    }

    private func startRename(_ group: AlarmDisplayGroup) {
        renameText = group.name ?? ""
        renamingGroup = group
    }
}

#Preview {
    AlarmsView()
        .environmentObject(AlarmsViewModel())
}
