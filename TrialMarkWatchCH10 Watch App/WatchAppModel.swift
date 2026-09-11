//
//  WatchAppModel.swift
//  TrialMarkWatchCH10 Watch App
//
//  Created by Lemuel Gayle on 9/8/26.
//

import Foundation
import TrialMarkCH10Core

@MainActor
@Observable
final class WatchAppModel {
    let health = HealthKitManager()
}
