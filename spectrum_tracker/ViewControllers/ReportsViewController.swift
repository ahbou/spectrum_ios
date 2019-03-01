import UIKit
import Alamofire
import SwiftyJSON
import Toast_Swift
import Mapbox
import MapKit

class ReportsViewController: ViewControllerWaitingResult,UIScrollViewDelegate {
    
    @IBOutlet var assetSingleSelectTableViewHC: NSLayoutConstraint!
    @IBOutlet var dateSelect: UISegmentedControl!
    @IBOutlet var datePickerWrapperView: UIView!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var topView: UIView!
    @IBOutlet var labelWorkMileage: UILabel!
    @IBOutlet var txtMaxSpeed: UILabel!
    @IBOutlet var txtTotalStops: UILabel!
    @IBOutlet var txtWorkMileage: UILabel!
    @IBOutlet var txtMileageMile: UILabel!
    @IBOutlet var txtTotalFuel: UILabel!
    @IBOutlet var txtWorkFuel: UILabel!
    @IBOutlet var txtTimeTotal: UILabel!
    @IBOutlet var txtWorkTime: UILabel!
    @IBOutlet weak var txtSpeeding: UILabel!
    @IBOutlet weak var txtIdling: UILabel!
    @IBOutlet weak var txtHarshAcce: UILabel!
    @IBOutlet weak var txtHarshDece: UILabel!
    @IBOutlet weak var txtFatigure: UILabel!
    @IBOutlet weak var txtHighRPM: UILabel!
    @IBOutlet weak var txtLowBattery: UILabel!
    @IBOutlet weak var txtTemp: UILabel!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var labelStartDate: UILabel!
    @IBOutlet var labelEndDate: UILabel!
    
    @IBOutlet var assetSingleSelectTableView: AssetSingleSelectTableView! {
        didSet {
            assetSingleSelectTableView.parentVC = self
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
    var tripLogList: [TripLogModel]!
    var assetLogList: [AssetLogModel]!
    var selectedAsset: AssetModel!
    var businessUser: Bool! = false
    var carImage: UIImage! = UIImage(named: "ic_marker_car")
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "ReportsViewController"
        
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
            
            //print(dataResponse)
            
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
        let id = selectedAsset._id
        
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
        
        let reqInfo = URLManager.assets_logs(id)
        
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
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            print(dataResponse)
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                
                self.businessUser = json["business"].boolValue
                
                let items = json["items"]
                
                self.assetLogList = [AssetLogModel]()
                
                for i in 0..<items.count {
                    self.assetLogList.append(AssetLogModel.parseJSON(items[i]))
                }
                
                if self.assetLogList.count != 0 {
                    self.loadTripLogs(reportId:self.assetLogList[0].reportingId)
                } else {
                    self.view.makeToast("no log found")
                }
                
                
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }
        self.reloadInputViews()
    }
    
    
    
    func loadTripLogs(reportId:String) {
        
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
        
        let reqInfo = URLManager.trip_logs(reportId)
        
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
                
                self.tripLogList = [TripLogModel]()

                for i in 0..<json.count {
                    self.tripLogList.append(TripLogModel.parseJSON(json[i]))
                }

                if self.tripLogList.count != 0 {
                    self.showReportTrip()
                } else {
                    self.view.makeToast("no log found")
                }
                
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    
    func showReportTrip() {
        var maxSpeed:Double! = 0
        var harshDeceNum:Int! = 0
        var harshAcceNum:Int! = 0
        var speedingNum:Int! = 0
        var totalTrips:Int! = 0
        var idleNum:Int! = 0
        var totalFuel:Double! = 0
        var totalMileages:Double! = 0
        
        for i in 0..<tripLogList.count {
            let device = tripLogList[i]
            maxSpeed = max(maxSpeed,device.maxSpeed)
            harshDeceNum = harshDeceNum + device.harshDece
            harshAcceNum = harshAcceNum + device.harshAcce
            speedingNum = speedingNum + device.speeding
            totalTrips = totalTrips + device.stops
            idleNum = idleNum + device.idle
            totalFuel = totalFuel + device.fuel
            totalMileages = totalMileages + device.mileage
        }
        txtMaxSpeed.text = String(format: "%.2f",maxSpeed)
        txtHarshDece.text = String(harshDeceNum)
        txtHarshAcce.text = String(harshAcceNum)
        txtSpeeding.text = String(speedingNum)
        txtTotalStops.text = String(totalTrips)
        txtIdling.text = String(idleNum)
        txtTotalFuel.text = String(format: "%.2f",totalFuel)
        txtMileageMile.text = String(format: "%.2f",totalMileages)
        labelWorkMileage.text = "Average trip distance"
        if totalMileages == 0 || totalTrips == 0 {
            txtWorkMileage.text = "0"
        }
        else {
            txtWorkMileage.text = String(Int(ceil(totalMileages/Double(totalTrips))))
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
    @IBAction func onBtnEndDate(_ sender: Any) {
        datePicker.setDate(replayEndDate, animated: false)
        dateSelect.selectedSegmentIndex = 1
        showDatePicker()
    }
    
    override func setResult(_ result: Any, from id: String) {
        
        if id == "AssetSingleSelectTableViewCell-selectedItem" {
            self.selectedAsset = result as! AssetModel
            //print("id")
            onBtnReport(self)
        }
        
    }
    
    
}
