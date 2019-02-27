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
import MobileCoreServices

/// The View controller for editing a Markdown file.
class DocumentViewController: UIViewController, WKNavigationDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, SettingsDelegate {
    
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
    var textStorage: NSTextStorage!
    
    /// The Text view containing the raw content.
    var textView: UITextView!
    
    /// The Web view containing the preview.
    var webView: WKWebView!
    
    /// The navigation corresponding to the latest preview.
    var previewNavigation: WKNavigation?
    
    /// The document to edit. This document should already be open. Should not be nil!
    var document: Document! {
        didSet {
            title = document.fileURL.lastPathComponent
            
            segmentedControl.isHidden = false
            
            let layoutManager = NSLayoutManager()
            if pathExtension == "md" || pathExtension == "markdown" {
                textStorage = Storage()
                (textStorage as! Storage).theme = Theme(themePath: Bundle.main.path(forResource: "themes/\(themeName)", ofType: "json") ?? Bundle.main.bundleURL.appendingPathComponent("themes/\(themeName).json").path)
            } else {
                textStorage = CodeAttributedString()
                if SettingsManager.shared.isDarkModeEnabled {
                    (textStorage as! CodeAttributedString).highlightr.setTheme(to: themeName)
                } else {
                    (textStorage as! CodeAttributedString).highlightr.setTheme(to: themeName)
                }
            }
            
            textStorage.addLayoutManager(layoutManager)
            
            let textContainer = NSTextContainer()
            layoutManager.addTextContainer(textContainer)
            
            var isScript = false
            
            if pathExtension == "md" || pathExtension == "markdown" {
                (textStorage as? CodeAttributedString)?.language = "markdown"
            } else if pathExtension == "html" || pathExtension == "htm" {
                (textStorage as? CodeAttributedString)?.language = "xml"
            } else {
                isScript = true
            }
            
            textView = UITextView(frame: view.safeAreaLayoutGuide.layoutFrame, textContainer: textContainer)
            textView.isHidden = true
            textView.smartDashesType = .no
            textView.smartQuotesType = .no
            
            if !isScript {
                textView.autocorrectionType = .default
                textView.autocapitalizationType = .sentences
                textView.smartDashesType = .default
                textView.smartQuotesType = .default
                
                textView.backgroundColor = (textStorage as? Storage)?.theme?.backgroundColor
            } else {
                segmentedControl.isHidden = true
                showHeadersBarButtonItem.isEnabled = false
                
                textView.autocorrectionType = .no
                textView.autocapitalizationType = .none
                textView.smartDashesType = .no
                textView.smartQuotesType = .no
                
                // Syntax coloring
                
                let languages = NSDictionary(contentsOf: Bundle.main.bundleURL.appendingPathComponent("langs.plist"))! as! [String:[String]] // List of languages associated by file extensions
                
                if let languagesForFile = languages[document.fileURL.pathExtension.lowercased()] {
                    if languagesForFile.count > 0 {
                        (textStorage as? CodeAttributedString)?.language = languagesForFile[0]
                    }
                }
                
                textView.backgroundColor = (textStorage as? CodeAttributedString)?.highlightr.theme.themeBackgroundColor
            }
        }
    }
    
    /// The path extension of `document`.
    var pathExtension: String {
        return document.fileURL.pathExtension.lowercased()
    }
    
    /// The name of the theme to use.
    var themeName: String {
        if textStorage is Storage {
            if SettingsManager.shared.isDarkModeEnabled {
                return "one-dark"
            } else {
                return "one-light"
            }
        } else if textStorage is CodeAttributedString {
            if SettingsManager.shared.isDarkModeEnabled {
                return "atelier-cave-dark"
            } else {
                return "xcode"
            }
        } else {
            return ""
        }
    }
    
    /// Picks an image for embedding it.
    @IBAction func pickImage(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeImage as String]
        picker.delegate = self
        present(picker, animated: true, completion: nil)
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
        
        var code = ""
        
        let foregroundColor = (textStorage as? Storage)?.theme?.body.attributes[.foregroundColor] as? UIColor ?? .black
        
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        foregroundColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        var head = DocumentViewController.htmlHead
        head = head.replacingOccurrences(of: "%COLOR%", with: String(format:"#%06x", rgb))
        
