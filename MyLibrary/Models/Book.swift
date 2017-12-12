import RealmSwift

public class Book: Object {

    @objc dynamic var name = ""
    @objc dynamic var bookDescription = ""
    @objc dynamic var isbn = ""
    @objc dynamic var authors = ""

    convenience init(name: String, authors: String, isbn: String, description: String?) {
        self.init()
        self.name = name
        self.bookDescription = description ?? ""
        self.isbn = isbn
        self.authors = authors
    }
}
