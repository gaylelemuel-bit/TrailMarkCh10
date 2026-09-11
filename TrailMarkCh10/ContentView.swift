//
//  ContentView.swift
//  TrailMarkCh10
//
//  Created by Lemuel Gayle on 9/8/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TodayDashboardView()
            .tabItem {
                Label("Today", systemImage: "sun.max.fill")
            }
    }
}

#Preview {
    ContentView()
        .environment(AppModel())
}
