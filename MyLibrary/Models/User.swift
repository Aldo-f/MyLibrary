import RealmSwift

public class User: Object {
    
    @objc dynamic var name = ""
    var library = List<Book>()
    var wishlist = List<Book>()
    
    convenience init(name: String) {
        self.init()
        self.name = name
    }
}
