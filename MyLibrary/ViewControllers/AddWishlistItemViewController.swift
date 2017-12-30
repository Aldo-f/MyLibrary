import UIKit
import RealmSwift
import SwiftValidators

class AddWishlistItemViewController: UITableViewController {
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var authorField: UITextField!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var isbnField: UITextField!
    @IBOutlet weak var descriptionField: UITextView!
    @IBOutlet weak var priceField: UITextField!
    @IBOutlet weak var urlField: UITextField!
    
    var item: WishlistItem?
    
    var bookTask: URLSessionTask?
    
    private func fillInTextFields() {
        if let item = item {
            authorField.text = item.book!.authors
            titleField.text = item.book!.name
            isbnField.text = item.book!.isbn
            descriptionField.text = item.book!.bookDescription
            priceField.text = "\(item.price)"
            urlField.text = item.url
            
            // enable savebutton because when you start editing a book, it has to be valid
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }
    
    override func viewDidLoad() {
        titleField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        authorField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        isbnField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        priceField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        urlField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        
        fillInTextFields()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "didAddWishlistItem"?:
            let price = Double(priceField.text!)
            item = WishlistItem(name: titleField.text!, authors: authorField.text!, isbn: isbnField.text!, price: price!, url: urlField.text!,
                                description: descriptionField.text)
        case "scanBarcode"?:
            break
        default:
            fatalError("Unknown segue")
        }
    }
    
    @IBAction func save() {
        let item = try! Realm().objects(WishlistItem.self).first{ $0.book?.isbn == isbnField.text }
        if item != nil {
            let alert = UIAlertController(title: "Boek reeds toegevoegd",
                                          message: "Dit boek zit reeds in je verlanglijstje, voeg een ander boek toe",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let book = try! Realm().objects(Book.self).first{ $0.isbn == isbnField.text }
        if book != nil {
            let alert = UIAlertController(title: "Boek reeds toegevoegd",
                                          message: "Dit boek zit reeds in je boekenkast. Ben je zeker dat je het aan je verlanglijstje wil toevoegen?",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ja", style: .default, handler: { (action) in
                self.saveConfirmed()
            }))
            alert.addAction(UIAlertAction(title: "Nee", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        saveConfirmed()
    }
    
    func saveConfirmed() {
        if let _ = item {
            // bestaand boek bewerkt
            performSegue(withIdentifier: "didEditWishlistItem", sender: self)
        } else {
            // nieuw boek
            performSegue(withIdentifier: "didAddWishlistItem", sender: self)
        }
    }
    
    @IBAction func unwindFromScanBarcode(_ segue: UIStoryboardSegue) {
        switch segue.identifier {
        case "didScanBarcode"?:
            let barcodeScannerViewController = segue.source as! BarcodeScannerViewController
            let barcode = barcodeScannerViewController.barcode!
            
            // cancel a previous task if it exists
            bookTask?.cancel()
            
            // create the new task
            bookTask = BarcodeDataService.searchAPI(isbn: barcode, completion: {
                (bookFound) in
                
                guard let bookFound = bookFound else {
                    // let the user know, we didn't find a book
                    let alert = UIAlertController(title: "Geen boek gevonden", message: "We konden geen informatie vinden over dit ISBN.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)

                    self.isbnField.text = barcode
                    return
                }
                
                self.authorField.text = bookFound.authors
                self.titleField.text = bookFound.name
                self.isbnField.text = bookFound.isbn
                
                self.fillInTextFields()
            })
            
            // start the new task
            bookTask!.resume()
        default:
            fatalError("Unknown segue")
        }
    }
    
    @objc func editingChanged(_ textField: UITextField) {
        if textField.text?.count == 1 {
            if textField.text?.first == " " {
                textField.text = ""
                return
            }
        }
        
        if let url = urlField.text {
            if Validator.regex("_^(?:(?:https?|ftp)://)(?:\\S+(?::\\S*)?@)?(?:(?!10(?:\\.\\d{1,3}){3})(?!127(?:\\.\\d{1,3}){3})(?!169\\.254(?:\\.\\d{1,3}){2})(?!192\\.168(?:\\.\\d{1,3}){2})(?!172\\.(?:1[6-9]|2\\d|3[0-1])(?:\\.\\d{1,3}){2})(?:[1-9]\\d?|1\\d\\d|2[01]\\d|22[0-3])(?:\\.(?:1?\\d{1,2}|2[0-4]\\d|25[0-5])){2}(?:\\.(?:[1-9]\\d?|1\\d\\d|2[0-4]\\d|25[0-4]))|(?:(?:[a-z\\x{00a1}-\\x{ffff}0-9]+-?)*[a-z\\x{00a1}-\\x{ffff}0-9]+)(?:\\.(?:[a-z\\x{00a1}-\\x{ffff}0-9]+-?)*[a-z\\x{00a1}-\\x{ffff}0-9]+)*(?:\\.(?:[a-z\\x{00a1}-\\x{ffff}]{2,})))(?::\\d{2,5})?(?:/[^\\s]*)?$_iuS").apply(url) {
             
                saveButton.isEnabled = false
                return
            }
        }
        
        guard
            let title = titleField.text, !title.isEmpty,
            let author = authorField.text, !author.isEmpty,
            let isbn = isbnField.text, !isbn.isEmpty,
            let price = priceField.text, !price.isEmpty,
            Validator.isFloat().apply(price),
            (Validator.isISBN(.v10).apply(isbn) || Validator.isISBN(.v13).apply(isbn))
            else {
                saveButton.isEnabled = false
                return
        }
        saveButton.isEnabled = true
    }
}
