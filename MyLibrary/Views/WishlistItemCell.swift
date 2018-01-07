import UIKit

class WishlistItemCell: UITableViewCell {
    
    @IBOutlet weak var authorsField: UILabel!
    @IBOutlet weak var titleField: UILabel!
    @IBOutlet weak var priceField: UILabel!
    
    var wishlistItem: WishlistItem! {
        didSet {
            self.authorsField.text = wishlistItem.authors
            self.titleField.text = wishlistItem.name
            self.priceField.text = wishlistItem.formattedPrice
        }
    }
}
