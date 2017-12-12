import UIKit
import RealmSwift

class WishlistViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var indexPathToEdit: IndexPath!
    
    var items: Results<WishlistItem>!
    
    override func viewDidLoad() {
        items = try! Realm().objects(WishlistItem.self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "addWishlistItem"?:
            break
        case "editWishlistItem"?:
            let destination = segue.destination as! AddWishlistItemViewController
            let wishlistItem = items[indexPathToEdit!.row]
            destination.item = wishlistItem
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
        default:
            fatalError("Unknown segue")
        }
    }
}

extension WishlistViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let editAction = UIContextualAction(style: .normal, title: "Bewerk") {
            (action, view, completionHandler) in
            self.indexPathToEdit = indexPath
            self.performSegue(withIdentifier: "editWishlistItem", sender: self)
            completionHandler(true)
        }
        editAction.backgroundColor = UIColor.orange
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Verwijder") {
            (action, view, completionHandler) in

            let wishlistItem = self.items[indexPath.row]
            
            let realm = try! Realm()
            try! realm.write {
                realm.delete(wishlistItem)
            }
            
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            
            completionHandler(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
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
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "wishlistItemCell", for: indexPath) as! WishlistItemCell
        cell.wishlistItem = items[indexPath.row]
        return cell
    }
}
