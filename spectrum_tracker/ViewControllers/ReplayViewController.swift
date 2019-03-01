import UIKit
import Alamofire
import SwiftyJSON
import Toast_Swift
import Mapbox
import MapKit
import MapboxGeocoder
import Charts
import VerticalSteppedSlider

class CustomAnnotation: MGLPointAnnotation {
    var heading: CGFloat! = 0
}


class ReplayViewController: ViewControllerWaitingResult , UIScrollViewDelegate{
   
    @IBOutlet var info_table: UIStackView!
    @IBOutlet var label_topSpeed: UILabel!
    @IBOutlet var label_totalSpeeding: UILabel!
    @IBOutlet var routeControlView: UIView!
    @IBOutlet var btn_prevDay: UIButton!
    @IBOutlet var label_harshAcce: UILabel!
    @IBOutlet var btn_backwardR: UIButton!
    @IBOutlet var label_harshDece: UILabel!
    @IBOutlet var btn_playR: UIButton!
    @IBOutlet var label_totalStops: UILabel!
    @IBOutlet var btn_forwardR: UIButton!
    @IBOutlet var partRoute_header: UIStackView!
    @IBOutlet var topStackView: UIStackView!
    @IBOutlet var label_partRouteHeader: UILabel!
    @IBOutlet var btn_nextDay: UIButton!
    @IBOutlet var label_dateFromTO: UILabel!
    @IBOutlet var allRoute_header: UIStackView!
    @IBOutlet var zoom_Slider: VSSlider!
    @IBOutlet var reportLabel: UILabel!
    @IBOutlet var mapViewWrapper: UIView!
    @IBOutlet var slider: UISlider!
    @IBOutlet var labelSpeed: UILabel!
    @IBOutlet var btn_style: UIButton!
    @IBOutlet var allScrollView: UIScrollView!
    @IBOutlet var labelGageDate: UILabel!
    @IBOutlet var speedIndicator: UIImageView!
    @IBOutlet var topViewHC: NSLayoutConstraint!
    @IBOutlet var topView: UIView!
    @IBOutlet var bottomView: UIStackView!
    @IBOutlet var reportLabelView: UIScrollView!
    @IBOutlet var bottomTableHC: NSLayoutConstraint!
    @IBOutlet var datePickerWrapperView: UIView!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var bottomHC: NSLayoutConstraint!
    @IBOutlet var dateSelect: UISegmentedControl!
    @IBOutlet var btnStartDate: UIButton!
    @IBOutlet var btnEndDate: UIButton!
    @IBOutlet var btn_menu: UIButton!
    @IBOutlet var assetSingleSelectTableView: AssetSingleSelectTableView! {
        didSet {
            assetSingleSelectTableView.parentVC = self
        }
    }
    
    @IBAction func changeMapStyle(_ sender: Any) {
        if(mapStyle)
        {
            mapView.styleURL = URL(string: "https://osm.spectrumtracking.com/styles/ciw6czz2n00242kmg6hw20box/style.json")
        }
        else
        {
            mapView.styleURL = MGLStyle.satelliteStyleURL()
        }
        mapStyle = !mapStyle
    }
    
    @IBAction func actionPrevDay(_ sender: Any) {
        self.replayStartDate = self.replayStartDate.date(plusDay: -1)
        self.replayEndDate =  self.replayEndDate.date(plusDay: -1)
        self.btnStartDate.setTitle(replayStartDate.toString("MM/dd/yyyy"), for: .normal)
        self.btnEndDate.setTitle(replayEndDate.toString("MM/dd/yyyy"), for: .normal)
        self.allRoute_header.isHidden = false
        self.partRoute_header.isHidden = true
        self.label_dateFromTO.text = self.replayStartDate.toString("MM.dd") + " to " + self.replayEndDate.toString("MM.dd")
        self.btn_nextDay.isEnabled = true
        self.onBtnReport(self)
    }
    
    @IBAction func actionNextDay(_ sender: Any) {
        self.replayStartDate = self.replayStartDate.date(plusDay: 1)
        self.replayEndDate =  self.replayEndDate.date(plusDay: 1)
        self.btnStartDate.setTitle(replayStartDate.toString("MM/dd/yyyy"), for: .normal)
        self.btnEndDate.setTitle(replayEndDate.toString("MM/dd/yyyy"), for: .normal)
        self.allRoute_header.isHidden = false
        self.partRoute_header.isHidden = true
        self.label_dateFromTO.text = self.replayStartDate.toString("MM.dd") + " to " + self.replayEndDate.toString("MM.dd")
        print(replayEndDate.toString("MM.dd"))
        print("today:\(Date().toString("MM.dd"))")
        if replayStartDate.toString("MM.dd") == Date().toString("MM.dd") {
            self.btn_nextDay.isEnabled = false
        }
        self.onBtnReport(self)
    }
    
    @IBAction func showReports(_ sender: Any) {
        reportLabelView.isHidden = !reportLabelView.isHidden
//        if !reportLabel.isHidden {
//            topViewHC.constant = 0 - self.scrollChildView.frame.size.height * 0.4
//        }
//        else {
//            topViewHC.constant = 0
//            self.scrollChildView.contentOffset.y = 0
//        }
    }
    
