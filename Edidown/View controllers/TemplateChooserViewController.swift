//
//  TemplateChooserViewController.swift
//  Edidown
//
//  Created by Adrian Labbe on 10/15/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit

/// The View controller for choosing a file template.
class TemplateChooserViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    /// An enum representing file template types to choose.
    enum TemplateType {
        
        /// A markdown document.
        case markdown
        
        /// An HTML document.
        case html
        
        /// Code.
        case code
        
        /*/// Math tex.
        case mathTex*/
        
        /// A plain text document.
        case txt
    }
    
    /// Code called when a template is selected. Its value should be `importHandler` given by `UIDocumentBrowserViewController.documentBrowser(_:, didRequestDocumentCreationWithHandler:)`.
    var importHandler: (((URL?, UIDocumentBrowserViewController.ImportMode) -> Void))?
    
    /// The table view containing templates.
    @IBOutlet weak var tableView: UITableView!
    
    /// The type of templates to choose.
    var type = TemplateType.markdown {
        didSet {
            
            templatesName = [:]
            templatesURL = [:]
            
            let activityIndicator = UIActivityIndicatorView(style: .gray)
            activityIndicator.startAnimating()
            
            tableView.reloadData()
            tableView.backgroundView = activityIndicator
            
            DispatchQueue.global().async { // Sorting an array can take a lot of time
                
                let currentType = self.type
                
                let keys = self.templates.keys.sorted(by: { $0.lowercased() < $1.lowercased() })
                for key in keys {
                    guard currentType == self.type else {
                        break
                    }
                    
                    guard let firstChar = key.first else {
                        continue
                    }
                    
                    let first = String(firstChar)
                    
                    if !(self.templatesName[first] != nil) {
                        self.templatesName[first] = [String]()
                    }
                    
                    self.templatesName[first] = self.templatesName[first]!+[key]
                    self.templatesURL[key] = self.templates[key]!
                }
                
                DispatchQueue.main.async {
                    self.tableView.backgroundView = nil
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    /// Choosable templates URLs per name depending on `type`.
    var templates: [String:URL] {
        
        guard
            let plistURL = Bundle.main.url(forResource: "Templates", withExtension: "plist"),
            let langsURL = Bundle.main.url(forResource: "langs", withExtension: "plist"),
            var templatesURL = Bundle.main.url(forResource: "Templates", withExtension: nil) else {
            return [:]
        }
        var templates = [String:URL]()
        
        if type == .markdown, let templatesDict = NSDictionary(contentsOf: plistURL)?["Markdown"] as? [String:String] {
            templatesURL.appendPathComponent("Markdown")
            
            for file in templatesDict {
                templates[file.key] = templatesURL.appendingPathComponent(file.value)
            }
        } else if type == .html, let templatesDict = NSDictionary(contentsOf: plistURL)?["HTML"] as? [String:String] {
            
            templatesURL.appendPathComponent("HTML")
            
            for file in templatesDict {
                templates[file.key] = templatesURL.appendingPathComponent(file.value)
            }
        /*} else if type == .mathTex, let templatesDict = NSDictionary(contentsOf: plistURL)?["Tex"] as? [String:String] {
            
            templatesURL.appendPathComponent("Tex")
            
            for file in templatesDict {
                templates[file.key] = templatesURL.appendingPathComponent(file.value)
            }*/
        } else if type == .txt, let templatesDict = NSDictionary(contentsOf: plistURL)?["TXT"] as? [String:String] {
            
            templatesURL.appendPathComponent("TXT")
            
            for file in templatesDict {
                templates[file.key] = templatesURL.appendingPathComponent(file.value)
            }
        } else if type == .code, let templatesDict = NSDictionary(contentsOf: langsURL) {
            templatesURL.appendPathComponent("Code/Untitled")
            
            for file in templatesDict {
                if let key = file.key as? String {
                    templates[key] = templatesURL.appendingPathExtension(key)
                }
            }
        }
        
        return templates
    }
    
    // For `tableView`
    private var templatesName = [String:[String]]()
    private var templatesURL = [String:URL]()
    
    /// Cancels the import.
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true) {
            self.importHandler?(nil, .none)
        }
    }
    
    /// Changes between Markdown and HTML templates depending on `sender` state.
    ///
    /// - Parameters:
    ///     - sender: If its selected segment index is `0`, `type` will be `markdown`, if is `1`, `type` will be `html` and `txt` if is `2`.
    @IBAction func changeMode(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            type = .markdown
        } else if sender.selectedSegmentIndex == 1 {
            type = .html
        } else if sender.selectedSegmentIndex == 2 {
            type = .code
        } else if sender.selectedSegmentIndex == 3 {
            type = .txt
        }
    }
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        type = .markdown
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return templatesName.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return templatesName[((templatesName as NSDictionary).allKeys as! [String]).sorted(by: { $0.lowercased() < $1.lowercased() } )[section]]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = templatesName[templatesName.keys.sorted(by: { $0.lowercased() < $1.lowercased() })[indexPath.section]]?[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if type == .code {
            return templatesName.keys.sorted(by: { $0.lowercased() < $1.lowercased() })[section]
        } else {
            return nil
        }
    }
    
    // MARK: - Table view delegate
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if type == .code {
            return templatesName.keys.sorted(by: {$0.lowercased() < $1.lowercased()})
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard var url = self.templatesURL[self.templatesName[self.templatesName.keys.sorted(by: { $0.lowercased() < $1.lowercased() })[indexPath.section]]?[indexPath.row] ?? ""] else {
            return
        }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(url.lastPathComponent)
            FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
        }
        
        dismiss(animated: true) {
            
            let alert = UIAlertController(title: "Create \(url.pathExtension)", message: "Type the new file name excluding the extension", preferredStyle: .alert)
            alert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "File name"
            })
            alert.addAction(UIAlertAction(title: "Create", style: .default, handler: { (_) in
                var title = alert.textFields?.first?.text ?? "Untitled"
                if title.isEmpty {
                    title = "Untitled"
                }
                let newURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(title).appendingPathExtension(url.pathExtension)
                if FileManager.default.fileExists(atPath: newURL.path) {
                    try? FileManager.default.removeItem(at: newURL)
                }
                do {
                    try FileManager.default.copyItem(at: url, to: newURL)
                    self.importHandler?(newURL, .copy)
                } catch {
                    UIApplication.shared.keyWindow?.rootViewController?.presentError(error, withTitle: "Error copying template!")
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            UIApplication.shared.keyWindow?.topViewController?.present(alert, animated: true, completion: nil)
        }
    }
}
