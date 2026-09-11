//
//  TrialMarkWatchCH10App.swift
//  TrialMarkWatchCH10 Watch App
//
//  Created by Lemuel Gayle on 9/8/26.
//

import SwiftUI
import TrialMarkCH10Core

@main
struct TrialMarkWatchCH10_Watch_AppApp: App {
    @State private var model = WatchAppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .task {
                    await model.health.requestAuthorization()
                }
        }
    }
}