        if pathExtension == "md" || pathExtension == "markdown" {
           code = head+"\n"+ParseMarkdown(textView.text)
        } else if pathExtension == "html" || pathExtension == "htm" {
            code = head+"\n"+textView.text
        }
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0]
        
        // Don't use `WKWebView.loadHTMLString(_:baseURL:)` because of permission problems
        let newFileURL = docs.appendingPathComponent(UUID().uuidString).appendingPathExtension("html")
        
        if let data = code.data(using: .utf8), FileManager.default.createFile(atPath: newFileURL.path, contents: data, attributes: nil) {
            previewNavigation = webView.loadFileURL(newFileURL, allowingReadAccessTo: docs)
        } else {
            presentMessage("An error occurred while loading preview.", withTitle: "Error loading preview!")
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
        
        webView = WKWebView(frame: .zero)
        webView.navigationDelegate = self
        webView.isHidden = true
        webView.backgroundColor = .clear
        webView.isOpaque = false
        view.addSubview(webView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let txtView = textView, txtView.superview == nil {
            view.addSubview(txtView)
            textView.text = document.text
            view.backgroundColor = txtView.backgroundColor
        }
        
        if SettingsManager.shared.isDarkModeEnabled {
            navigationController?.navigationBar.barStyle = .black
        } else {
            navigationController?.navigationBar.barStyle = .default
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        SettingsManager.shared.delegate = self
        
        textView.isHidden = false
        textView.frame = view.safeAreaLayoutGuide.layoutFrame
        webView.frame = textView.frame
        
        if SettingsManager.shared.isDarkModeEnabled {
            textView.keyboardAppearance = .dark
        } else {
            textView.keyboardAppearance = .default
        }
        
        if let txtView = textView, txtView.superview == nil {
            view.addSubview(txtView)
        }
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
        if let url = webView.url, navigation == previewNavigation {
            try? FileManager.default.removeItem(at: url)
        }
        if shouldShowHeadersOnWebViewDidLoad {
            shouldShowHeadersOnWebViewDidLoad = false
            showHeaders(showHeadersBarButtonItem)
        }
    }
    
    // MARK: - Image picker controleller delegate
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        dismiss(animated: true) {
            guard let url = info[.imageURL] as? URL else {
                self.presentMessage("An error occurred while importing image", withTitle: "Error importing image!")
                return
            }
            
            let newURL = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0].appendingPathComponent(url.lastPathComponent)
            let encodedName = url.lastPathComponent.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? url.lastPathComponent
            
            do {
                if FileManager.default.fileExists(atPath: newURL.path) {
                    try FileManager.default.removeItem(at: newURL)
                }
                try FileManager.default.copyItem(at: url, to: newURL)
                
                if self.pathExtension == "md" || self.pathExtension == "markdown" {
                    self.textView.insertText("\n![Image](\(encodedName))")
                } else if self.pathExtension == "html" || self.pathExtension == "htm" {
                    self.textView.insertText("\n<img src='\(encodedName)'>")
                }
                self.segmentedControl.selectedSegmentIndex = 0
                self.changeMode(self.segmentedControl)
            } catch {
                self.presentError(error, withTitle: "Error importing image!")
            }
        }
    }
    
    // MARK: - Settings delegate
    
    func settings(_ settings: SettingsManager, didToggleDarkMode darkMode: Bool) {
        
        if let mdStorage = textStorage as? Storage {
            mdStorage.theme = Theme(themePath: Bundle.main.path(forResource: "themes/\(themeName)", ofType: "json") ?? Bundle.main.bundleURL.appendingPathComponent("themes/\(themeName).json").path)
            textView.backgroundColor = mdStorage.theme?.backgroundColor
        } else if let codeStorage = textStorage as? CodeAttributedString {
            codeStorage.highlightr.setTheme(to: themeName)
            textView.backgroundColor = codeStorage.highlightr.theme.themeBackgroundColor
        }
        
        view.backgroundColor = textView.backgroundColor
        
        if darkMode {
            textView.keyboardAppearance = .dark
            navigationController?.navigationBar.barStyle = .black
            (presentingViewController as? UIDocumentBrowserViewController)?.browserUserInterfaceStyle = .dark
        } else {
            textView.keyboardAppearance = .default
            navigationController?.navigationBar.barStyle = .default
            (presentingViewController as? UIDocumentBrowserViewController)?.browserUserInterfaceStyle = .white
        }
        
        if !webView.isHidden {
            loadPreview()
        }
    }
}
