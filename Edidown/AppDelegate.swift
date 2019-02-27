//
//  AppDelegate.swift
//  Edidown
//
//  Created by Adrian Labbe on 10/14/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import UserNotifications
import GCDWebServers
import Down

/// The app's delegate.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = DocumentBrowserViewController(forOpeningFilesWithContentTypes: ["public.item"])
        window?.accessibilityIgnoresInvertColors = true
        window?.tintColor = UIColor(named: "TintColor")
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { (_, _) in }
        
        // Web server
        
        application.beginBackgroundTask {
            print("Background task expired!")
        }
        let wwwDirectory = WebServerManager.shared.wwwDirectory
        do {
            if (try FileManager.default.contentsOfDirectory(at: wwwDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) == [], let indexURL = Bundle.main.url(forResource: "index", withExtension: "md") {
                try FileManager.default.copyItem(at: indexURL, to: wwwDirectory.appendingPathComponent(indexURL.lastPathComponent))
            }
        } catch {
            NSLog("%@", error.localizedDescription)
        }
        
        WebServerManager.shared.startServer()
        
        return true
    }
    
    func application(_ app: UIApplication, open inputURL: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Ensure the URL is a file URL
        guard inputURL.isFileURL else { return false }
                
        // Reveal / import the document at the URL
        guard let documentBrowserViewController = window?.rootViewController as? DocumentBrowserViewController else { return false }

        documentBrowserViewController.revealDocument(at: inputURL, importIfNeeded: true) { (revealedDocumentURL, error) in
            if let error = error {
                // Handle the error appropriately
                print("Failed to reveal the document at URL \(inputURL) with error: '\(error)'")
                return
            }
            
            // Present the Document View Controller for the revealed URL
            documentBrowserViewController.presentDocument(at: revealedDocumentURL!)
        }

        return true
    }


}

