//
//  SettingsManager.swift
//  Edidown
//
//  Created by Adrian Labbé on 2/27/19.
//  Copyright © 2019 Adrian Labbe. All rights reserved.
//

import Foundation

/// A protocol that listen for settings.
protocol SettingsDelegate {
    
}

/// A class for managing settings.
class SettingsManager {
    
    /// The shared instance.
    static let shared = SettingsManager()
    private init() {
    }
    
    // MARK: - Instance
    
    private let defaults = UserDefaults.standard
    
    /// Object that listens for changes.
    var delegate: SettingsDelegate?
}
