//
//  AlarmStoreService.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import Foundation

/// Persists alarms to disk as JSON so they survive relaunches. AlarmKit keeps
/// its own scheduled copies, but this is the app's source of truth for the list
/// the user sees and lets us re-arm AlarmKit on launch.
struct AlarmStoreService {
    private let fileURL: URL

    init(filename: String = "alarms.json") {
        let directory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = directory.appendingPathComponent(filename)
    }

    func load() -> [AlarmModel] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([AlarmModel].self, from: data)) ?? []
    }

    func save(_ alarms: [AlarmModel]) {
        guard let data = try? JSONEncoder().encode(alarms) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
