import SwiftUI

struct SleepNowView: View {
    // For now use a default cycle length; real settings will come later
    private let cycleMinutes: Int = 90
    private let cyclesToShow: Int = 6

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("If you fall asleep now")) {
                    ForEach(1...cyclesToShow, id: \ .self) { cycle in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(cycle) cycle\(cycle > 1 ? "s" : "")")
                                    .font(.headline)
                                Text(wakeTimeText(for: cycle))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: {
                                // placeholder: schedule alarm for this time later
                            }) {
                                Text("Set")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Sleep Now")
            .listStyle(.insetGrouped)
        }
    }

    private func wakeTimeText(for cycle: Int) -> String {
        let totalMinutes = cycle * cycleMinutes
        let date = Calendar.current.date(byAdding: .minute, value: totalMinutes, to: Date()) ?? Date()
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}

#Preview {
    SleepNowView()
}
