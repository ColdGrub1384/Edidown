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
        
        // Checkboxes
        html = html.replacingOccurrences(of: "<li>[x]", with: "<li style='list-style:none'><input type=checkbox disabled checked>")
        html = html.replacingOccurrences(of: "<li>[ ]", with: "<li style='list-style:none'><input type=checkbox disabled>")
        
        return html
    } catch {
        return str
    }
}
