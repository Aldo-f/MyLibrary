import UIKit
import RealmSwift
import SwiftValidators

class AddBookViewController: UITableViewController {
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var authorField: UITextField!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var isbnField: UITextField!
    @IBOutlet weak var descriptionField: UITextView!
    @IBOutlet weak var isbnButton: UIButton!
    
    var bookEdited = false
    var book: Book?
    
    private func fillInTextFields() {
        if let book = book {
            authorField.text = book.authors
            titleField.text = book.name
            isbnField.text = book.isbn
            descriptionField.text = book.bookDescription;
            
            // enable savebutton because when you start editing a book, it has to be valid
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }
    
    private var bookTask: URLSessionTask?
    
    override func viewDidLoad() {
        titleField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        authorField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        isbnField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        
        fillInTextFields()
    }
    
    // Uses UIView as parameter because there is a UITextView also
    @IBAction func hideKeyboard(_ sender: UIView) {
        sender.resignFirstResponder()
    }
    
    @IBAction func save() {
        if bookEdited {
            // bestaand boek bewerkt
            performSegue(withIdentifier: "didEditBook", sender: self)
        } else {
            // nieuw boek
            performSegue(withIdentifier: "didAddBook", sender: self)
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
                    let alert = UIAlertController(title: "Geen boek gevonden", message: "We konden geen informatie vinden over dit ISBN. Gelieve de gegevens zelf in te vullen", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                    if let book = self.book {
                        book.isbn = barcode
                    } else {
                        self.book = Book()
                        self.book!.isbn = barcode
                    }
                    
                    self.isbnField.text = barcode
                    return
                }
                
                if let book = self.book {
                    book.name = bookFound.name
                    book.authors = bookFound.authors
                    book.isbn = bookFound.isbn
                } else {
                    self.book = bookFound
                }

                self.fillInTextFields()
            })
            
            // start the new task
            bookTask!.resume()
        default:
            fatalError("Unknown segue")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "didAddBook"?:
            book = Book(name: titleField.text!, authors: authorField.text!, isbn: isbnField.text!, description: descriptionField.text)
        case "didEditBook"?:
            let realm = try! Realm()
            try! realm.write{
                book!.name = titleField.text!
                book!.authors = authorField.text!
                book!.isbn = isbnField.text!
                book!.bookDescription = descriptionField.text
            }
        case "scanBarcode"?:
            break
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
        guard
            let title = titleField.text, !title.isEmpty,
            let author = authorField.text, !author.isEmpty,
            let isbn = isbnField.text, !isbn.isEmpty,
            (Validator.isISBN(.v10).apply(isbn) || Validator.isISBN(.v13).apply(isbn))
            else {
                saveButton.isEnabled = false
                return
        }
        saveButton.isEnabled = true
    }
}
