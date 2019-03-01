import UIKit
import Alamofire
import SwiftyJSON
import Toast_Swift
import Mapbox
import MapKit

class AlarmsViewController: ViewControllerWaitingResult,UIScrollViewDelegate {
    
    @IBOutlet var assetSingleSelectTableViewHC: NSLayoutConstraint!
    @IBOutlet var reportEventView: UIStackView!
    @IBOutlet var dateSelect: UISegmentedControl!
    @IBOutlet var datePickerWrapperView: UIView!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var topView: UIView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var labelStartDate: UILabel!
    @IBOutlet var labelEndDate: UILabel!
    
    @IBOutlet var assetSingleSelectTableView: AssetSingleSelectTableView! {
        didSet {
            assetSingleSelectTableView.parentVC = self
        }
    }
    @IBOutlet var reportEventTableView: ReportEventTableView! {
        didSet {
            reportEventTableView.parentVC = self
        }
    }
    @IBAction func selectDate(_ sender: Any) {
        if(dateSelect.selectedSegmentIndex == 0) {
            datePicker.setDate(replayStartDate, animated: true)
        }
        else {
            datePicker.setDate(replayEndDate, animated: true)
        }
    }
    
    @IBAction func onPrevDay(_ sender: Any) {
        self.replayStartDate = self.replayStartDate.date(plusDay: -1)
        self.replayEndDate =  self.replayEndDate.date(plusDay: -1)
        self.labelStartDate.text = self.replayStartDate.toString("yyyy/MM/dd")
        self.labelEndDate.text = self.replayEndDate.toString("yyyy/MM/dd")
        onBtnReport(self)
    }
    @IBAction func onNextDay(_ sender: Any) {
        self.replayStartDate = self.replayStartDate.date(plusDay: 1)
        self.replayEndDate =  self.replayEndDate.date(plusDay: 1)
        self.labelStartDate.text = self.replayStartDate.toString("yyyy/MM/dd")
        self.labelEndDate.text = self.replayEndDate.toString("yyyy/MM/dd")
        onBtnReport(self)
    }
    
    var replayStartDate: Date!
    var replayEndDate: Date!
    var currentSelectingDate: Int! // 1: startDate, 2: endDate
    var assetList: [AssetModel]!
    var eventList: [ReportEventModel]!
    var assetLogList: [AssetLogModel]!
    var selectedAsset: AssetModel!
    var businessUser: Bool! = false
    var carImage: UIImage! = UIImage(named: "ic_marker_car")
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "AlarmsViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.panGestureRecognizer.delaysTouchesBegan = true
        self.scrollView.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.topView.frame.origin.y = scrollView.contentOffset.y
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadAllDrivers()
        hideDatePicker()
        
        self.replayStartDate = Date()
        self.replayEndDate = self.replayStartDate.date(plusDay: 1)
        self.labelStartDate.text = self.replayStartDate.toString("yyyy/MM/dd")
        self.labelEndDate.text = self.replayEndDate.toString("yyyy/MM/dd")
    }
    
    func hideDatePicker() {
        if datePickerWrapperView.isHidden == false {
            UIView.animate(withDuration: 0.2, animations: {
                self.datePickerWrapperView.alpha = 0
                
            }) { (value) in
                self.datePickerWrapperView.isHidden = true
            }
        }
    }
    
    func showDatePicker() {
        if self.datePickerWrapperView.isHidden {
            self.datePickerWrapperView.alpha = 0
            self.datePickerWrapperView.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                self.datePickerWrapperView.alpha = 1
            })
        }
    }
    
    func loadAllDrivers() {
        if assetList == nil {
            assetList = [AssetModel]()
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
                
                self.assetList = [AssetModel]()
                
                for i in 0..<items.count {
                    self.assetList.append(AssetModel.parseJSON(items[i]))
                }
                
                for asset in self.assetList {
                    asset.isSelected = false
                }
                
                self.assetSingleSelectTableView.setData(self.assetList)
                self.assetSingleSelectTableView.reloadData()
                self.assetSingleSelectTableViewHC.constant = self.assetSingleSelectTableView.getHeight()
                self.assetSingleSelectTableView.layer.borderColor = UIColor.gray.cgColor
                self.assetSingleSelectTableView.layer.borderWidth = 0.2
                self.assetSingleSelectTableView.layer.cornerRadius = 5.0
                self.assetSingleSelectTableView.layer.shadowColor = UIColor.black.cgColor
                self.assetSingleSelectTableView.layer.shadowOffset = CGSize(width:3.0,height:3.0)
                self.assetSingleSelectTableView.layer.shadowOpacity = 0.7
                self.assetSingleSelectTableView.layer.shadowRadius = 7.0
                self.assetSingleSelectTableView.layer.masksToBounds = false
                
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }
        
    }
    
    @IBAction func onBtnReport(_ sender: Any) {
        if selectedAsset == nil {
            self.view.makeToast("please select vehicle")
            return
        }
       // self.reportEventView.isHidden = true
        let id = selectedAsset.trackerId
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Internet Connection Error")
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.trackers_id(id)
        
        let parameters: Parameters = [
            :
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.queryString, headers: headers)
        
        request.responseString { dataResponse in
            self.hideLoader()
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            print(dataResponse)
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                let tracker = TrackerModel.parseJSON(json)
                self.loadEvents(reportId:tracker.reportingId)
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }
        self.reloadInputViews()
    }
    
    func loadEvents(reportId:String) {
        let startTime = replayStartDate.setTime()
        let endTime = replayEndDate.setTime()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-M-d HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "GMT")
        
        let startTimeString = dateFormatter.string(from: startTime) + ".000Z"
        let endTimeString = dateFormatter.string(from: endTime) + ".000Z"
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Internet Connection Error")
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.event_logs(reportId)
        
        let parameters: Parameters = [
            "startDate": startTimeString,
            "endDate": endTimeString
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.queryString, headers: headers)
        
        request.responseString { dataResponse in
            self.hideLoader()
            
            print(dataResponse)
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            //print(dataResponse)
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                
                self.eventList = [ReportEventModel]()
                
                for i in 0..<json.count {
                    self.eventList.append(ReportEventModel.parseJSON(json[i]))
                }
                
                if self.eventList.count != 0 {
                    self.reportEventTableView.setData(self.eventList)
                    self.reportEventTableView.reloadData()
                    self.reportEventView.isHidden = false
                } else {
                    self.view.makeToast("No Alarm.Change to another day.")
                }
                
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    
    
    
    
    @IBAction func onDateSelect(_ sender: Any) {
        if dateSelect.selectedSegmentIndex == 0 {
            self.replayStartDate = datePicker.date
            dateSelect.selectedSegmentIndex = 1
            datePicker.setDate(replayEndDate, animated: true)
            self.labelStartDate.text = self.replayStartDate.toString("yyyy/MM/dd")
        } else {
            self.replayEndDate = datePicker.date
            self.labelEndDate.text = self.replayEndDate.toString("yyyy/MM/dd")
            hideDatePicker()
            onBtnReport(self)
        }
    }
    
    @IBAction func onBtnStartDate(_ sender: Any) {
        datePicker.setDate(replayStartDate, animated: false)
        dateSelect.selectedSegmentIndex = 0
        showDatePicker()
        
    }
  
    
    override func setResult(_ result: Any, from id: String) {
        
        if id == "AssetSingleSelectTableViewCell-selectedItem" {
            self.selectedAsset = result as! AssetModel
            onBtnReport(self)
        }
        
    }
    
    
}
