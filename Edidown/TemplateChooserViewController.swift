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
    }
    
    /// Code called when a template is selected. Its value should be `importHandler` given by `UIDocumentBrowserViewController.documentBrowser(_:, didRequestDocumentCreationWithHandler:)`.
    var importHandler: (((URL?, UIDocumentBrowserViewController.ImportMode) -> Void))?
    
    /// The table view containing templates.
    @IBOutlet weak var tableView: UITableView!
    
    /// The type of templates to choose.
    var type = TemplateType.markdown {
        didSet {
            templatesName = []
            templatesURL = []
            for file in templates {
                templatesName.append(file.key)
                templatesURL.append(file.value)
            }
            tableView.reloadData()
        }
    }
    
    /// Choosable templates URLs per name depending on `type`.
    var templates: [String:URL] {
        
        guard let plistURL = Bundle.main.url(forResource: "Templates", withExtension: "plist"), var templatesURL = Bundle.main.url(forResource: "Templates", withExtension: nil) else {
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
        }
        
        return templates
    }
    
    // For `tableView`
    private var templatesName = [String]()
    private var templatesURL = [URL]()
    
    /// Cancels the import.
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true) {
            self.importHandler?(nil, .none)
        }
    }
    
    /// Changes between Markdown and HTML templates depending on `sender` state.
    ///
    /// - Parameters:
    ///     - sender: If its selected segment index is `0`, `type` will be `markdown` and if is `1`, `type` will be `html`.
    @IBAction func changeMode(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            type = .markdown
        } else if sender.selectedSegmentIndex == 1 {
            type = .html
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return templatesName.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = templatesName[indexPath.row]
        return cell
    }
    
    // MARK: - Table view delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true) {
            self.importHandler?(self.templatesURL[indexPath.row], .copy)
        }
    }
}
