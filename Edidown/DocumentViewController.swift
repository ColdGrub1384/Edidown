//
//  DocumentViewController.swift
//  Edidown
//
//  Created by Adrian Labbe on 10/14/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import MarkdownTextView
import WebKit
import Down

/// The View controller for editing a Markdown file.
class DocumentViewController: UIViewController {
    
    /// The Text view containing the raw content.
    var textView: UITextView!
    
    /// The Web view containing the preview.
    var webView: WKWebView!
    
    /// The document to edit.
    var document: Document?
    
    /// Called to change between edit and preview mode.
    ///
    /// - Parameters:
    ///     - sender: The mode will be changed depending on this Segmented control state. 0 for editing and 1 for previewing.
    @IBAction func changeMode(_ sender: UISegmentedControl) {
        webView.isHidden = (sender.selectedSegmentIndex == 0)
        textView.isHidden = !webView.isHidden
        do {
            webView.loadHTMLString("<meta name='viewport' content='width=device-width, initial-scale=1.0'> <style> * { font-family: 'Helvetica', 'Arial', sans-serif; } </style>"+(try Down(markdownString: textView.text).toHTML()), baseURL: nil)
        } catch {
            webView.loadHTMLString("<meta name='viewport' content='width=device-width, initial-scale=1.0'><br/>"+error.localizedDescription, baseURL: nil)
        }
        
    }
    
    /// Dismisses keyboard or this View controller and save file.
    @IBAction func dismissDocumentViewController() {
        
        guard !textView.isFirstResponder else {
            textView.resignFirstResponder()
            return
        }
        
        dismiss(animated: true) {
            self.document?.text = self.textView.text
            self.document?.save(to: self.document!.fileURL, for: .forOverwriting, completionHandler: { (success) in
                self.document?.close(completionHandler: nil)
                
                if !success {
                    // TODO: Handle error
                }
            })
        }
    }
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView = MarkdownTextView(frame: .zero)
        view.addSubview(textView)
        
        webView = WKWebView(frame: view.frame)
        webView.isHidden = true
        view.addSubview(webView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Access the document
        document?.open(completionHandler: { (success) in
            if success {
                // Display the content of the document, e.g.:
                self.title = self.document?.fileURL.lastPathComponent
                self.textView.text = self.document?.text
            } else {
                // TODO: Handle error
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        textView.frame = view.safeAreaLayoutGuide.layoutFrame
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        guard view != nil else {
            return
        }
        
        _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (_) in
            self.textView.frame = self.view.safeAreaLayoutGuide.layoutFrame
        }) // TODO: Anyway to to it without a timer?
    }
    
    // MARK: - Keyboard
    
    /// Resize `textView`.
    @objc func keyboardWillShow(_ notification:Notification) {
        let d = notification.userInfo!
        var r = d[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        
        r = textView.convert(r, from:nil)
        textView.contentInset.bottom = r.size.height
        textView.scrollIndicatorInsets.bottom = r.size.height
    }
    
    /// Set `textView` to the default size.
    @objc func keyboardWillHide(_ notification:Notification) {
        textView.contentInset = .zero
        textView.scrollIndicatorInsets = .zero
    }
}
