//
//  DocumentBrowserViewController.swift
//  Edidown
//
//  Created by Adrian Labbe on 10/14/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit

/// The main document browser.
class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate, UIViewControllerTransitioningDelegate {
    
    /// Transition controller for presenting and dismissing View controllers.
    var transitionController: UIDocumentBrowserTransitionController?
    
    // MARK: - Document browser view controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        allowsDocumentCreation = true
        allowsPickingMultipleItems = false
    }
    
    // MARK: Document browser viewController delegate
    
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
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let documentViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentViewController") as! DocumentViewController
        documentViewController.document = Document(fileURL: documentURL)
        
        let vc = UINavigationController(rootViewController: documentViewController)
        vc.transitioningDelegate = self
        if #available(iOS 12.0, *) {
            vc.modalPresentationStyle = .custom
            documentViewController.loadViewIfNeeded()
            transitionController = transitionController(forDocumentAt: documentURL)
            transitionController?.targetView = documentViewController.view
        }
        
        present(vc, animated: true, completion: nil)
    }
    
    // MARK: - View controller transition delegate
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionController
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionController
    }
}