    @IBAction func onShowMenu(_ sender: Any) {
        if display_mode == "multiVelocity" {
            self.slideMenuController()?.openLeft()
        }
        else {
            
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func zoom_Change(_ sender: Any) {
        mapView.zoomLevel = Double(zoom_Slider.value);
    }
    
    @IBAction func selectDate(_ sender: Any) {
        if(dateSelect.selectedSegmentIndex == 0) {
            datePicker.setDate(replayStartDate, animated: true)
        }
        else {
            datePicker.setDate(replayEndDate, animated: true)
        }
    }
    
    @IBAction func onBackwardAction(_ sender: Any) {
        selectRouteIndex = selectRouteIndex - 1
        if selectRouteIndex < 0 {
            return
        }
        if selectRouteIndex < pointIndex_Array.count - 2 {
            self.btn_forwardR.isEnabled = true
        }
        if selectRouteIndex == 0 {
            self.btn_backwardR.isEnabled = false
        }
        self.allRoute_header.isHidden = true
        self.partRoute_header.isHidden = false
        self.label_partRouteHeader.text = self.partHeader_Array[selectRouteIndex]
        drawRoute()
    }
    
    @IBAction func onForwardAction(_ sender: Any) {
        selectRouteIndex = selectRouteIndex + 1
        if selectRouteIndex == pointIndex_Array.count - 2 {
            self.btn_forwardR.isEnabled = false
        }
        if selectRouteIndex > 0 {
            self.btn_backwardR.isEnabled = true
        }
        self.allRoute_header.isHidden = true
        self.partRoute_header.isHidden = false
        self.label_partRouteHeader.text = self.partHeader_Array[selectRouteIndex]
        drawRoute()
    }

    var mapView: MGLMapView!
    var mapStyle: Bool! = false
    var replayStartDate: Date!
    var replayEndDate: Date!
    var currentSelectingDate: Int! // 1: startDate, 2: endDate
    var assetList: [AssetModel]!
    var assetLogList: [AssetLogModel]!
    var selectedAsset: AssetModel!
    var points: [CLLocationCoordinate2D]!
    var tempPoints: [CLLocationCoordinate2D]!
    var speedPoints: [CLLocationCoordinate2D] = []
    var speed_Array: [Double]!
    var dateTime_Array: [Date]!
    var partHeader_Array: [String]!
    var speeding_Array: [Int]!
    var harshDriving_Array: [Int]!
    var accOffAlarm_Array: [Int]!
    var accOnAlarm_Array: [Int]!
    var harshAcce_Array: [Int]!
    var harshDece_Array: [Int]!
    var idling_Array: [Int]!
    var plugOut_Array: [Int]!
    var pointIndex_Array: [Int]!
    var velocityState_Array: [Bool]!
    var geoMarkerIndex: Int! = 0
    var startImage: UIImage! = UIImage(named: "start")
    var finishImage: UIImage! = UIImage(named: "finish")
    var speedingImage: UIImage! = UIImage(named: "driverspeeding")
    var harshacceImage: UIImage! = UIImage(named: "replay_harshacce")
    var harshdeceImage: UIImage! = UIImage(named: "replay_desse")
    var idlingImage: UIImage! = UIImage(named: "replay_idling")
    var stopImage: UIImage! = UIImage(named: "stop")
    var animatingTimer: Timer? = nil
    var geocoder: Geocoder!
    var geocodingDataTask: URLSessionDataTask?
    var geocodingDataTask1: URLSessionDataTask?
    var geoAnnotation: CustomAnnotation? = nil
    var startAnnotation: MGLPointAnnotation? = nil
    var endAnnotation: MGLPointAnnotation? = nil
    var startStop: String! = ""
    var lastStop: String! = ""
    var display_mode: String! = "multiVelocity"
    var selectRouteIndex: Int! = -1
    var total_stops: Int! = 0
    var harsh_acce: Int! = 0
    var harsh_dece: Int! = 0
    var total_speeding: Int! = 0
    var top_speed: Double!
   
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "ReplayViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        slider.setThumbImage(UIImage(named: "circle"), for: .normal)
        slider.setThumbImage(UIImage(named: "circle"), for: .selected)
        self.allScrollView.panGestureRecognizer.delaysTouchesBegan = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        initMapView()
        points = [CLLocationCoordinate2D]()
        loadAllDrivers()
        hideDatePicker()
        
        self.replayStartDate = Date()
        self.replayEndDate =  self.replayStartDate.date(plusDay: 1)
        self.label_dateFromTO.text = self.replayStartDate.toString("MM.dd") + " to " + self.replayEndDate.toString("MM.dd")
        self.btnStartDate.setTitle(replayStartDate.toString("MM/dd/yyyy"), for: .normal)
        self.btnEndDate.setTitle(replayEndDate.toString("MM/dd/yyyy"), for: .normal)
        info_table.isHidden = true
        self.topViewHC.constant = self.view.bounds.height * 0.875
        self.btn_nextDay.isEnabled = true
        if display_mode == "oneVelocity" {
            bottomView.isHidden = true
            self.btn_nextDay.isEnabled = false
            routeControlView.isHidden = false
            info_table.isHidden = false
            self.topViewHC.constant = self.view.bounds.height - 33 - 64
            onBtnReport(self)
        }
        self.allScrollView.delegate = self
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == allScrollView {
               self.topStackView.frame.origin.y = allScrollView.contentOffset.y
        }
       
    }
    
    func checkVerticle() {
        let v_lat = Double((self.geoAnnotation?.coordinate.latitude)!);
        let v_lon = Double((self.geoAnnotation?.coordinate.longitude)!);
        let s_top = Double(mapView.visibleCoordinateBounds.ne.latitude);
        let s_bottom = Double(mapView.visibleCoordinateBounds.sw.latitude);
        let s_left = Double(mapView.visibleCoordinateBounds.sw.longitude);
        let s_right = Double(mapView.visibleCoordinateBounds.ne.longitude);
        if(v_lat > s_top || v_lat < s_bottom || v_lon < s_left || v_lon > s_right)
        {
            let zoomlevel = mapView.zoomLevel
            mapView.centerCoordinate = (self.geoAnnotation?.coordinate)!;
            mapView.zoomLevel = zoomlevel
            mapView.removeAnnotation(geoAnnotation!)
            mapView.addAnnotation(geoAnnotation!)
        }
    }
    
    
    func initMapView() {
        self.mapView = MGLMapView(frame: mapViewWrapper.bounds)
        mapView.styleURL = URL(string: "https://osm.spectrumtracking.com/styles/ciw6czz2n00242kmg6hw20box/style.json")
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.attributionButton.isHidden = true
        self.mapViewWrapper.addSubview(mapView)
        mapView.delegate = self
        mapView.zoomLevel = 15.0
        mapView.centerCoordinate = CLLocationCoordinate2D(latitude: 38.2534189, longitude: -85.7551944)
        mapView.allowsRotating = false
    }
    
    func mapView(mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        return UIColor.black
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
                self.bottomTableHC.constant = self.assetSingleSelectTableView.getHeight()
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
        self.btn_forwardR.isEnabled = true
        self.btn_backwardR.isEnabled = false
        self.allScrollView.contentOffset.y = 0
        self.slider.setValue(0.0, animated: true)
        self.topViewHC.constant = self.view.bounds.height - 33 - 64
        self.selectRouteIndex = -1
        if selectedAsset == nil {
            self.view.makeToast("please select vehicle")
            loadAllDrivers()
            return
        }
        self.selectRouteIndex = -1
        let id = selectedAsset._id
        let startTime = replayStartDate.setTime()
        let endTime = replayEndDate.setTime()
        self.label_dateFromTO.text = self.replayStartDate.toString("MM.dd") + " to " + self.replayEndDate.toString("MM.dd")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-M-d HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "GMT")
        
        let startTimeString = dateFormatter.string(from: startTime) + ".000Z"
        let endTimeString = dateFormatter.string(from: endTime) + ".000Z"
        
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
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.hideLoader()
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                
                if let annotiations = self.mapView.annotations
                {
                    self.mapView.removeAnnotations(annotiations)
                }
                
                let items = json["items"]
                // print(items)
                self.assetLogList = [AssetLogModel]()
                
                for i in 0..<items.count {
                    self.assetLogList.append(AssetLogModel.parseJSON(items[i]))
                }
                
                if self.assetLogList.count != 0 {
                    self.btn_forwardR.isEnabled = true
                    self.btn_playR.isEnabled = true
                    self.drawPath()
                } else {
                    self.view.makeToast("No Data.Change to another day.")
                    self.btn_forwardR.isEnabled = false
                    self.btn_playR.isEnabled = false
                    self.slider.isHidden = true
                    self.label_totalSpeeding.text = String(0)
                    self.label_harshAcce.text = String(0)
                    self.label_harshDece.text = String(0)
                    self.label_topSpeed.text = String(0)
                    self.label_totalStops.text = String(0)
                }

            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
            self.hideLoader()
            
        }
    }
    
    @IBAction func onDateSelect(_ sender: Any) {
        if dateSelect.selectedSegmentIndex == 0 {
            self.replayStartDate = datePicker.date
            dateSelect.selectedSegmentIndex = 1
            datePicker.setDate(replayEndDate, animated: true)
            self.btnStartDate.setTitle(replayStartDate.toString("MM/dd/yyyy"), for: .normal)
        } else {
            self.replayEndDate = datePicker.date
            self.btnEndDate.setTitle(replayEndDate.toString("MM/dd/yyyy"), for: .normal)
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
            if routeControlView.isHidden {
                routeControlView.isHidden = false
                info_table.isHidden = false
                self.topViewHC.constant = self.topViewHC.constant - 33 - 64
            }
            slider.isHidden = true
            allRoute_header.isHidden = false
            partRoute_header.isHidden = true
            onBtnReport(self)
        }
        
    }
    func drawRoute() {
        if selectRouteIndex < 0 || selectRouteIndex > pointIndex_Array.count-2{
            return
        }
        tempPoints = [CLLocationCoordinate2D]()
        var tempSpeedPoints:[CLLocationCoordinate2D] = [CLLocationCoordinate2D]()
        let startIndex = pointIndex_Array[selectRouteIndex]
        var endIndex = pointIndex_Array[selectRouteIndex+1]
        if !velocityState_Array[selectRouteIndex] {
            endIndex = startIndex
            self.mapView.maximumZoomLevel = 15
        }
        self.total_speeding = 0
        self.harsh_acce = 0
        self.harsh_dece = 0
        self.top_speed = 0
        print(startIndex)
        print(endIndex)
        var prev_speedState : Int = -1
        var speedState : Int = 0
        if let annotiations = self.mapView.annotations
        {
            self.mapView.removeAnnotations(annotiations)
        }
//        var eventIndex = 0
//        for i in 0...startIndex {
//            if ((accOffAlarm_Array.count > i + 1) && accOffAlarm_Array[i] == 1) {
//                eventIndex += 1
//            }
//
//            if ((accOnAlarm_Array.count > i + 1) && accOnAlarm_Array[i] == 1) {
//                eventIndex += 1
//            }
//        }
        for index in startIndex...endIndex {
            let device = assetLogList[index]
            let lat = abs(device.lat)
            let lng = abs(device.lng)
            
            if lat != 0 && lng != 0 && abs(lng) < 180 && abs(lat) < 180 {
                let point = CLLocationCoordinate2D(latitude: device.lat, longitude: device.lng)
                
                if prev_speedState == -1
                {
                    prev_speedState = getSpeedState(speed: device.speedInMph)
                }
                if top_speed < device.speedInMph {
                    self.top_speed = device.speedInMph
                }
                speedState = getSpeedState(speed: device.speedInMph)
                if( speedState == prev_speedState)
                {
                    tempSpeedPoints.append(point)
                    prev_speedState = speedState
                }
                else
                {
                    tempSpeedPoints.append(point)
                    let speedline = MGLPolyline(coordinates: tempSpeedPoints, count: UInt(tempSpeedPoints.count))
                    switch prev_speedState {
                    case 0:
                        speedline.title = "45"
                        break;
                    case 1:
                        speedline.title = "60"
                        break;
                    case 2:
                        speedline.title = "80"
                        break;
                    case 3:
                        speedline.title = "over"
                        break
                    default:
                        speedline.title = "60"
                    }
                    
                    self.mapView.addAnnotation(speedline)
                    tempSpeedPoints.removeAll()
                    tempSpeedPoints.append(point)
                    prev_speedState = speedState
                }
            }
            let currentPoint = points[index]
            tempPoints.append(currentPoint)
            let currentTime = dateTime_Array[index].toString("MM/dd/yyyy hh:mm:ss a")
            if (speeding_Array.count > index + 1 && speeding_Array[index] == 1) {
                let annotation = MGLPointAnnotation()
                annotation.coordinate = currentPoint
                annotation.title = "speeding"
                mapView.addAnnotation(annotation)
                self.total_speeding += 1
            }
            if (harshAcce_Array.count > index + 1 && harshAcce_Array[index] == 1) {
                let annotation = MGLPointAnnotation()
                annotation.coordinate = currentPoint
                annotation.title = "harshAcce"
                mapView.addAnnotation(annotation)
                self.harsh_acce += 1
            }
            
            if (harshDece_Array.count > index + 1 && harshDece_Array[index] == 1) {
                let annotation = MGLPointAnnotation()
                annotation.coordinate = currentPoint
                annotation.title = "harshDece"
                mapView.addAnnotation(annotation)
                self.harsh_dece += 1
            }
            
            if (idling_Array.count > index + 1 && idling_Array[index] == 1) {
                let annotation = MGLPointAnnotation()
                annotation.coordinate = currentPoint
                annotation.title = "idling"
                mapView.addAnnotation(annotation)
            }
            
            
            if ((accOffAlarm_Array.count > index + 1) && accOffAlarm_Array[index] == 1) {
                let annotation = MGLPointAnnotation()
                annotation.coordinate = currentPoint
                annotation.title = "stop at \(currentTime)"
                annotation.subtitle = String(selectRouteIndex+1)
                mapView.addAnnotation(annotation)
                self.total_stops += 1
            }
            
            if ((accOnAlarm_Array.count > index + 1) && accOnAlarm_Array[index] == 1) {
                let annotation = MGLPointAnnotation()
                annotation.coordinate = currentPoint
                annotation.title = "start"
                annotation.subtitle = String(selectRouteIndex+1)
                mapView.addAnnotation(annotation)
            }
            
        }
        let speedline = MGLPolyline(coordinates: tempSpeedPoints, count: UInt(tempSpeedPoints.count))
        switch prev_speedState {
        case 0:
            speedline.title = "45"
            break;
        case 1:
            speedline.title = "60"
            break;
        case 2:
            speedline.title = "80"
            break;
        case 3:
            speedline.title = "over"
            break
        default:
            speedline.title = "60"
        }
        self.mapView.addAnnotation(speedline)
        let line = MGLPolyline(coordinates: tempPoints, count: UInt(tempPoints.count))
        mapView.camera = mapView.cameraThatFitsCoordinateBounds(line.overlayBounds, edgePadding: UIEdgeInsets(top: 50, left: 20, bottom: 50, right: 20))
        zoom_Slider.value = Float(mapView.zoomLevel)
        let routeLength = tempPoints.count
        let _ = {
            self.geoAnnotation = CustomAnnotation()
            self.geoAnnotation!.coordinate = tempPoints.first!
            self.geoAnnotation!.title = "geo"
            
            mapView.addAnnotation(self.geoAnnotation!)
        }()
        self.label_totalSpeeding.text = String(self.total_speeding)
        self.label_harshAcce.text = String(self.harsh_acce)
        self.label_harshDece.text = String(self.harsh_dece)
        self.label_topSpeed.text = String(self.top_speed)
        if !velocityState_Array[selectRouteIndex] {
            self.label_topSpeed.text = "0"
        }
        geoMarkerIndex = 0
        slider.minimumValue = 0
        slider.maximumValue = Float(routeLength - 1)
        slider.setValue(0.0, animated: true)
    }
    
    func drawPath() {
        var firstStop = -1;
        var lastStop = 0;
        self.total_speeding = 0
        self.harsh_acce = 0
        self.harsh_dece = 0
        self.top_speed = 0
        self.total_stops = 0
        points = [CLLocationCoordinate2D]()
        speedPoints = [CLLocationCoordinate2D]()
        tempPoints = [CLLocationCoordinate2D]()
        speed_Array = [Double]()
        dateTime_Array = [Date]()
        speeding_Array = [Int]()
        harshDriving_Array = [Int]()
        accOffAlarm_Array = [Int]()
        accOnAlarm_Array = [Int]()
        pointIndex_Array = [Int]()
        velocityState_Array = [Bool]()
        harshAcce_Array = [Int]()
        harshDece_Array = [Int]()
        idling_Array = [Int]()
        plugOut_Array = [Int]()
        //pointIndex_Array.append(0)
        var speedState : Int = 0
        var prev_speedState : Int = -1
        var prev_accStatus : Int = 0
        var ACCStatusNum : Int = 0
        var diffTime: Int = 0
        for i in 0 ..< assetLogList.count {
            let device = assetLogList[i]
            let lat = abs(device.lat)
            let lng = abs(device.lng)
            
            let trackerModel = device.trackerModel as String
            //print("\(lat):\(lng)")
            if lat != 0 && lng != 0 && abs(lng) < 180 && abs(lat) < 180 {
                let dateTime = device.dateTime.toString("MM/dd/yyyy hh:mm:ss a")
                //print(dateTime)
                dateTime_Array.append(device.dateTime)
                var point = CLLocationCoordinate2D(latitude: device.lat, longitude: device.lng)
                // print(point)
                if prev_speedState == -1
                {
                    prev_speedState = getSpeedState(speed: device.speedInMph)
                }
                if self.top_speed < device.speedInMph {
                    self.top_speed = device.speedInMph
                }
                speedState = getSpeedState(speed: device.speedInMph)
                if( speedState == prev_speedState)
                {
                    speedPoints.append(point)
                    prev_speedState = speedState
                }
                else
                {
                    speedPoints.append(point)
                    let speedline = MGLPolyline(coordinates: speedPoints, count: UInt(speedPoints.count))
                    switch prev_speedState {
                    case 0:
                        speedline.title = "45"
                        break;
                    case 1:
                        speedline.title = "60"
                        break;
                    case 2:
                        speedline.title = "80"
                        break;
                    case 3:
                        speedline.title = "over"
                        break
                    default:
                        speedline.title = "60"
                    }
                    
                    mapView.addAnnotation(speedline)
                    speedPoints.removeAll()
                    speedPoints.append(point)
                    prev_speedState = speedState
                }
                
                
                var coorOld : CLLocationCoordinate2D!
                
                if (trackerModel == ("huaheng") || trackerModel == ("mictrack")) {
                    if i != 0 && i != assetLogList.count - 1 {
                        let dateTimeNow = assetLogList[i].dateTime
                        let dateTimeNext = assetLogList[i+1].dateTime
                        diffTime = (dateTimeNext?.seconds(from: dateTimeNow!))!
                        print("diffTime:\(diffTime)")
                    }
                    if (device.ACCStatus == 1 && prev_accStatus == 0 && diffTime > 12) {
                        accOnAlarm_Array.append(1)
                        accOffAlarm_Array.append(0)
                    }
                    else if (device.ACCStatus == 0 && prev_accStatus == 1) {
                        coorOld = point;
                        accOffAlarm_Array.append(1)
                        accOnAlarm_Array.append(0)
                    }
                    else if (device.ACCStatus == 0 && prev_accStatus == 0) {
                        if coorOld != nil {
                            point = coorOld
                        }
                        else {
                            coorOld = point
                        }
                        accOffAlarm_Array.append(0)
                        accOnAlarm_Array.append(0)
                    }
                    else {
                        accOffAlarm_Array.append(0)
                        accOnAlarm_Array.append(0)
                    }
                   
                    prev_accStatus = device.ACCStatus
                }
                
                if trackerModel == ("sinocastel") {
                    if device.speedInMph == 0 && ACCStatusNum == 0 {
                        coorOld = point
                        ACCStatusNum = ACCStatusNum + 1;
                    }
                    else if device.speedInMph == 0 && ACCStatusNum > 0 && coorOld != nil{
                        point = coorOld
                    }
                    else {
                        ACCStatusNum = 0
                    }
                }
                speed_Array.append(device.speedInMph)
                points.append(point)
                tempPoints.append(point)
                
                
                if trackerModel == "huaheng" {
                    if device.huaheng != nil {
                        let alarm: Int! = device.huaheng!.alarmNumberAdd1 - 1
                        if alarm == 3 {
                            speeding_Array.append(1)
                        } else {
                            speeding_Array.append(0)
                        }
                        //
                        if alarm == 7 {
                            harshDece_Array.append(1)
                        } else {
                            harshDece_Array.append(0)
                        }
                        
                        if alarm == 8 {
                            harshAcce_Array.append(1)
                        } else {
                            harshAcce_Array.append(0)
                        }
                        
                        if alarm == 14 {
                            idling_Array.append(1)
                        } else {
                            idling_Array.append(0)
                        }
                        
                        if alarm == 16{
                            plugOut_Array.append(1)
                        } else {
                            plugOut_Array.append(0)
                        }
                        
                    } else {
                        speeding_Array.append(0)
                        harshDece_Array.append(0)
                        harshAcce_Array.append(0)
                        idling_Array.append(0)
                        plugOut_Array.append(0)
                    }
                } else if (trackerModel.lowercased() == "sinocastel" && device.reportType != "sinoOBDPackage") {
                    if (device.sinocastel != nil && device.reportType == "sinoAlarmPackage") {
                        if device.sinocastel!.vehicleStatus != nil {
                            
                            let vehicleStatus = device.sinocastel!.vehicleStatus!
                            if vehicleStatus.hardAcce != -1
                            {
                                harshAcce_Array.append(1)
                            }
                            else
                            {
                                harshAcce_Array.append(0)
                            }
                            
                            if vehicleStatus.hardDece != -1
                            {
                                harshDece_Array.append(1)
                            }
                            else
                            {
                                harshDece_Array.append(0)
                            }
                            
                            if vehicleStatus.idleEngine != -1
                            {
                                idling_Array.append(1)
                            }
                            else
                            {
                                idling_Array.append(0)
                            }
                            
                            if vehicleStatus.ignitionOff != 0 {
                                accOffAlarm_Array.append(1)
                            } else {
                                accOffAlarm_Array.append(0)
                            }
                            
                            if vehicleStatus.speeding != -1 {
                                speeding_Array.append(1)
                            } else {
                                speeding_Array.append(0)
                            }
                            
                            if vehicleStatus.ignitionOn != 0 {
                                accOnAlarm_Array.append(1)
                            } else {
                                accOnAlarm_Array.append(0)
                            }
                        }
                        else {
                            idling_Array.append(0)
                            harshAcce_Array.append(0)
                            harshDece_Array.append(0)
                            accOffAlarm_Array.append(0)
                            speeding_Array.append(0)
                            accOnAlarm_Array.append(0)
                        }
                    } else {
                        idling_Array.append(0)
                        harshAcce_Array.append(0)
                        harshDece_Array.append(0)
                        accOffAlarm_Array.append(0)
                        speeding_Array.append(0)
                        accOnAlarm_Array.append(0)
                    }
                } else if trackerModel == "cctr" {
                    if device.cctr != nil {
                        if device.cctr!.vehicleStatus != nil {
                            let vehicleStatus = device.cctr!.vehicleStatus!
                            
                            harshDriving_Array.append(0)
                            
                            if vehicleStatus.overSpeed2 != -1{
                                speeding_Array.append(1)
                            } else {
                                speeding_Array.append(0)
                            }
                        }
                    } else {
                        idling_Array.append(0)
                        harshAcce_Array.append(0)
                        harshDece_Array.append(0)
                        accOffAlarm_Array.append(0)
                        speeding_Array.append(0)
                        accOnAlarm_Array.append(0)
                    }
                } else {
                    // idling_Array.append(0)
                    //harshAcce_Array.append(0)
                    //harshDece_Array.append(0)
                    //accOffAlarm_Array.append(0)
                    //speeding_Array.append(0)
                    //accOnAlarm_Array.append(0)
                }
            }
        }
        
        //draw last polyine added by robin
        //
        let speedline = MGLPolyline(coordinates: speedPoints, count: UInt(speedPoints.count))
        switch prev_speedState {
        case 0:
            speedline.title = "45"
            break;
        case 1:
            speedline.title = "60"
            break;
        case 2:
            speedline.title = "80"
            break;
        case 3:
            speedline.title = "over"
            break
        default:
            speedline.title = "45"
        }
        mapView.addAnnotation(speedline)
        //
        ///////////////
        let line = MGLPolyline(coordinates: points, count: UInt(points.count))
        //mapView.addAnnotation(line)
        
        mapView.camera = mapView.cameraThatFitsCoordinateBounds(line.overlayBounds, edgePadding: UIEdgeInsets(top: 50, left: 20, bottom: 50, right: 20))
        zoom_Slider.value = Float(mapView.zoomLevel)
        let routeLength = points.count
        
        slider.minimumValue = 0
        slider.maximumValue = Float(routeLength - 1)
        slider.setValue(0.0, animated: true)
        
        var eventIndex = 0
        for index in 0..<routeLength {
            let currentPoint = points[index]
            let currentTime = dateTime_Array[index]
            if (speeding_Array.count > index + 1 && speeding_Array[index] == 1) {
                let annotation = MGLPointAnnotation()
                annotation.coordinate = currentPoint
                annotation.title = "speeding"
                //print("speeding********************")
                mapView.addAnnotation(annotation)
                self.total_speeding += 1
            }
            if (harshAcce_Array.count > index + 1 && harshAcce_Array[index] == 1) {
                let annotation = MGLPointAnnotation()
                annotation.coordinate = currentPoint
                annotation.title = "harshAcce"
                //print("harshAcce********************")
                mapView.addAnnotation(annotation)
                self.harsh_acce += 1
            }
            
            if (harshDece_Array.count > index + 1 && harshDece_Array[index] == 1) {
                let annotation = MGLPointAnnotation()
                annotation.coordinate = currentPoint
                annotation.title = "harshDece"
                //print("harshDece********************")
                mapView.addAnnotation(annotation)
                self.harsh_dece += 1
            }
            
            if (idling_Array.count > index + 1 && idling_Array[index] == 1) {
                let annotation = MGLPointAnnotation()
                annotation.coordinate = currentPoint
                annotation.title = "idling"
                //print("idling********************")
                mapView.addAnnotation(annotation)
            }
            
            
            if ((accOffAlarm_Array.count > index + 1) && accOffAlarm_Array[index] == 1) {
                if(firstStop == -1) {
                    firstStop = index
                }
                lastStop = index
                let annotation = MGLPointAnnotation()
                annotation.coordinate = currentPoint
                annotation.title = "stop at \(currentTime)"
                annotation.subtitle = "all route"
                mapView.addAnnotation(annotation)
                print("stop\(index)")
                eventIndex = eventIndex + 1
            }
            if ((accOnAlarm_Array.count > index + 1) && accOnAlarm_Array[index] == 1) {
                if(firstStop == -1) {
                    firstStop = index
                }
                lastStop = index
                let annotation = MGLPointAnnotation()
                annotation.coordinate = currentPoint
                annotation.title = "start"
                annotation.subtitle = "all route"
                print("start\(index)")
                mapView.addAnnotation(annotation)
                eventIndex = eventIndex + 1
            }
        }
        if(firstStop != -1) {
            setReports(firstStop: firstStop, lastStop: lastStop)
            self.btn_forwardR.isEnabled = true
        }
        else {
            self.btn_forwardR.isEnabled = false
        }
        self.label_totalSpeeding.text = String(self.total_speeding)
        self.label_harshAcce.text = String(self.harsh_acce)
        self.label_harshDece.text = String(self.harsh_dece)
        self.label_topSpeed.text = String(self.top_speed)
        let _ = {
            self.geoAnnotation = CustomAnnotation()
            self.geoAnnotation!.coordinate = points.first!
            self.geoAnnotation!.title = "geo"
            
            mapView.addAnnotation(self.geoAnnotation!)
        }()
        geoMarkerIndex = 0
        routeControlView.isHidden = false
        slider.isHidden = false
        info_table.isHidden = false
        allRoute_header.isHidden = false
        partRoute_header.isHidden = true
    }
    func setReports(firstStop:Int,lastStop:Int) {
        let MapboxAccessToken = "pk.eyJ1Ijoid29vbGVlMTA2IiwiYSI6ImNqbzNjdWRwbTBxcjEzcHFuOWwxdGs5NXIifQ.ZDt6AmvMcsM3SeT5zy8GBg"
        geocoder = Geocoder(accessToken: MapboxAccessToken)
        self.geocodingDataTask?.cancel()
        let options = ReverseGeocodeOptions(coordinate: points[firstStop])
        self.geocodingDataTask = self.geocoder.geocode(options) { [unowned self] (placemarks, attribution, error) in
            if let error = error {
                NSLog("%@", error)
            } else if let placemarks = placemarks, !placemarks.isEmpty {
                
                self.startStop  = placemarks[0].qualifiedName!
            } else {
                self.startStop  = "Unknown Address"
            }
            self.geocodingDataTask1?.cancel()
            let options1 = ReverseGeocodeOptions(coordinate: self.points[lastStop])
            self.geocodingDataTask1 = self.geocoder.geocode(options1) { [unowned self] (placemarks, attribution, error) in
                if let error = error {
                    NSLog("%@", error)
                } else if let placemarks = placemarks, !placemarks.isEmpty {
                    
                    self.lastStop  = placemarks[0].qualifiedName!
                } else {
                    self.lastStop  = "Unknown Address"
                }
                self.setAllReports(firstStop: firstStop, lastStop: lastStop)
            }
        }
    }
    func setAllReports(firstStop:Int,lastStop:Int) {
        let routeLength = points.count
        self.partHeader_Array = [String]()
        var report_txt = ""
        var position = ""
        var pastTime:Date!
        var lastIndex:Int!
        var total_stop = 0
        var eventNum = 1
        var mode = ""
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        for index in 0..<routeLength {
            let currentTime = formatter.date(from:dateTime_Array![index].toString("yyyy/MM/dd HH:mm"))
            if ((accOnAlarm_Array.count > index + 1) && accOnAlarm_Array[index] == 1) {
                if(index == lastStop) {
                    position = self.lastStop
                }
                else if(index == firstStop) {
                    position = self.startStop
                }
                if pastTime != nil
                {
                    
                    let formatter = DateComponentsFormatter()
                    formatter.allowedUnits = [.year,.month,.day,.hour,.minute]
                    formatter.unitsStyle = .full
                    var daysString = formatter.string(from: pastTime, to:currentTime!)
                    var pointFlag = false
                    if mode == "stop" {
                        if position != "" {
                            position = "at " + position
                            pointFlag = true
                        }
                        report_txt += String(eventNum) + ": Stop " + position + " at " + pastTime.toString("MM/dd hh:mm a") + " for " + daysString! + "\n\n"
                        partHeader_Array.append(daysString! + " Stop at " + pastTime.toString("MM/dd hh:mm a"))
                    }
                    else if mode == "left" {
                        if position != "" {
                            position = "from " + position
                            pointFlag = true
                        }
                        if daysString == "0 minutes" {
                            daysString = ""
                        }
                        report_txt += String(eventNum) + ": Trip " + daysString! + ". Left " + position + " at " + pastTime.toString("MM/dd hh:mm a") + "\n\n"
                        partHeader_Array.append(daysString! + " Trip " + pastTime.toString("MM/dd hh:mm a") + " -- " + currentTime!.toString("MM/dd hh:mm a"))
                    }
                    self.reportLabel.numberOfLines += 3
                    eventNum += 1
                    if pointFlag {
                        position = ""
                    }
                }
                lastIndex = index
                pastTime = currentTime
                mode = "left"
                pointIndex_Array.append(index)
                velocityState_Array.append(true)
                print("left\(index)")
            }
            if ((accOffAlarm_Array.count > index + 1) && accOffAlarm_Array[index] == 1) {
                
                if pastTime != nil
                {
                    let formatter = DateComponentsFormatter()
                    formatter.allowedUnits = [.year,.month,.day,.hour,.minute]
                    formatter.unitsStyle = .full
                    var daysString = formatter.string(from: pastTime, to:currentTime!)
                    var pointFlag = false
                    
                    if mode == "stop" {
                        if position != "" {
                            position = "at " + position
                            pointFlag = true
                        }
                        report_txt += String(eventNum) + ": Stop " + position + " at " + pastTime.toString("MM/dd hh:mm a") + " for " + daysString! + "\n\n"
                        partHeader_Array.append(daysString! + " Stop at " + pastTime.toString("MM/dd hh:mm a"))
                    }
                    else if mode == "left" {
                        if position != "" {
                            position = "from " + position
                            pointFlag = true
                        }
                        if daysString == "0 minutes" {
                            daysString = ""
                        }
                        report_txt += String(eventNum) + ": Trip " + daysString! + ". Left " + position + " at " + pastTime.toString("MM/dd hh:mm a") + "\n\n"
                        partHeader_Array.append(daysString! + " Trip " + pastTime.toString("MM/dd hh:mm a") + " -- " + currentTime!.toString("MM/dd hh:mm a"))
                    }
                    
                    
                    self.reportLabel.numberOfLines += 3
                    eventNum += 1
                    if pointFlag {
                        position = ""
                    }
                }
                if(index == lastStop) {
                    position = self.lastStop
                }
                else if(index == firstStop) {
                    position = self.startStop
                }
                total_stop += 1
                pastTime = currentTime
                mode = "stop"
                pointIndex_Array.append(index)
                velocityState_Array.append(false)
                print("stop\(index)")
            }
        }
        if accOnAlarm_Array.count >= pointIndex_Array.count && accOnAlarm_Array[pointIndex_Array[pointIndex_Array.count-1]] == 1 {
            if position != "" {
                position = "from " + position
            }
            report_txt += String(eventNum) + ": Trip Left " + position + " at " + dateTime_Array[pointIndex_Array[pointIndex_Array.count-1]].toString("MM/dd hh:mm a") + "\n"
            self.reportLabel.numberOfLines += 3
        }
        else {
            report_txt += String(eventNum) + ": Stop " + position + " at " + dateTime_Array[pointIndex_Array[pointIndex_Array.count-1]].toString("MM/dd hh:mm a") + "\n"
            self.reportLabel.numberOfLines += 3
        }
        self.reportLabel!.text = report_txt
        self.label_totalStops.text = String(total_stop)
        if pointIndex_Array.count <= 2 {
            self.btn_forwardR.isEnabled = false
        }
        print(pointIndex_Array)
    }
    func getSpeedState(speed: Double) -> Int{
        if( speed <= 45) {
            return 0
        }
        else if( speed <= 60) {
            return 1
        }
        else if( speed <= 80){
            return 2
        }
        else
        {
            return 3
        }
    }
    
    func startAnimation() {
        if animatingTimer != nil {
            animatingTimer!.invalidate()
        }
        self.mapView.maximumZoomLevel = 15
        animatingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            //  print("\(self.geoMarkerIndex):\(self.tempPoints.count)")
            if self.tempPoints != nil && self.geoMarkerIndex >= self.tempPoints.count {
                timer.invalidate()
                print("end")
                self.btn_playR.setImage(UIImage(named: "ic_play"), for: .normal)
                self.animatingTimer = nil
                return
            }
            
            self.showReplayPointOfIndex()
            self.geoMarkerIndex = self.geoMarkerIndex + 1
        })
        
    }
    
    func degreesToRadians(degrees: Double) -> Double { return degrees * .pi / 180.0 }
    func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / .pi }
    
    func getBearingBetweenTwoPoints1(point1 : CLLocationCoordinate2D, point2 : CLLocationCoordinate2D) -> CGFloat {
        
        let lat1 = degreesToRadians(degrees: point1.latitude)
        let lon1 = degreesToRadians(degrees: point1.longitude)
        
        let lat2 = degreesToRadians(degrees: point2.latitude)
        let lon2 = degreesToRadians(degrees: point2.longitude)
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return CGFloat(radiansBearing)
    }
    func showReplayPointOfIndex() {
        
        if geoMarkerIndex >= tempPoints.count {
            if animatingTimer != nil {
                animatingTimer!.invalidate()
            }
            self.btn_playR.setImage(UIImage(named: "ic_play"), for: .normal)
        }
        var speed = min(speed_Array[geoMarkerIndex], 100)
        var dateString = dateTime_Array[geoMarkerIndex]
        if selectRouteIndex != -1 {
            speed = min(speed_Array[pointIndex_Array[selectRouteIndex] + geoMarkerIndex], 100)
            dateString = dateTime_Array[pointIndex_Array[selectRouteIndex] + geoMarkerIndex]
        }
        if geoAnnotation != nil {
            self.mapView.removeAnnotation(geoAnnotation!)
            
            self.geoAnnotation = CustomAnnotation()
            self.geoAnnotation!.coordinate = tempPoints[geoMarkerIndex]
            self.geoAnnotation!.title = "geo"
            self.geoAnnotation!.heading = getBearingBetweenTwoPoints1(point1: tempPoints[geoMarkerIndex], point2: tempPoints[(geoMarkerIndex + 1) % tempPoints.count])
            
            mapView.addAnnotation(self.geoAnnotation!)
        }
        self.setSpeed(Int(speed))
        self.labelGageDate.text = dateString.toString("MM/dd HH:mm")
        
        slider.value = Float(geoMarkerIndex)
        checkVerticle();
    }
    
    func setSpeed(_ speed: Int) {
        labelSpeed.text = speed.toString()
        
        
        let angle = CGFloat.pi / 2 * 3 * CGFloat(speed) / 100
        let tr = CGAffineTransform(rotationAngle: angle)
        
        speedIndicator.transform = tr
        
        
    }
    
    @IBAction func onBtnPlayPause(_ sender: Any) {
        if animatingTimer == nil {
            self.btn_playR.setImage(UIImage(named: "ic_pause"), for: .normal)
            startAnimation()
        } else {
            self.mapView.maximumZoomLevel = 30
            animatingTimer!.invalidate()
            animatingTimer = nil
            self.btn_playR.setImage(UIImage(named: "ic_play"), for: .normal)
        }
    }
    
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        let progressChangedValue = Int(slider.value)
        self.geoMarkerIndex = progressChangedValue
        
        self.showReplayPointOfIndex()
    }
}


