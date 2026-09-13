//
//  AppModel.swift
//  TrailMarkCh10
//
//  Created by Lemuel Gayle on 9/8/26.
//

import Foundation
import Observation
import TrialMarkCH10Core

@MainActor
@Observable
final class AppModel {
    let health = HealthKitManager()
    let media = MediaStore()
}
