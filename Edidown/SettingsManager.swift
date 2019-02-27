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
    
    /// Called when dark mode is toggled.
    ///
    /// - Parameters:
    ///     - settings: Settings manager.
    ///     - darkMode: `true` if dark mode is enabled.
    func settings(_ settings: SettingsManager, didToggleDarkMode darkMode: Bool)
}

/// A class for managing settings.
class SettingsManager {
    
    /// The shared instance.
    static let shared = SettingsManager()
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(didToggleDarkMode(_:)), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    // MARK: - Instance
    
    private let defaults = UserDefaults.standard
    
    @objc private func didToggleDarkMode(_ notification: Notification) {
        delegate?.settings(self, didToggleDarkMode: isDarkModeEnabled)
    }
    
    /// Object that listens for changes.
    var delegate: SettingsDelegate?
    
    /// Returns `true` if Dark mode is enabled.
    var isDarkModeEnabled: Bool {
        get {
            return defaults.bool(forKey: "darkMode")
        }
        
        set {
            defaults.set(newValue, forKey: "darkMode")
            defaults.synchronize()
        }
    }
}
