import UIKit
import Alamofire
import SwiftyJSON
import Toast_Swift

import UIKit

class UpdateDriverInfoViewController: ViewControllerWaitingResult {

    @IBOutlet var tableView: UpdateDriverInfoTableView! {
        didSet {
            self.tableView.parentVC = self
        }
    }
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "UpdateDriverInfoViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        loadTable()
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func loadTable() {
        
        
        self.view.endEditing(true)
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Internet Connection Error")
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.assets()
        
        let parameters: Parameters = [
            :
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            self.hideLoader()
            
            print(dataResponse)
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                
                let items = json["items"]
                
                var tableData = [AssetModel]()
                
                for i in 0..<items.count {
                    tableData.append(AssetModel.parseJSON(items[i]))
                }
                self.tableView.setData(tableData)
                self.tableView.reloadData()
                
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }
        
    }
    
    override func setResult(_ result: Any, from id: String) {
        if(id == "UpdateDriverInfoTableView-updateDriverItem") {
            let item = result as! (String, String, String, String)
            self.updateDriver(item.0, item.1, item.2, item.3)
        }
    }
    
    func updateDriver(_ driverName: String, _ driverPhone: String, _ vehicleName: String, _ assetId: String) {
        if(driverName == "") {
            self.view.makeToast("please enter driver name")
            return
        }
        if(driverPhone == "") {
            self.view.makeToast("please enter driver phone")
            return
        }
        if(vehicleName == "") {
            self.view.makeToast("please enter vehicle name")
            return
        }
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Internet Connection Error")
            return
            // do some tasks..
        }
        
        self.view.endEditing(true)
        
        let reqInfo = URLManager.updateAsset(assetId)
        
        let parameters: Parameters = [
            "name": vehicleName,
            "driverName": driverName,
            "driverPhoneNumber": driverPhone
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            self.hideLoader()
            
            print(dataResponse)
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                
                self.view.makeToast("update success")
                
                self.loadTable()
                
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }
        
    }
    

}
