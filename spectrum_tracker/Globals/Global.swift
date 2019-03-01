import Foundation
import UIKit
import Alamofire

class Global {
    static var shared: Global! = Global()
    
    init() {
        self.csrfToken = ""
        self.username = "---"
        self.alertArray = [String:String]()
    }
    
    var csrfToken: String!
    var alertArray: [String:String]!
    var username: String!
    
    static var AFManager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10 // seconds
        configuration.timeoutIntervalForResource = 10 //seconds
        return Alamofire.SessionManager(configuration: configuration)
    }()
    
}


struct Regex_strings {
    static let mobile = "^[0-9]{11}$"
    static let password = "^.{8,18}$"
    static let age = "^(0?[1-9]|[1-9][0-9])$"
    static let specialChars = "[$&+,:;=\\?@#|/'<>.^*()%!-]"
    static let email = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
}
