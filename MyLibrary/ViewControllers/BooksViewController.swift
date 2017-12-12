import UIKit
import RealmSwift

/**
 Deze code is grotendeels gekopieerd van de oefening Tasks
 */
class BooksViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var indexPathToEdit: IndexPath!
    
    var books: Results<Book>!
    {
        didSet{
            booksPerAuthor = books.grouped{ $0.authors }
        }
    }
    
    /*
     Omdat dit vaak herberekend moet worden in de extension, houden we dit bij.
     Als books wijzigt, wordt dit automatisch ook gewijzigd.
     */
    var booksPerAuthor: [String: [Book]] = [:]
    
    override func viewDidLoad() {
        books = try! Realm().objects(Book.self)
    }
    
    @IBAction func unwindFromAddBook(_ segue: UIStoryboardSegue) {
        switch segue.identifier {
        case "didAddBook"?:
            let source = segue.source as! AddBookViewController
            if let _ = booksPerAuthor.index(forKey: source.book!.authors) {
                // de auteur bestaat reeds
                addNew(book: source.book!)
                
                let authorIndex = Array(booksPerAuthor.keys).index(of: source.book!.authors)!
                let row = booksPerAuthor[source.book!.authors]!.count - 1
                tableView.insertRows(at: [IndexPath(row: row, section: authorIndex)], with: .automatic)
            } else {
                addNew(book: source.book!)
                
                // dit moeten we met beginUpdates en endUpdates doen aangezien we de hele
                // structuur van de tableview gaan wijzigen en niet één enkele section
                // we doen m.a.w. verschillende dingen tegelijk
                tableView.beginUpdates()
                // eerste een nieuwe sectie toevoegen
                let authorIndex = Array(booksPerAuthor.keys).index(of: source.book!.authors)!
                tableView.insertSections([authorIndex], with: .automatic)
                
                // dan pas een rij aan diezelfde sectie
                let row = booksPerAuthor[source.book!.authors]!.count - 1
                tableView.insertRows(at: [IndexPath(row: row, section: authorIndex)], with: .automatic)
                tableView.endUpdates()
            }
        case "didEditBook"?:
            // herlaad de rij waar de gebruiker daarnet op edit geklikt heeft
            tableView.reloadRows(at: [indexPathToEdit], with: .automatic)
        default:
            fatalError("Unknown segue")
        }
        
        //let source = segue.source as! AddBookViewController
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "addBook"?:
            break
        case "editBook"?:
            if let indexPathToEdit = indexPathToEdit {
                let author = getAuthorAt(index: indexPathToEdit.section)
                let booksOfAuthor = booksPerAuthor[author]!
                let book = booksOfAuthor[indexPathToEdit.row]
                let destination = segue.destination as! AddBookViewController
                destination.book = book
                destination.bookEdited = true
            }
        default:
            fatalError("Unknown segue")
        }
    }
    
    func addNew(book b: Book) {
        let realm = try! Realm()
        try! realm.write {
            realm.add(b)
        }
        doGroupBy()
    }
    
    func remove(book b: Book) {
        let realm = try! Realm()
        try! realm.write {
            realm.delete(b)
        }
        doGroupBy()
    }
    
    func doGroupBy() {
        booksPerAuthor = books.grouped{ $0.authors }
    }
}

extension BooksViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let editAction = UIContextualAction(style: .normal, title: "Bewerk") {
            (action, view, completionHandler) in
            self.indexPathToEdit = indexPath
            self.performSegue(withIdentifier: "editBook", sender: self)
            completionHandler(true)
        }
        editAction.backgroundColor = UIColor.orange
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Verwijder") {
            (action, view, completionHandler) in
            // we moeten het boek zelf zoeken omdat we met sections
            // de indexen door elkaar halen
            let author = self.getAuthorAt(index: indexPath.section)
            let bookToDelete = self.booksPerAuthor[author]![indexPath.row]
            self.remove(book: bookToDelete)
            
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            // als het het laatste boek van auteur was, sectie ook weg
            if self.booksPerAuthor[author] == nil {
                tableView.deleteSections([indexPath.section], with: .automatic)
            }

            tableView.endUpdates()
            
            completionHandler(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.indexPathToEdit = indexPath
        self.performSegue(withIdentifier: "editBook", sender: self)
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

extension BooksViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return booksPerAuthor.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let author = getAuthorAt(index: section)
        return booksPerAuthor[author]!.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return getAuthorAt(index: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let author = getAuthorAt(index: indexPath.section)
        let cell = tableView.dequeueReusableCell(withIdentifier: "bookCell", for: indexPath) as! BookCell
        let index = getIndexFor(row: indexPath.row)
        cell.book = booksPerAuthor[author]![index]
        return cell
    }
    
    func getAuthorAt(index i: Int) -> String {
        let author = Array(booksPerAuthor.keys)[i]
        return author
    }
    
    /*
     Om de index van een bepaald boek van een auteur te weten, deel je de huidige rij
     door het aantal auteurs (sections) en rond je steeds naar boven af.
    */
    func getIndexFor(row i: Int) -> Int {
        let sectionsCount = numberOfSections(in: tableView);
        var quotient: Double = Double(i) / Double(sectionsCount);
        quotient.round(.up)
        return Int(quotient)
    }
}

/**
 Gekopieerd van https://medium.com/ios-os-x-development/little-snippet-group-by-in-swift-3-5be0a06307db
 */
extension Results {
    func grouped<T>(by criteria: (Element) -> T) -> [T: [Element]] {
        var groups = [T: [Element]]()
        for element in self {
            let key = criteria(element)
            if groups.keys.contains(key) == false {
                groups[key] = [Element]()
            }
            groups[key]?.append(element)
        }
        return groups
    }
}

