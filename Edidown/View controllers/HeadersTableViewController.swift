//
//  HeadersTableViewController.swift
//  Edidown
//
//  Created by Adrian Labbe on 10/15/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit

class HeadersTableViewController: UITableViewController {
    
    var headersRanges = [Range<String.Index>]()
    
    var headers = [String]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    var selectionHandler: ((Range<String.Index>) -> Void)?
    
    @objc private func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    func configureLabel(label: UILabel, forHeader header: String) {
        var h = 0
        var hashes = ""
        var headerName = header
        while headerName.hasPrefix("#") {
            h += 1
            hashes += "#"
            headerName = String(headerName.dropFirst())
        }
        
        var textStyle: UIFont.TextStyle?
        
        switch h {
        case 1:
            textStyle = .title1
        case 2:
            textStyle = .title2
        case 3:
            textStyle = .title3
        default:
            textStyle = .title3
        }
        
        let font = UIFont(name: "Courier-Bold", size: UIFont.preferredFont(forTextStyle: textStyle ?? .body).pointSize)!
        let attributedString = NSMutableAttributedString(string: hashes, attributes: [.foregroundColor : UIColor.lightGray, .font : font])
        attributedString.append(NSAttributedString(string: headerName, attributes: [.font : font]))
        
        label.numberOfLines = 0
        label.text = header
        label.attributedText = attributedString
    }
    
    // MARK: - Table view controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return headers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        
        if let label = cell.textLabel {
            configureLabel(label: label, forHeader: headers[indexPath.row])
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let label = UILabel()
        configureLabel(label: label, forHeader: headers[indexPath.row])
        guard label.frame.height != 0 else {
            return tableView.rowHeight
        }
        return label.frame.height
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true) {
            self.selectionHandler?(self.headersRanges[indexPath.row])
        }
    }
}
