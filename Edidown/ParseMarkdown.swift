//
//  ParseMarkdown.swift
//  Edidown
//
//  Created by Adrian Labbe on 10/15/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import Down

/// Parses Markdown to HTML.
func ParseMarkdown(_ str: String) -> String {
    do {
        var html = try Down(markdownString: str).toHTML()
        
        let li = "<li style='list-style:none; margin-left: -20px;'>"
        let checkedBox = "<input type=checkbox disabled checked>"
        let uncheckedBox = "<input type=checkbox disabled>"
        
        // Checkboxes
        
        html = html.replacingOccurrences(of: "<li>[x]", with: li+checkedBox)
        html = html.replacingOccurrences(of: "<li>[ ]", with: li+uncheckedBox)
        
        html = html.replacingOccurrences(of: "<li>\n<p>[x]", with: "\(li)<p>"+checkedBox)
        html = html.replacingOccurrences(of: "<li>\n<p>[ ]", with: "\(li)<p>"+uncheckedBox)
        
        return html
    } catch {
        return str
    }
}
