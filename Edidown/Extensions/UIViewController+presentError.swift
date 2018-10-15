//
//  UIViewController+presentError.swift
//  Edidown
//
//  Created by Adrian Labbe on 10/15/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit

extension UIViewController {
    
    /// Presents an alert describing the given error.
    ///
    /// - Parameters:
    ///     - error: The error to show.
    ///     - title: The title of the error.
    func presentError(_ error: Error, withTitle title: String?) {
        let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    /// Presents an alert with given info.
    ///
    /// - Parameters:
    ///     - message: The message to show.
    ///     - title: The title of the error.
    func presentMessage(_ message: String?, withTitle title: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
