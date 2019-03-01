import UIKit
import Alamofire
import SwiftyJSON
import Toast_Swift

import UIKit

class OrderServiceViewController: ViewControllerWaitingResult {
    
    @IBOutlet var tableView: OrderServiceTableView! {
        didSet {
            self.tableView.parentVC = self
        }
    }
    
    @IBOutlet var labelServicePlanSum: UILabel!
    @IBOutlet var labelLteDataSum: UILabel!
    @IBOutlet var labelDataSum: UILabel!
    @IBOutlet var tableHC: NSLayoutConstraint!
    
    var assetList: [AssetModel]!
    var trackers: [AssetModel: TrackerModel]!
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "OrderServiceViewController"
        
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
        
        loadAllDrivers()
        
        
    }
    
    func loadAllDrivers() {
        
        if assetList == nil {
            assetList = [AssetModel]()
        }
        if trackers == nil {
            trackers = [AssetModel: TrackerModel]()
        }
        
        
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
                
                
                for i in 0..<items.count {
                    self.assetList.append(AssetModel.parseJSON(items[i]))
                }
                
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
            self.trackers.removeAll()
            
            self.loadTrackersFrom(0)
            
        }
    }
    
    func loadTrackersFrom(_ assetIdOnSelectedAssetList: Int) {
        if(assetIdOnSelectedAssetList == assetList.count) {
            onTrackersAllLoaded()
            return
        }
        
        let asset = assetList[assetIdOnSelectedAssetList]
        
        let reqInfo = URLManager.trackers_id(asset.trackerId)
        
        let parameters: Parameters = [
            :
        ]
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Internet Connection Error")
            return
            // do some tasks..
        }
        
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
                
                let tracker = TrackerModel.parseJSON(json)
                self.trackers[asset] = tracker
                
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
            
            self.loadTrackersFrom(assetIdOnSelectedAssetList + 1)
            
        }
        
        
        
    }
    
    func onTrackersAllLoaded() {
        showTable()
    }
    
    func showTable() {
        var items = [OrderServiceModel]()
        
        for asset in assetList {
            if trackers[asset] == nil {
                continue
            }
            let tracker = trackers[asset]!
            
            let item = OrderServiceModel()
            
            item.name = asset.name
            item.trackerId = asset.trackerId
            
            item.servicePlanList = [ServicePlanModel]()
            item.lteDataList = [LTEDataModel]()
            
            
            var nextPeriod = Date()
            nextPeriod = nextPeriod.date(plusDay: 14)
            
            
            
            let expDate = tracker.expirationDate
            
            item.servicePlanList.append(ServicePlanModel("No Service: $0.00", 0))
            item.servicePlanList.append(ServicePlanModel("Personal Economy: $9.95", 9.95))
            item.servicePlanList.append(ServicePlanModel("Personal Premium: $12.95", 12.95))
            item.servicePlanList.append(ServicePlanModel("Business Economy: $14.95", 14.95))
            item.servicePlanList.append(ServicePlanModel("Business Premium: $17.95", 17.95))
            item.servicePlanList.append(ServicePlanModel("Personal Economy annual: $99.50", 99.5))
            item.servicePlanList.append(ServicePlanModel("Personal Premium annual: $129.50", 129.5))
            item.servicePlanList.append(ServicePlanModel("Business Economy annual: $149.50", 149.5))
            item.servicePlanList.append(ServicePlanModel("Business Premium annual: $179.50", 179.5))
            
            
            item.lteDataList.append(LTEDataModel("No Data: $0.00", 0))
            item.lteDataList.append(LTEDataModel("1G LTE Data: $12.50", 12.5))
            item.lteDataList.append(LTEDataModel("2G LTE Data: $22.00", 22))
            
            item.selectedServicePlanId = 0
            if (tracker.dataPlan != "") {
                for i in 0..<item.servicePlanList.count {
                    if tracker.dataPlan == item.servicePlanList[i].servicePlan {
                        item.selectedServicePlanId = i
                    }
                }
            }
            item.selectedLTEDataId = 0
            if (tracker.LTEData != "") {
                for i in 0..<item.lteDataList.count {
                    if tracker.LTEData == item.lteDataList[i].lteData {
                        item.selectedLTEDataId = i
                    }
                }
            }
            item.servicePlanEnabled = true
            item.lteDataEnabled = true
            item.expirationDate = (expDate ?? Date()).toString("yyyy-MM-dd")
            item.autoReview = true
            items.append(item)
        }
        
        self.tableView.setData(items)
        self.tableView.reloadData()
        self.tableHC.constant = min(self.tableView.getHeight(),self.view.bounds.height-390)
        self.updateBottomPrices()
    }
    
    
    override func setResult(_ result: Any, from id: String) {
        if(id == "OrderServiceTableViewCell-need2UpdateBottomPrices") {
            self.updateBottomPrices()
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
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Internet Connection Error")
            return
            // do some tasks..
        }
        
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
    
    func updateBottomPrices() {
        var sum1: Double! = 0
        var sum2: Double! = 0
        
        for item in self.tableView.tableData {
            sum1 = sum1 + item.servicePlanList[item.selectedServicePlanId].price
            sum2 = sum2 + item.lteDataList[item.selectedLTEDataId].price
        }
        
        labelServicePlanSum.text = sum1.priceString()
        labelLteDataSum.text = sum2.priceString()
        labelDataSum.text = (sum1 + sum2).priceString()
    }
    
    @IBAction func onProceedToCheckOut(_ sender: Any) {
        
        let checkoutVC = CheckoutViewController.getNewInstance() as! CheckoutViewController
        checkoutVC.initData.orderServiceItemList = self.tableView.tableData
        checkoutVC.initData.from = "OrderServiceViewController"
        
        //self.slideMenuController()?.changeMainViewController(checkoutVC, close: true)
        self.present(checkoutVC, animated: true, completion: nil)
    }
    
    
}
