//
//  Document.swift
//  Edidown
//
//  Created by Adrian Labbe on 10/14/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit

/// Errors opening the document.
enum DocumentError: Error {
    case unableToParseText
    case unableToEncodeText
}

/// A document representing a Markdown or HTML file.
class Document: UIDocument {
    
    /// The text of the Markdown or HTML file to save.
    var text = ""
    
    override func contents(forType typeName: String) throws -> Any {
        guard let data = text.data(using: .utf8) else {
            throw DocumentError.unableToEncodeText
        }
        
        return data
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let data = contents as? Data else {
            // This would be a developer error.
            fatalError("*** \(contents) is not an instance of NSData.***")
        }
        
        guard let newText = String(data: data, encoding: .utf8) else {
            throw DocumentError.unableToParseText
        }
        
        text = newText
    }
}
