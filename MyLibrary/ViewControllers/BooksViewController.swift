import UIKit
import RealmSwift

/**
 Deze code is grotendeels gekopieerd van de oefening Tasks
 */
class BooksViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var indexPathToEdit: IndexPath!
    
    // dit geeft aan of er gezocht werd
    // zo ja, dan wordt het aantal van de gefilterde lijst teruggeven aan de UITableView
    var searchActive: Bool = false
    
    private var scopeButtons: [String] = ["Auteur", "Titel"]
    
    var books: Results<Book>!
    {
        didSet{
            booksPerAuthor = books.grouped{ $0.authors }
        }
    }
    
    var filteredBooks: [Book]! {
        didSet {
            booksPerAuthor = filteredBooks.grouped{ $0.authors }
        }
    }
    
    /*
     Omdat dit vaak herberekend moet worden in de extension, houden we dit bij.
     Als books wijzigt, wordt dit automatisch ook gewijzigd.
     */
    var booksPerAuthor: [String: [Book]] = [:]
    
    override func viewDidLoad() {
        books = try! Realm().objects(Book.self)
        
        // Dit zorgt ervoor dat het keyboard verdwijnt wanneer ernaast geklikt wordt tijdens het zoeken
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        // anders werkt de didSelectRowAt van de tableview niet meer omdat de TapGestureRecognizer steeds de touch opvangt
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        searchBar.scopeButtonTitles = scopeButtons
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

extension BooksViewController: UISearchBarDelegate {

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsScopeBar = false
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsScopeBar = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        booksPerAuthor = books.grouped { $0.authors }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyboard()
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        if searchBar.text != nil {
            filterBooks(by: searchBar.text!)
            self.tableView.reloadData()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            booksPerAuthor = books.grouped{ $0.authors }
        } else {
            filterBooks(by: searchText)
        }

        self.tableView.reloadData()
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        searchBar.endEditing(true)
    }
    
    func filterBooks(by searchText: String) {
        filteredBooks = books.filter({ (book) -> Bool in
            var tmp: NSString = ""
            if searchBar.selectedScopeButtonIndex == 0 {
                // Auteurs
                tmp = book.authors as NSString
            }
            if searchBar.selectedScopeButtonIndex == 1 {
                // Titel
                tmp = book.name as NSString
            }
            
            let range = tmp.range(of: searchText, options: NSString.CompareOptions.caseInsensitive)
            return range.location != NSNotFound
        })
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

extension Array {
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

