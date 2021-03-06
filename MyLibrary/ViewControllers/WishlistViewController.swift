import UIKit
import RealmSwift

class WishlistViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var indexPathToEdit: IndexPath!
    var searchActive: Bool = false
    
    private var scopeButtons: [String] = ["Auteur", "Titel"]
    
    var items: Results<WishlistItem>!
    var filteredItems: [WishlistItem]!
    
    override func viewDidLoad() {
        items = try! Realm().objects(WishlistItem.self)
        
        // Dit zorgt ervoor dat het keyboard verdwijnt wanneer ernaast geklikt wordt tijdens het zoeken
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        // anders werkt de didSelectRowAt van de tableview niet meer omdat de TapGestureRecognizer steeds de touch opvangt
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        searchBar.scopeButtonTitles = scopeButtons
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "addWishlistItem"?:
            break
        case "editWishlistItem"?:
            let destination = segue.destination as! AddWishlistItemViewController
            let wishlistItem = items[indexPathToEdit!.row]
            destination.item = wishlistItem
            destination.itemEdited = true
        default:
            fatalError("Unkown segue")
        }
    }
    
    @IBAction func unwindFromAddWishlist(_ segue: UIStoryboardSegue) {
        switch segue.identifier {
        case "didAddWishlistItem"?:
            let source = segue.source as! AddWishlistItemViewController
            let wishlistItem = source.item!
            
            let realm = try! Realm()
            try! realm.write {
                realm.add(wishlistItem)
            }

            tableView.beginUpdates()
            tableView.insertRows(at: [IndexPath(row: items.count - 1, section: 0)], with: .automatic)
            tableView.endUpdates()
        case "didEditWishlistItem"?:
            // herlaad de rij waar de gebruiker daarnet op edit geklikt heeft
            tableView.reloadRows(at: [indexPathToEdit], with: .automatic)
        default:
            fatalError("Unknown segue")
        }
    }
}

extension WishlistViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let itemBoughtAction = UIContextualAction(style: .normal, title: "Gekocht") {
            (action, view, completionHandler) in
            let alert = UIAlertController(title: "Boek kopen", message: "Ben je zeker dat je niet boek als gekocht wil aanduiden?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ja", style: .destructive, handler: { (action) in
                let item = self.items[indexPath.row]
                let book = Book(name: item.name, authors: item.authors, isbn: item.isbn, description: item.bookDescription)
                
                // we voegen nu het boek toe en verwijderen het wishlistitem
                let realm = try! Realm()
                try! realm.write {
                    realm.add(book)
                    realm.delete(item)
                    
                    // verwijder dan de rij uit de TableView
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            }))

            alert.addAction(UIAlertAction(title: "Nee", style: .default, handler: nil))

            self.present(alert, animated: true, completion: nil)
            completionHandler(true)
        }
        itemBoughtAction.backgroundColor = UIColor.green
        
        let editAction = UIContextualAction(style: .normal, title: "Bewerk") {
            (action, view, completionHandler) in
            self.indexPathToEdit = indexPath
            self.performSegue(withIdentifier: "editWishlistItem", sender: self)
            completionHandler(true)
        }
        editAction.backgroundColor = UIColor.orange
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Verwijder") {
            (action, view, completionHandler) in

            let alert = UIAlertController(title: "Boek verwijderen", message: "Ben je zeker dat je dit boek wil verwijderen?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ja", style: .destructive, handler: { (action) in
                let wishlistItem = self.items[indexPath.row]
                
                let realm = try! Realm()
                try! realm.write {
                    realm.delete(wishlistItem)
                }
                
                tableView.beginUpdates()
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.endUpdates()

                completionHandler(true)
            }))
            
            alert.addAction(UIAlertAction(title: "Nee", style: .default, handler: { (action) in
                completionHandler(false)
            }))
        
            self.present(alert, animated: true, completion: nil)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction, itemBoughtAction])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.indexPathToEdit = indexPath
        self.performSegue(withIdentifier: "editWishlistItem", sender: self)
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

extension WishlistViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchActive {
            return filteredItems.count
        }

        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "wishlistItemCell", for: indexPath) as! WishlistItemCell
        
        if searchActive {
            cell.wishlistItem = filteredItems[indexPath.row]
        } else {
            cell.wishlistItem = items[indexPath.row]
        }

        return cell
    }
}

extension WishlistViewController: UISearchBarDelegate {
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsScopeBar = false
        searchActive = false
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsScopeBar = true
        searchActive = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        dismissKeyboard()
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        if searchBar.text != nil {
            filterItems(by: searchBar.text!)
            searchActive = true
            self.tableView.reloadData()
        } else {
            searchActive = false
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            filterItems(by: searchText)
            searchActive = true
        } else {
            searchActive = false
        }

        self.tableView.reloadData()
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        searchBar.endEditing(true)
    }
    
    func filterItems(by searchText: String) {
        filteredItems = items.filter({ (item) -> Bool in
            var tmp: NSString = ""
            if searchBar.selectedScopeButtonIndex == 0 {
                // Auteurs
                tmp = (item.authors) as NSString
            }
            if searchBar.selectedScopeButtonIndex == 1 {
                // Titel
                tmp = (item.name) as NSString
            }
            
            let range = tmp.range(of: searchText, options: NSString.CompareOptions.caseInsensitive)
            return range.location != NSNotFound
        })
    }
}
