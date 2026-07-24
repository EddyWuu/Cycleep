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

    var body: some View {
        NavigationStack {
            Form {
                Section("Sound") {
                    ForEach(AlarmSound.allCases) { sound in
                        Button {
                            viewModel.selectedSound = sound
                            audioService.preview(sound, rampUp: viewModel.rampUpEnabled)
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
