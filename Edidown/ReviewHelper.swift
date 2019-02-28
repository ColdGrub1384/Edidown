import Foundation
import StoreKit

/// Helper used to request app review based on app launches.
class ReviewHelper {
    
    /// Request review and reset points.
    func requestReview() {
        
        if minSaves == -1 {
            return
        }
        
        if saves >= minSaves {
            saves = 0
            if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(1 * Double(NSEC_PER_SEC)) / Double(NSEC_PER_SEC), execute: {
                    print(UIApplication.shared.windows.count)
                    if UIApplication.shared.windows.count > 2 {
                        _ = DocumentViewController.shared?.textView.resignFirstResponder()
                    }
                })
            }
            
            if minSaves == 1 {
                minSaves = 3
            } else if minSaves == 3 {
                minSaves = 6
            } else {
                minSaves = -1
            }
        }
    }
    
    // MARK: - Singleton
    
    /// Shared and unique instance.
    static let shared = ReviewHelper()
    private init() {}
    
    // MARK: - Launches tracking
    
    /// Times the user saved a file.
    var saves: Int {
        
        get {
            return UserDefaults.standard.integer(forKey: "launches")
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "launches")
        }
    }
    
    private var minSaves: Int {
        get {
            return UserDefaults.standard.value(forKey: "minSaves") as? Int ?? 1
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "minSaves")
            UserDefaults.standard.synchronize()
        }
    }
}
