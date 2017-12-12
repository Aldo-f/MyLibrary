import RealmSwift

class WishlistItem: Object {
    
    @objc dynamic var book: Book? = nil
    @objc dynamic var price: Double = 0.0
    @objc dynamic var url: String = ""
    
    convenience init(name: String, authors: String, isbn: String, price: Double, url: String, description: String?) {
        self.init()
        self.book = Book(name: name, authors: authors, isbn: isbn, description: description ?? "")
        self.price = price
        self.url = url
    }
    
    var formattedPrice: String {
        get {
            return "€ \(price)"
        }
    }
}
