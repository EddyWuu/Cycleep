import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sleep Cycle")) {
                    HStack {
                        Text("Default cycle length")
                        Spacer()
                        Text("90 min")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Notifications")) {
                    Toggle("Enable notifications", isOn: .constant(true))
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