// MGLMapViewDelegate delegate
extension ReplayViewController: MGLMapViewDelegate {
    // Use the default marker. See also: our view annotation or custom marker examples.
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        if( annotation.title == "45") {
            return UIColor(hexInt: 0xF96F00)
        }
        else if ( annotation.title == "60")
        {
            return .blue
        }
        else if ( annotation.title == "80")
        {
            return .green
        }
        else if ( annotation.title == "over")
        {
            return .red
        }
        return UIColor(red: 0.0, green: 0.0, blue: 0.502, alpha: 1.0)
    }
    
    func mapView(_ mapView: MGLMapView, didAdd annotationViews: [MGLAnnotationView])
    {
        
        //        for annView in annotationViews
        //        {
        //            let ant = annView.annotation!st
        //            let title = ant.title ?? ""
        //            if title == "geo" {
        //                mapView.bringSubview(toFront: annView)
        //            }
        //        }
        
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView?
    {
        let title = annotation.title ?? ""
        if title == "geo" {
            let annotation = annotation as! CustomAnnotation
            let kk = MGLAnnotationView.init(annotation: annotation, reuseIdentifier: "pos")
            kk.frame = CGRect.init(x: 0, y: 0, width: 40, height: 40)
            let iv = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 40, height: 40))
            let rotation = annotation.heading!
            var geoImage: UIImage! = UIImage(named: "cartoprightsmall")
            geoImage = geoImage.image(withRotation: 3.141592/2.0 - rotation)
            iv.image = geoImage
            kk.addSubview(iv)
            return kk
        }
        else if title?.range(of: "stop") != nil && annotation.subtitle != "all route"{
            let reuseIdentifier = title
            // For better performance, always try to reuse existing annotations.
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier ?? "stop")
            // If there’s no reusable annotation view available, initialize a new one.
            if annotationView == nil {
                annotationView = MGLAnnotationView(reuseIdentifier: reuseIdentifier)
                annotationView?.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
                
                let iv = UIImageView.init(frame: CGRect.init(x: 0, y: 8, width: 20 , height: 20))
                iv.image = stopImage.scaleImageToFitSize(size: CGSize(width:20,height:20))
                annotationView?.addSubview(iv)
                
                let view = UIView()
                view.frame = CGRect(x: 12, y: 0, width: 16, height: 16)
                view.layer.cornerRadius = (view.frame.size.width) / 2
                view.layer.borderWidth = 1.0
                view.layer.borderColor = UIColor.white.cgColor
                view.backgroundColor = UIColor.red
                
                let label = UILabel()
                label.text = annotation.subtitle ?? "?"
                label.font = UIFont.boldSystemFont(ofSize: 9.5)
                label.textAlignment = .center
                label.textColor = UIColor.white
                label.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
                view.addSubview(label)
                
                annotationView?.addSubview(view)
            }
            return annotationView
        }
        else if title?.range(of: "start") != nil && annotation.subtitle != "all route"{
            let reuseIdentifier = title
            // For better performance, always try to reuse existing annotations.
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier ?? "start")
            // If there’s no reusable annotation view available, initialize a new one.
            if annotationView == nil {
                annotationView = MGLAnnotationView(reuseIdentifier: reuseIdentifier)
                annotationView?.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
                
                let iv = UIImageView.init(frame: CGRect.init(x: 0, y: 8, width: 20 , height: 20))
                iv.image = startImage.scaleImageToFitSize(size: CGSize(width:20,height:20))
                annotationView?.addSubview(iv)
                
                let view = UIView()
                view.frame = CGRect(x: 12, y: 0, width: 16, height: 16)
                view.layer.cornerRadius = (view.frame.size.width) / 2
                view.layer.borderWidth = 1.0
                view.layer.borderColor = UIColor.white.cgColor
                view.backgroundColor = UIColor(hexInt: 0x63cf0d)
                
                let label = UILabel()
                label.text = annotation.subtitle ?? "?"
                label.font = UIFont.boldSystemFont(ofSize: 9.5)
                label.textAlignment = .center
                label.textColor = UIColor.white
                label.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
                view.addSubview(label)
                
                annotationView?.addSubview(view)
            }
            return annotationView
        }
        return nil;
    }
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation)
    {
        
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        
        let title = annotation.title ?? ""
        if title == "speeding" {
            return MGLAnnotationImage(image: speedingImage.scaleImageToFitSize(size: CGSize(width:25,height:25)), reuseIdentifier: "speedingimage")
        } else if title == "harshAcce" {
            return MGLAnnotationImage(image: harshacceImage.scaleImageToFitSize(size: CGSize(width:25,height:25)), reuseIdentifier: "harshacceicon")
        } else if title == "harshDece" {
            return MGLAnnotationImage(image: harshdeceImage.scaleImageToFitSize(size: CGSize(width:25,height:25)), reuseIdentifier: "harshdeceicon")
        } else if title == "idling" {
            return MGLAnnotationImage(image: idlingImage.scaleImageToFitSize(size: CGSize(width:25,height:25)), reuseIdentifier: "idlingicon")
        }
        else if title == "arrow" {
            let annotation = annotation as! CustomAnnotation
            let rotation = annotation.heading!
            var geoImage: UIImage! = UIImage(named: "greenarrow")
            geoImage = geoImage.image(withRotation: 3.141592/2.0 - rotation)
            let reuseIdentifier = "arrow-\(annotation.coordinate.longitude)"
            
            return MGLAnnotationImage(image: geoImage, reuseIdentifier: reuseIdentifier)
        }
        else if title == "start" && annotation.subtitle == "all route" {
            return MGLAnnotationImage(image: startImage.scaleImageToFitSize(size: CGSize(width:25,height:25)), reuseIdentifier: "starticon")
        }
        else if title?.range(of: "stop") != nil && annotation.subtitle == "all route" {
            return MGLAnnotationImage(image: stopImage.scaleImageToFitSize(size: CGSize(width:25,height:25)), reuseIdentifier: "stopicon")
        }
        else
        {
            return nil
        }
    }
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        let title = annotation.title ?? ""
        if title?.range(of: "stop") != nil {
            return true
        }
        else {
            return false
        }
    }
    
    // Allow callout view to appear when an annotation is tapped.
    //    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
    //        return false
    //    }
    
}
