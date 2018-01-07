import RealmSwift

class WishlistItem: Object {
    
    @objc dynamic var name = ""
    @objc dynamic var bookDescription = ""
    @objc dynamic var isbn = ""
    @objc dynamic var authors = ""
    @objc dynamic var price: Double = 0.0
    @objc dynamic var url: String = ""
    
    convenience init(name: String, authors: String, isbn: String, price: Double, url: String, description: String?) {
        self.init()
        self.name = name
        self.bookDescription = description ?? ""
        self.isbn = isbn
        self.authors = authors
        self.price = price
        self.url = url
    }
    
    var formattedPrice: String {
        get {
            return "€ \(price)"
        }
    }
}
