//
//  WebServer.swift
//  Edidown
//
//  Created by Adrian Labbe on 10/20/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import GCDWebServers
import UserNotifications

/// An object managing the app's web server.
class WebServerManager: NSObject, GCDWebServerDelegate, UNUserNotificationCenterDelegate {
    private override init() {}
    
    /// The shared instance.
    static let shared = WebServerManager()
    
    /// The Web server.
    let webServer = GCDWebServer()
    
    /// Returns an URL for accessing `webServer`.
    private(set) var serverURL: URL?
    
    /// The base directory for the web server.
    var wwwDirectory = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0]
    
    /// A web server response for a 404 error.
    ///
    /// - Returns: A ready to return `GCDWebServerResponse`.
    var error404: GCDWebServerResponse? {
        let errorResponse = GCDWebServerDataResponse(html: DocumentViewController.htmlHead+"\n<h1>Error 404</h1>File not found. If you are '\(UIDevice.current.name)' owner, you can add the file into the Edidown's local directory.")
        errorResponse?.statusCode = 404
        return errorResponse
    }
    
    /// A web server response for browsing files in given directory.
    ///
    /// - Parameters:
    ///     - directory: The directory to browse.
    ///
    /// - Returns: A ready to return `GCDWebServerResponse`.
    func fileBrowser(forDirectory directory: String) -> GCDWebServerResponse? {
        var code = DocumentViewController.htmlHead+"\n<h1> Files in \(directory)</h1>"
        
        for file in (try? FileManager.default.contentsOfDirectory(atPath: wwwDirectory.appendingPathComponent(directory).path)) ?? [] {
            if !file.hasPrefix(".") {
                code += "<a href='\((directory as NSString).appendingPathComponent(file))'>\(file)</a><br/>"
            }
        }
        
        return GCDWebServerDataResponse(html: code)
    }
    
    private var requestedResponses = [String : GCDWebServerResponse]()
    private var sentResponses = [String : GCDWebServerResponse]()
    private var semaphores = [String : DispatchSemaphore]()
    private var allowedAddresses = [Data]()
    private var requestingAddresses = [String : Data]()
    
    /// Starts and setups `webServer`.
    func startServer() {
        
        func response(forFile file: URL) -> GCDWebServerResponse? {
            do {
                if file.pathExtension.lowercased() == "md" || file.pathExtension.lowercased() == "markdown" {
                    return GCDWebServerDataResponse(html: DocumentViewController.htmlHead+ParseMarkdown(try String(contentsOf: file)))
                } else if file.pathExtension.lowercased() == "html" || file.pathExtension.lowercased() == "htm" {
                    return GCDWebServerDataResponse(html: DocumentViewController.htmlHead+(try String(contentsOf: file)))
                } else {
                    return GCDWebServerFileResponse(file: file.path)
                }
            } catch {
                let errorResponse = GCDWebServerDataResponse(html: "<h1>Error</h1><p>\(error.localizedDescription)</p>")
                errorResponse?.statusCode = 500
                return errorResponse
            }
        }
        
        let webServer = GCDWebServer()
        webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse? in
            
            let notifContent = UNMutableNotificationContent()
            notifContent.title = request.url.absoluteString
            
            var notifBody: String {
                get {
                    return notifContent.body
                }
                
                set {
                    
                    let id = request.url.absoluteString
                    
                    guard !self.allowedAddresses.contains(request.localAddressData) else {
                        return
                    }
                    
                    let allowAction = UNNotificationAction(identifier: "allow", title: "Allow", options: [])
                    let disallowAction = UNNotificationAction(identifier: "disallow", title: "Disallow", options: [])
                    let category = UNNotificationCategory(identifier: "serverEvent", actions: [allowAction, disallowAction], intentIdentifiers: [], options: [])
                    
                    notifContent.body = newValue
                    notifContent.categoryIdentifier = "serverEvent"
                    
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                    let request = UNNotificationRequest(identifier: request.url.absoluteString, content: notifContent, trigger: trigger)
                    UNUserNotificationCenter.current().setNotificationCategories([category])
                    UNUserNotificationCenter.current().delegate = self
                    
                    UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
                        if settings.authorizationStatus == .denied {
                            self.requestingAddresses[id] = nil
                            self.sentResponses[id] = self.requestedResponses[id]
                            self.semaphores[id]?.signal()
                        } else {
                            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                        }
                    })
                }
            }
            
            func send(response: GCDWebServerResponse?, notificationBody: String) -> GCDWebServerResponse? {
                guard !self.allowedAddresses.contains(request.localAddressData) else {
                    return response
                }
                self.requestingAddresses[request.url.absoluteString] = request.localAddressData
                self.requestedResponses[request.url.absoluteString] = response
                self.semaphores[request.url.absoluteString] = DispatchSemaphore(value: 0)
                notifBody = notificationBody
                self.semaphores[request.url.absoluteString]?.wait()
                return self.sentResponses[request.url.absoluteString]
            }
            
            var isDir: ObjCBool = false
            let fileExists = FileManager.default.fileExists(atPath: self.wwwDirectory.appendingPathComponent(request.path).path, isDirectory: &isDir)
            guard fileExists else {
                return send(response: self.error404, notificationBody: "'\(request.path)' was requested but the file is not found. A 404 error will be returned. Do you want to allow or disallow access?")
            }
            
            guard isDir.boolValue else {
                if FileManager.default.fileExists(atPath: self.wwwDirectory.appendingPathComponent(request.path).path) {
                    return send(response: response(forFile: self.wwwDirectory.appendingPathComponent(request.path)), notificationBody: "'\(request.path)' file was requested and its content will be returned and parsed if needed. Do you want to allow or disallow access?")
                } else {
                    return send(response: self.error404, notificationBody: "'\(request.path)' was requested but the file is not found. A 404 error will be returned. Do you want to allow or disallow access?")
                }
            }
            
            var fileURL: URL?
            
            let indexHTML = self.wwwDirectory.appendingPathComponent(request.path).appendingPathComponent("index.html")
            let indexHTM = self.wwwDirectory.appendingPathComponent(request.path).appendingPathComponent("index.htm")
            let indexMD = self.wwwDirectory.appendingPathComponent(request.path).appendingPathComponent("index.md")
            let indexMarkdown = self.wwwDirectory.appendingPathComponent(request.path).appendingPathComponent("index.markdown")
            let readmeMD = self.wwwDirectory.appendingPathComponent(request.path).appendingPathComponent("README.md")
            let readmeMarkdown = self.wwwDirectory.appendingPathComponent(request.path).appendingPathComponent("README.markdown")
            let indexTxt = self.wwwDirectory.appendingPathComponent(request.path).appendingPathComponent("index.txt")
            let readmeTxt = self.wwwDirectory.appendingPathComponent(request.path).appendingPathComponent("README.txt")
            let index = self.wwwDirectory.appendingPathComponent(request.path).appendingPathComponent("index")
            let readme = self.wwwDirectory.appendingPathComponent(request.path).appendingPathComponent("README")
            
            if FileManager.default.fileExists(atPath: indexHTML.path) {
                fileURL = indexHTML
            } else if FileManager.default.fileExists(atPath: indexHTM.path) {
                fileURL = indexHTM
            } else if FileManager.default.fileExists(atPath: indexMD.path) {
                fileURL = indexMD
            } else if FileManager.default.fileExists(atPath: indexMarkdown.path) {
                fileURL = indexMarkdown
            } else if FileManager.default.fileExists(atPath: readmeMD.path) {
                fileURL = readmeMD
            } else if FileManager.default.fileExists(atPath: readmeMarkdown.path) {
                fileURL = readmeMarkdown
            } else if FileManager.default.fileExists(atPath: indexTxt.path) {
                fileURL = indexTxt
            } else if FileManager.default.fileExists(atPath: readmeTxt.path) {
                fileURL = readmeTxt
            } else if FileManager.default.fileExists(atPath: index.path) {
                fileURL = index
            } else if FileManager.default.fileExists(atPath: readme.path) {
                fileURL = readme
            }
            
            guard let url = fileURL else {
                return send(response: self.fileBrowser(forDirectory: request.path), notificationBody: "The web server's root was requested but no index file is found. A list of files will be returned. Do you want to allow or disallow access?")
            }
            
            return send(response: response(forFile: url), notificationBody: "The web server's root was requested and '\(url.lastPathComponent)' was found. Its content will be returned and parsed if needed. Do you want to allow or disallow access?")
        }
        webServer.delegate = self
        try? webServer.start(options: [GCDWebServerOption_AutomaticallySuspendInBackground : false, GCDWebServerOption_Port : 80, GCDWebServerOption_BonjourName : UIDevice.current.name])
    }
    
    // MARK: - Web server delegate
    
    func webServerDidCompleteBonjourRegistration(_ server: GCDWebServer) {
        serverURL = server.bonjourServerURL
    }
    
    // MARK: - Notification center delegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.alert)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let id = response.notification.request.identifier
        
        func allow() {
            if let address = requestingAddresses[id] {
                allowedAddresses.append(address)
            }
            sentResponses[id] = requestedResponses[id]
            semaphores[id]?.signal()
        }
        
        func disallow() {
            requestingAddresses[id] = nil
            sentResponses[id] = GCDWebServerDataResponse(html: DocumentViewController.htmlHead+"<h1>Access denied</h1><p>\(UIDevice.current.name) denied access to this page.</p>")
            semaphores[id]?.signal()
        }
        
        if response.actionIdentifier == "allow" {
            allow()
        } else if response.actionIdentifier == "disallow" {
            disallow()
        } else {
            let alert = UIAlertController(title: response.notification.request.content.title, message: response.notification.request.content.body, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Allow", style: .default, handler: { (_) in
                allow()
            }))
            alert.addAction(UIAlertAction(title: "Disallow", style: .cancel, handler: { (_) in
                disallow()
            }))
            UIApplication.shared.keyWindow?.topViewController?.present(alert, animated: true, completion: nil)
        }
        
        completionHandler()
    }
}
