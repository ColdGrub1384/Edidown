//
//  DocumentBrowserViewController.swift
//  Edidown
//
//  Created by Adrian Labbe on 10/14/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import SafariServices

/// The main document browser.
class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate, UIViewControllerTransitioningDelegate, SettingsDelegate {
    
    /// Transition controller for presenting and dismissing View controllers.
    var transitionController: UIDocumentBrowserTransitionController?
    
    /// Shows the local web server in Safari.
    @objc func showLocalWebServer() {
        present(SFSafariViewController(url: WebServerManager.shared.serverURL ?? URL(string: "http://localhost")!), animated: true, completion: nil)
    }
    
    // MARK: - Document browser view controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        if SettingsManager.shared.isDarkModeEnabled {
            browserUserInterfaceStyle = .dark
        } else {
            browserUserInterfaceStyle = .white
        }
        
        allowsDocumentCreation = true
        allowsPickingMultipleItems = false
        additionalLeadingNavigationBarButtonItems = [UIBarButtonItem(image: UIImage(named: "www"), style: .plain, target: self, action: #selector(showLocalWebServer))]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        SettingsManager.shared.delegate = self
    }
    
    // MARK: Document browser view controller delegate
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let templateChooser = storyboard.instantiateViewController(withIdentifier: "TemplateChooserViewController") as! TemplateChooserViewController
        templateChooser.importHandler = importHandler
        let navVC = UINavigationController(rootViewController: templateChooser)
        navVC.modalPresentationStyle = .formSheet
        navVC.modalTransitionStyle = .crossDissolve
        present(navVC, animated: true, completion: nil)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        
        // Present the Document View Controller for the first document that was picked.
        // If you support picking multiple items, make sure you handle them all.
        presentDocument(at: sourceURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }
    
    // MARK: Document Presentation
    
    /// Present document at given URL.
    ///
    /// - Parameters:
    ///     - documentURL: The URL to present.
    func presentDocument(at documentURL: URL) {
        
        let documentViewController = DocumentViewController.makeViewController()
        
        let doc = Document(fileURL: documentURL)
        
        let vc = UINavigationController(rootViewController: documentViewController)
        vc.transitioningDelegate = self
        if #available(iOS 12.0, *) {
            vc.modalPresentationStyle = .custom
            documentViewController.loadViewIfNeeded()
            transitionController = transitionController(forDocumentAt: documentURL)
            transitionController?.loadingProgress = doc.progress
            transitionController?.targetView = documentViewController.textView
        }
        doc.open(completionHandler: { (success) in
            if success {
                documentViewController.document = doc
                self.present(vc, animated: true, completion: nil)
            } else {
                self.presentMessage("An error occurred while reading file.", withTitle: "Error reading file!")
            }
        })
    }
    
    // MARK: - View controller transition delegate
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionController
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionController
    }
    
    // MARK: - Settings delegate
    
    func settings(_ settings: SettingsManager, didToggleDarkMode darkMode: Bool) {
        if darkMode {
            browserUserInterfaceStyle = .dark
        } else {
            browserUserInterfaceStyle = .white
        }
    }
}

