//
//  ContentView.swift
//  TrialMarkWatchCH10 Watch App
//
//  Created by Lemuel Gayle on 9/8/26.
//

import SwiftUI
import TrialMarkCH10Core

struct ContentView: View {
    var body: some View {
        // Vertical paging keeps each screen focused on a single task and lets
        // the Digital Crown move between them — the watch-native navigation model.
        // One shared NavigationStack: nesting a stack inside each page crashes
        // watchOS's paging navigation bar.
        NavigationStack {
            TabView {
                WristHomeView()
                WristMemoView()
                LiveVitalsView()
                MotionView()
            }
            .tabViewStyle(.verticalPage)
        }
    }
}

#Preview {
    ContentView()
        .environment(WatchAppModel())
}
