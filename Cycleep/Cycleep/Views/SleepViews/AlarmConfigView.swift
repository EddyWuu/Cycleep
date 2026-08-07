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
    @EnvironmentObject private var audioService: AlarmAudioService
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
                Section("Sound") {
                    ForEach(AlarmSound.allCases) { sound in
                        Button {
                            viewModel.selectedSound = sound
                            audioService.preview(sound)
                        } label: {
                            HStack {
                                Label(sound.displayName, systemImage: sound.systemImage)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if audioService.previewingSound == sound {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .foregroundStyle(.secondary)
                                }
                                if viewModel.selectedSound == sound {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
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
                    Toggle("Ramp up volume", isOn: $viewModel.rampUpEnabled)
                } footer: {
                    Text("Fades the sound in gradually so you wake up gently. AlarmKit still fires a backup alert if the app isn't running.")
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
                        audioService.stop()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        audioService.stop()
                        viewModel.apply(using: alarmsViewModel)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onDisappear { audioService.stop() }
        }
    }
}

#Preview {
    AlarmConfigView(mode: .create(.wake(time: Date(), cycles: 5)))
        .environmentObject(AlarmsViewModel())
        .environmentObject(AlarmAudioService())
}
