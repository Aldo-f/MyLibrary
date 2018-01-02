import UIKit

class HomeViewController: UIViewController {
    
    private let LIBRARY = 1
    private let WISHLIST = 2
    
    @IBAction func showLibrary() {
        self.tabBarController?.selectedIndex = LIBRARY
    }
    
    @IBAction func showWishlist() {
        self.tabBarController?.selectedIndex = WISHLIST
    }
}
