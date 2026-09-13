//
//  TrailMarkCh10App.swift
//  TrailMarkCh10
//
//  Created by Lemuel Gayle on 9/8/26.
//

import SwiftUI
import TrialMarkCH10Core

@main
struct TrailMarkCh10App: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
        }
    }
}
