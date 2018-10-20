//
//  DocumentViewController.swift
//  Edidown
//
//  Created by Adrian Labbe on 10/14/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import WebKit
import Down
import Highlightr
import SafariServices

/// The View controller for editing a Markdown file.
class DocumentViewController: UIViewController, WKNavigationDelegate {
    
    /// Returns a newly initialized instance from Storyboard.
    static func makeViewController() -> DocumentViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DocumentViewController") as! DocumentViewController
    }
    
    /// The segmented control for switching between edition and preview.
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    /// The bar button item for showing headers.
    @IBOutlet weak var showHeadersBarButtonItem: UIBarButtonItem!
    
    private var shouldShowHeadersOnWebViewDidLoad = false
    
    /// HTML code to be shown before the markdown or HTMl content. Put styles and metas.
    static var htmlHead: String {
        do {
            if let url = Bundle.main.url(forResource: "body", withExtension: "html") {
                return try String(contentsOf: url)
            } else {
                return ""
            }
        } catch {
            return ""
        }
    }
    
    /// The text storage used in `textView`.
    let textStorage = CodeAttributedString()
    
    /// The Text view containing the raw content.
    var textView: UITextView!
    
    /// The Web view containing the preview.
    var webView: WKWebView!
    
    /// The document to edit. This document should already be open. Should not be nil!
    var document: Document! {
        didSet {
            title = document.fileURL.lastPathComponent
            textView.text = document.text
            if pathExtension == "md" || pathExtension == "markdown" {
                segmentedControl.isHidden = false
                textStorage.language = "markdown"
            } else if pathExtension == "html" || pathExtension == "htm" {
                segmentedControl.isHidden = false
                textStorage.language = "xml"
            } else {
                segmentedControl.isHidden = true
            }
        }
    }
    
    /// The path extension of `document`.
    var pathExtension: String {
        return document.fileURL.pathExtension.lowercased()
    }
    
    /// Shows headers of markdown file.
    @IBAction func showHeaders(_ sender: UIBarButtonItem) {
        guard !webView.isHidden else {
            shouldShowHeadersOnWebViewDidLoad = true
            segmentedControl.selectedSegmentIndex = 1
            changeMode(segmentedControl)
            return
        }
        
        let vc = JSHeadersTableViewController()
        webView.evaluateJavaScript("getHeadersIndexes()") { (indexes, error) in
            if let indexes = indexes as? Int, indexes >= 0 {
                for i in 0...indexes {
                    vc.headersIndex.append(i)
                }
            }
        }
        webView.evaluateJavaScript("getHeaders()") { (headers, error) in
            if let headers = headers as? [String] {
                vc.headers = headers
            }
        }
        vc.selectionHandler = { index in
            self.webView.evaluateJavaScript("headers()[\(index)].scrollIntoView()", completionHandler: nil)
        }
        
        let navVC = UINavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .popover
        navVC.popoverPresentationController?.barButtonItem = sender
        present(navVC, animated: true, completion: nil)
    }
    
    /// Exports file.
    @IBAction func export(_ sender: UIBarButtonItem) {
        
        let url = document.fileURL
        
        guard sender.tag == 1 else { // Auto save
            document.save(to: url, for: .forOverwriting, completionHandler: { _ in
                sender.tag = 1
                self.export(sender)
            })
            return
        }
        sender.tag = 0
        
        func share(file: URL) {
            let controller = UIDocumentInteractionController(url: file)
            controller.presentOptionsMenu(from: sender, animated: true)
        }
        
        if pathExtension == "html" {
            let sheet = UIAlertController(title: "Export", message: "Please choose a format to export '\(url.lastPathComponent)'", preferredStyle: .actionSheet)
            
            sheet.addAction(UIAlertAction(title: "HTML", style: .default, handler: { (_) in
                share(file: url)
            }))
            
            sheet.addAction(UIAlertAction(title: "RTF", style: .default, handler: { (_) in // Export to RTF
                let fileURL = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0].appendingPathComponent(url.lastPathComponent).deletingPathExtension().appendingPathExtension("rtf")
                do {
                    guard let data = self.textView.text.data(using: .utf8) else {
                        self.presentMessage("An error occurred while encoding data.", withTitle: "Error exporting file!")
                        return
                    }
                    let string = try NSAttributedString(data: data, options: [NSAttributedString.DocumentReadingOptionKey.documentType : NSAttributedString.DocumentType.html], documentAttributes: nil)
                    if FileManager.default.createFile(atPath: fileURL.path, contents: try string.data(from: NSRange(location: 0, length: string.length), documentAttributes: [.documentType : NSAttributedString.DocumentType.rtf]), attributes: nil) {
                        share(file: fileURL)
                    } else {
                        self.presentMessage("An error occurred while creating file.", withTitle: "Error exporting file!")
                    }
                } catch {
                    self.presentError(error, withTitle: "Error exporting file!")
                }
            }))
            
            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            sheet.popoverPresentationController?.barButtonItem = sender
            present(sheet, animated: true, completion: nil)
        } else if pathExtension == "md" || pathExtension == "markdown" {
            
            let html = ParseMarkdown(textView.text)
            
            let sheet = UIAlertController(title: "Export", message: "Please choose a format to export '\(url.lastPathComponent)'", preferredStyle: .actionSheet)
            
            sheet.addAction(UIAlertAction(title: "Markdown", style: .default, handler: { (_) in
                share(file: url)
            }))
            
            sheet.addAction(UIAlertAction(title: "HTML", style: .default, handler: { (_) in // Export to HTML
                let fileURL = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0].appendingPathComponent(url.lastPathComponent).deletingPathExtension().appendingPathExtension("html")
                if FileManager.default.createFile(atPath: fileURL.path, contents: html.data(using: .utf8), attributes: nil) {
                    share(file: fileURL)
                } else {
                    self.presentMessage("An error occurred creating file.", withTitle: "Error exporting file!")
                }
            }))
            
            sheet.addAction(UIAlertAction(title: "RTF", style: .default, handler: { (_) in // Export to RTF
                let fileURL = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0].appendingPathComponent(url.lastPathComponent).deletingPathExtension().appendingPathExtension("rtf")
                do {
                    let string = try Down(markdownString: html).toAttributedString()
                    if FileManager.default.createFile(atPath: fileURL.path, contents: try string.data(from: NSRange(location: 0, length: string.length), documentAttributes: [.documentType : NSAttributedString.DocumentType.rtf]), attributes: nil) {
                        share(file: fileURL)
                    } else {
                        self.presentMessage("An error occurred creating file.", withTitle: "Error exporting file!")
                    }
                } catch {
                    self.presentError(error, withTitle: "Error exporting file!")
                }
            }))
            
            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            sheet.popoverPresentationController?.barButtonItem = sender
            present(sheet, animated: true, completion: nil)
        } else {
            share(file: url)
        }
    }
    
    /// Loads preview for file.
    func loadPreview() {
        if pathExtension == "md" || pathExtension == "markdown" {
            webView.loadHTMLString(DocumentViewController.htmlHead+"\n"+ParseMarkdown(textView.text), baseURL: nil)
        } else if pathExtension == "html" || pathExtension == "htm" {
            webView.loadHTMLString(DocumentViewController.htmlHead+"\n"+textView.text, baseURL: nil)
        }
    }
    
    /// Called to change between edit and preview mode.
    ///
    /// - Parameters:
    ///     - sender: The mode will be changed depending on this Segmented control state. 0 for editing and 1 for previewing.
    @IBAction func changeMode(_ sender: UISegmentedControl) {
        webView.isHidden = (sender.selectedSegmentIndex == 0)
        textView.isHidden = !webView.isHidden
        document.save(to: self.document!.fileURL, for: .forOverwriting, completionHandler: nil)
        
        if textView.isHidden {
            textView.resignFirstResponder()
        }
        
        loadPreview()
    }
    
    /// Dismisses keyboard or this View controller and save file.
    @IBAction func dismissDocumentViewController() {
        
        guard !textView.isFirstResponder else {
            textView.resignFirstResponder()
            document.save(to: self.document!.fileURL, for: .forOverwriting, completionHandler: nil)
            return
        }
        
        dismiss(animated: true) {
            self.document.text = self.textView.text
            self.document.save(to: self.document!.fileURL, for: .forOverwriting, completionHandler: { (success) in
                self.document.close(completionHandler: nil)
                
                if !success {
                    UIApplication.shared.keyWindow?.rootViewController?.presentMessage("An error occurred while saving '\(self.document!.fileURL.lastPathComponent)'", withTitle: "Error saving file!")
                }
            })
        }
    }
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        segmentedControl.isHidden = true
        
        textStorage.highlightr.setTheme(to: "xcode")
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer()
        layoutManager.addTextContainer(textContainer)
        
        textView = UITextView(frame: .zero, textContainer: textContainer)
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        view.addSubview(textView)
        
        webView = WKWebView(frame: .zero)
        webView.navigationDelegate = self
        webView.isHidden = true
        view.addSubview(webView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        textView.frame = view.safeAreaLayoutGuide.layoutFrame
        webView.frame = textView.frame
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        guard view != nil else {
            return
        }
        
        let wasFirstResponder = textView.isFirstResponder
        textView.resignFirstResponder()
        _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (_) in
            self.textView.frame = self.view.safeAreaLayoutGuide.layoutFrame
            self.webView.frame = self.textView.frame
            if wasFirstResponder {
                self.textView.becomeFirstResponder()
            }
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
    
    // MARK: - Web kit navigation delegate
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if let url = webView.url, url.scheme?.lowercased() == "http" || url.scheme?.lowercased() == "https" {
            webView.stopLoading()
            if webView.canGoBack {
                webView.goBack()
            }
            present(SFSafariViewController(url: url), animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if shouldShowHeadersOnWebViewDidLoad {
            shouldShowHeadersOnWebViewDidLoad = false
            showHeaders(showHeadersBarButtonItem)
        }
    }
}
