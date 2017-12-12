import Foundation
import SwiftyJSON

class BarcodeDataService {
    
    private static let session = URLSession(configuration: .ephemeral)
    private static let GOOGLE_BOOKS_URL = "https://www.googleapis.com/books/v1/volumes?q=+isbn:"
    private static let API_KEY = "AIzaSyBnPnc-zColLnfzhrYNalWLTH-EiN-faH4"
    
    // example url: https://www.googleapis.com/books/v1/volumes?q=+isbn:9789461316059&key=AIzaSyBnPnc-zColLnfzhrYNalWLTH-EiN-faH4
    static func searchAPI(isbn: String, completion: @escaping (Book?) -> Void) -> URLSessionTask {
        
        // The URL we will use to get the data of the book with the given isbn
        let url = URL(string: "\(GOOGLE_BOOKS_URL)\(isbn)&key=\(API_KEY)")!
        
        return session.dataTask(with: url){ (data, response, error) in
            // wrap the completion handler to start it on the main thread
            let completion: (Book?) -> Void = {
                book in
                
                DispatchQueue.main.async {
                    // execute this when you have the time
                    completion(book)
                }
            }
            
            // check the status of the response
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                let data = data else {
                    
                    completion(nil)
                    return
            }
            
            // check if there is a result
            guard let result = try? JSONSerialization.jsonObject(with: data),
                    let json = result as? [String: Any] else {

                completion(nil)
                return
            }
            
            // check if the items are present
            guard let items = json["items"] as? [[String: Any]],
                    !items.isEmpty else {

                completion(nil)
                return
            }
            
            let item = items[0]

            guard let volumeInfo = item["volumeInfo"]  as? [String: Any],
                    !volumeInfo.isEmpty,
                    let title = volumeInfo["title"] as? String,
                    let authors = volumeInfo["authors"] as? [String]
            else {
                completion(nil)
                return
            }
            
            let authorsString = authors.joined(separator: ", ")
            completion(Book(name: title, authors: authorsString, isbn: isbn, description: ""))
        }
    }
}
