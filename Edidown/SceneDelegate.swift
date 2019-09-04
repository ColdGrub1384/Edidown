//
//  SceneDelegate.swift
//  Edidown
//
//  Created by Adrian Labbé on 03-09-19.
//  Copyright © 2019 Adrian Labbe. All rights reserved.
//

import UIKit

/// The scene delegate of the app.
class SceneDelegate: NSObject, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    @available(iOS 13.0, *)
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        let window = UIWindow(frame: (scene as? UIWindowScene)?.coordinateSpace.bounds ?? UIScreen.main.bounds)
        window.rootViewController = DocumentBrowserViewController(forOpeningFilesWithContentTypes: ["public.item"])
        window.accessibilityIgnoresInvertColors = true
        window.tintColor = UIColor(named: "TintColor")
        
        if let url = connectionOptions.urlContexts.first?.url {
            (window.rootViewController as? DocumentBrowserViewController)?.documentURL = url
        }
        
        window.windowScene = scene as? UIWindowScene
        self.window = window
        window.makeKeyAndVisible()
    }
    
    @available(iOS 13.0, *)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        
        // Ensure the URL is a file URL
        guard let url = URLContexts.first?.url, url.isFileURL else { return }
                
        // Reveal / import the document at the URL
        guard let documentBrowserViewController = window?.rootViewController as? DocumentBrowserViewController else { return }

        documentBrowserViewController.revealDocument(at: url, importIfNeeded: true) { (revealedDocumentURL, error) in
            if let error = error {
                // Handle the error appropriately
                print("Failed to reveal the document at URL \(url) with error: '\(error)'")
                return
            }
            
            // Present the Document View Controller for the revealed URL
            documentBrowserViewController.presentDocument(at: revealedDocumentURL!)
        }
    }
}
