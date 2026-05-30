import SwiftUI

struct AlarmsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("No alarms yet")
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            }
            .navigationTitle("Alarms")
        }
    }
}

#Preview {
    AlarmsView()
}
