//
//  AlarmConfigView.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import SwiftUI

struct AlarmConfigView: View {
    @StateObject private var viewModel: AlarmConfigViewModel
    @EnvironmentObject private var alarmsViewModel: AlarmsViewModel
    @Environment(\.dismiss) private var dismiss

    init(mode: AlarmConfigMode) {
        _viewModel = StateObject(wrappedValue: AlarmConfigViewModel(mode: mode))
    }

    /// Binds the preset menu to the view model, ignoring selections of "Custom".
    private var presetBinding: Binding<RepeatPreset?> {
        Binding(
            get: { viewModel.activePreset },
            set: { newValue in
                if let preset = newValue { viewModel.setRepeatPreset(preset) }
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(AlarmSound.allCases) { sound in
                        Button {
                            viewModel.selectedSound = sound
                        } label: {
                            HStack {
                                Label(sound.displayName, systemImage: sound.systemImage)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if viewModel.selectedSound == sound {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Sound")
                } footer: {
                    Text("Every sound fades in from silent to full over about a minute for a gentle wake-up.")
                }

                Section("Snooze") {
                    Picker("Snooze", selection: $viewModel.snoozeMinutes) {
                        ForEach(viewModel.snoozeOptions, id: \.self) { minutes in
                            Text(viewModel.snoozeLabel(minutes)).tag(minutes)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    Picker("Repeat", selection: presetBinding) {
                        Text("Custom").tag(RepeatPreset?.none)
                        ForEach(RepeatPreset.allCases) { preset in
                            Text(preset.rawValue).tag(RepeatPreset?.some(preset))
                        }
                    }
                    .pickerStyle(.menu)

                    HStack(spacing: 8) {
                        ForEach(Weekday.allCases) { day in
                            Button {
                                viewModel.toggleDay(day)
                            } label: {
                                Text(day.narrowName)
                                    .font(.subheadline.weight(.semibold))
                                    .frame(width: 34, height: 34)
                                    .background(
                                        Circle().fill(viewModel.repeatDays.contains(day)
                                                      ? Color.accentColor
                                                      : Color.secondary.opacity(0.15))
                                    )
                                    .foregroundStyle(viewModel.repeatDays.contains(day) ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                } header: {
                    Text("Repeat")
                } footer: {
                    Text(viewModel.repeatDays.isEmpty
                         ? "Fires once at the next occurrence."
                         : "Repeats \(viewModel.repeatSummary).")
                }

                Section {
                    Text(viewModel.summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.apply(using: alarmsViewModel)
                        // Confirm the save with a success haptic, then close the
                        // sheet to signal the alarm was saved.
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    AlarmConfigView(mode: .create(.wake(time: Date(), cycles: 5)))
        .environmentObject(AlarmsViewModel())
}
