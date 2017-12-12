import UIKit

class BookCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    var book: Book! {
        didSet {
            titleLabel.text = book.name
        }
    }
}
