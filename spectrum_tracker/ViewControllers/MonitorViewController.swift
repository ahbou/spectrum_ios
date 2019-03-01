//
//  MonitorViewController.swift
//  spectrum_tracker
//
//  Created by JO on 2018/5/7.
//  Copyright © 2018 JO. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Toast_Swift
import Mapbox
import MapboxGeocoder
import SwiftyUserDefaults
import MapKit
import CoreLocation
import VerticalSteppedSlider
import SCLAlertView
import AudioToolbox

class AddressAnnotation: MGLPointAnnotation {
    var displayFlag: Bool = false
}

class MonitorViewController: ViewControllerWaitingResult,UIScrollViewDelegate {

    @IBOutlet var mapViewFrameView: UIView!
    @IBOutlet var velocityTableView: VelocityTableView!
    @IBOutlet var bottomTableHC: NSLayoutConstraint!
    @IBOutlet var indicator: UIActivityIndicatorView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var zoom_Slider: VSSlider!
    @IBOutlet var velocityTableHC: NSLayoutConstraint!
    @IBOutlet var optionsView: UIView!
    @IBOutlet var rateView: UIView!
    @IBOutlet var velocityTableHeader: UIView!
    @IBOutlet var replayRouteView: UIView!
    private var btn_show_pos_y: CGFloat!
    private var changeDisplayFlag: Bool!
    @IBAction func actionVShow(_ sender: UIButton) {
        self.velocityTableView.isHidden = !self.velocityTableView.isHidden
        self.velocityTableHeader.isHidden = !self.velocityTableHeader.isHidden
        if self.velocityTableView.isHidden {
            sender.setImage(UIImage(named: "btn_tableshow"),for:.normal)
        }
        else {
            sender.setImage(UIImage(named: "btn_tablehide"),for:.normal)
        }
    }
    @IBOutlet var velocityView: UIView!
    @IBOutlet var assetMultiSelectTableView: AssetMultiSelectMoniterTableView! {
        didSet {
            assetMultiSelectTableView.parentVC = self
        }
    }
    
    let MapboxAccessToken = "pk.eyJ1Ijoid29vbGVlMTA2IiwiYSI6ImNqbzNjdWRwbTBxcjEzcHFuOWwxdGs5NXIifQ.ZDt6AmvMcsM3SeT5zy8GBg"
    var stopLoading: Bool! = false
    var firstUploadFlag: Bool! = true
    var cameraMoveFlag: Bool! = true
    var mapView: MGLMapView!
    var locationManager: CLLocationManager = CLLocationManager()
    var geocoder: Geocoder!
    var geocodingDataTask: URLSessionDataTask?
    var geocodingDataTask1: URLSessionDataTask?
    var assetList: [AssetModel]!
    var trackers: [AssetModel: TrackerModel]!
    var tempTrackers: [AssetModel:TrackerModel]!
    var trackPoints: [String:[CLLocationCoordinate2D]]!
    var selectedAssets: [AssetModel]!
    var carAnnotations: [MGLPointAnnotation]!
    var trackAnnnotations: [MGLPointAnnotation]!
    var polyLines: [MGLPolyline]!
    var mapStyle: Bool! = false
    var selectVelocityIndex: Int! = 0
    var userAnnotation: MGLPointAnnotation!
    var showUserLocationFlag: Bool! = true
    var normalAnnotations:[MGLPointAnnotation]!
    var parentVC: UIViewController?
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "MonitorViewController"
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    var carImage: UIImage! = UIImage(named: "locationcirclesmall")
    var pinImage: UIImage! = UIImage(named: "pin")
    var userImage: UIImage! = UIImage(named: "user_icon")
    var defaultZoom = 15.0
    var defaultPtZoom = 15.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initMapView()
        carAnnotations = [MGLPointAnnotation]()
        polyLines = [MGLPolyline]()
        normalAnnotations = [MGLPointAnnotation]()
        assetList = [AssetModel]()
        trackPoints = [String:[CLLocationCoordinate2D]]()
        tempTrackers = [AssetModel:TrackerModel]()
        loadAllDrivers()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        
        //self.scrollView.isScrollEnabled = false
        self.assetMultiSelectTableView.isScrollEnabled = false
        self.scrollView.panGestureRecognizer.delaysTouchesBegan = true
        self.scrollView.panGestureRecognizer.addTarget(self, action: #selector (self.panHandle (_:)))
        self.scrollView.delegate = self
       
        let gesture1 = UITapGestureRecognizer(target: self, action:  #selector (self.someAction1 (_:)))
        gesture1.cancelsTouchesInView = false
        self.assetMultiSelectTableView.addGestureRecognizer(gesture1)
        
        print("start")
    }
    

    @objc func panHandle(_ gestureRecognizer:UIPanGestureRecognizer) {
        let touchLocation = gestureRecognizer.location(in: self.zoom_Slider)
        if gestureRecognizer.state == UIGestureRecognizerState.began {
            if touchLocation.y >= 0 && touchLocation.x >= 0{
                self.scrollView.isScrollEnabled = false
            }
            else {
                self.scrollView.isScrollEnabled = true
            }
        }
    }
    
    @IBAction func showUserLocation(_ sender: UIButton) {
        showUserLocationFlag = !showUserLocationFlag
        if !showUserLocationFlag {
            if userAnnotation != nil {
                mapView.removeAnnotation(userAnnotation)
            }
        }
        else {
            locationManager.startUpdatingLocation()
        }
        showCarsOnMap()
    }
    
    @objc func someAction1(_ sender:UITapGestureRecognizer){
        self.scrollView.isScrollEnabled = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.mapView.frame.origin.y = scrollView.contentOffset.y
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopLoading = true
        
        print("============================")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("appear")
        if stopLoading {
            stopLoading = false
            print("restart")
            loadAllDrivers()
        }
    }
    
    @IBAction func zoomChanged(_ sender: Any) {
        mapView.zoomLevel = Double(zoom_Slider.value)
        self.scrollView.isScrollEnabled = true
    }
    
    func hideOptions() {
        if optionsView.isHidden == false {
            UIView.animate(withDuration: 0.2, animations: {
                self.optionsView.alpha = 0
            }) { (value) in
                self.optionsView.isHidden = true
            }
        }
        self.selectedAssets.removeAll()
        for asset in self.assetList {
            if asset.isSelected {
                self.selectedAssets.append(asset)
            }
        }
        showCarsOnMap()
    }
    
    func showOptions() {
        if self.optionsView.isHidden {
            self.optionsView.alpha = 0
            self.optionsView.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                self.optionsView.alpha = 1
            })
        }
    }
    	
    @IBAction func onReferAction(_ sender: Any) {
        guard let url = URL(string: "https://spectrumtracking.com/refer.html") else {return}
        UIApplication.shared.open(url)
    }
    @IBAction func onRateAction(_ sender: Any) {
        guard let url = URL(string: "https://www.amazon.com/review/review-your-purchases/?asin=B07BV4HBST") else {return}
        UIApplication.shared.open(url)
    }
    @IBAction func onFeedbackAction(_ sender: Any) {
        guard let url = URL(string: "https://spectrumtracking.com/feedback.html") else {return}
        UIApplication.shared.open(url)
    }
    @IBAction func changeMapStyle(_ sender: Any) {
        if(mapStyle)
        {
            mapView.styleURL = URL(string: "https://osm.spectrumtracking.com/styles/ciw6czz2n00242kmg6hw20box/style.json")
           // btn_style.setImage(UIImage(named: "mapstyle_satellite"),for:.normal)
        }
        else
        {
            mapView.styleURL = MGLStyle.satelliteStyleURL()
           // btn_style.setImage(UIImage(named: "mapstyle_street"),for:.normal)
        }
        mapStyle = !mapStyle
    }
    func initMapView() {
        self.mapView = MGLMapView(frame: mapViewFrameView.bounds)
        mapView.styleURL = URL(string: "https://osm.spectrumtracking.com/styles/ciw6czz2n00242kmg6hw20box/style.json")
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.maximumZoomLevel = 30
        mapView.attributionButton.isHidden = true
        mapView.contentInset = UIEdgeInsets(top:60,left:0,bottom:0,right:0)
        mapView.updateConstraints()
        mapView.zoomLevel = defaultZoom
        mapView.centerCoordinate = CLLocationCoordinate2D(latitude: 38.2534189, longitude: -85.7551944)
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleMapSingleTap(sender:)))
        let longTap = UILongPressGestureRecognizer (target: self, action: #selector(handleMapLongTap(sender:)))
        for recognizer in mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {
            singleTap.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(singleTap)
        mapView.addGestureRecognizer(longTap)
        self.mapViewFrameView.addSubview(mapView)
        mapView.delegate = self
        geocoder = Geocoder(accessToken: MapboxAccessToken)
    }
    @objc func handleMapSingleTap(sender: UITapGestureRecognizer) throws {
        print("single")
    }
    @objc func handleMapLongTap(sender: UITapGestureRecognizer) throws {
        let location = sender.location(in: self.mapView)
        print("click!!!")
        if self.normalAnnotations?.count != nil{
            if let existingAnnotations = self.normalAnnotations {
                mapView.removeAnnotations(existingAnnotations)
            }
            self.normalAnnotations.removeAll()
        }
        let annotationCoordinate = mapView.convert(location, toCoordinateFrom: mapView)
        let addressAnnotation = AddressAnnotation()
        addressAnnotation.coordinate = annotationCoordinate
        geocodingDataTask?.cancel()
        let options = ReverseGeocodeOptions(coordinate: annotationCoordinate)
        geocodingDataTask = geocoder.geocode(options) {(placemarks, attribution, error) in
            if let error = error {
                NSLog("%@", error)
            } else if let placemarks = placemarks, !placemarks.isEmpty {
                addressAnnotation.title  = placemarks[0].qualifiedName
            } else {
                addressAnnotation.title  = "No results"
            }
        }
        addressAnnotation.subtitle = "\(annotationCoordinate.latitude), \(annotationCoordinate.longitude)"
        normalAnnotations.append(addressAnnotation)
        mapView.addAnnotation(addressAnnotation)
    }
   
    
    @objc func loadAllDrivers() {
       
        if self.assetList == nil {
            self.assetList = [AssetModel]()
        }
        if self.trackers == nil {
            self.trackers = [AssetModel: TrackerModel]()
        }
        if self.selectedAssets == nil {
            self.selectedAssets = [AssetModel]()
        }
        self.selectedAssets.removeAll()
        
        self.view.endEditing(true)
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Internet Connection Error")
            
            let DELAY: Double! = 15.0
            DispatchQueue.main.asyncAfter(deadline: .now() + DELAY) {
                self.loadAllDrivers()
            }
            
            return
        }
        
        let reqInfo = URLManager.assets()
        
        let parameters: Parameters = [
            :
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                //self.view.makeToast("server connect error")
                self.indicator.alpha = 1
                self.loadAllDrivers()
                return
            }
            print(dataResponse)
            let code = dataResponse.response!.statusCode
           
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                
                let items = json["items"]
                
                var newAssetList = [AssetModel]()
                
                for i in 0..<items.count {
                    newAssetList.append(AssetModel.parseJSON(items[i]))
                }
                for newAsset in newAssetList {
                    newAsset.isSelected = false
                    if self.firstUploadFlag
                    {
                        newAssetList[0].isSelected = true
                        self.firstUploadFlag = false
                    }
                    for oldAsset in self.assetList {
                        if newAsset._id == oldAsset._id {
                            newAsset.isSelected = oldAsset.isSelected
                            break
                        }
                    }
                }
                self.assetList.removeAll()
                self.assetList.append(contentsOf: newAssetList)
                for asset in self.assetList {
                    if asset.isSelected {
                        self.selectedAssets.append(asset)
                    }
                }
                self.trackers.removeAll()
                
                self.loadTrackersFrom(0)
                
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
                self.indicator.alpha = 0
            }
        }
    }
    func requestAlarmData(trackerId : String)
    {
        let reqInfo = URLManager.alarm(trackerId)
        
        let parameters: Parameters = [
            :
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString {
            dataResponse in

            if(dataResponse.data == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            let code = dataResponse.response!.statusCode
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                let data : AlarmModel = AlarmModel.parseJSON(json)
                 Defaults[.alertSound] = data.soundAlarmStatus
                 Defaults[.vibration] = data.vibrationAlarmStatus
            } else {
                
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    func loadTrackersFrom(_ assetIdOnSelectedAssetList: Int) {
        if(assetIdOnSelectedAssetList >= selectedAssets.count) {
            onTrackersAllLoaded()
            return
        }
        let asset = selectedAssets[assetIdOnSelectedAssetList]
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Internet Connection Error")
            return
        }
        
        let reqInfo = URLManager.trackers_id(asset.trackerId)
        
        let parameters: Parameters = [
            :
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                //self.view.makeToast("server connect error")
                self.indicator.alpha = 1
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                let tracker = TrackerModel.parseJSON(json)
                self.checkTracker(asset: asset, tracker: tracker, assetIdOnSelectedAssetList: assetIdOnSelectedAssetList)
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
                self.loadTrackersFrom(assetIdOnSelectedAssetList + 1)
            }
            
        }
    }
    func checkTracker(asset:AssetModel,tracker:TrackerModel,assetIdOnSelectedAssetList:Int)  {
        
        var accOnChanged:Bool! = false , accOffChanged:Bool! = false
        
        if(!self.tempTrackers.keys.contains(asset) || self.tempTrackers[asset]?.lastACCOntime != tracker.lastACCOntime)
        {
            self.geocodingDataTask?.cancel()
            let options = ReverseGeocodeOptions(coordinate: CLLocationCoordinate2D(latitude: tracker.lastACCOnLat!, longitude: tracker.lastACCOnLng!))
            self.geocodingDataTask = self.geocoder.geocode(options) {(placemarks, attribution, error) in
                if let error = error {
                    NSLog("%@", error)
                } else if let placemarks = placemarks, !placemarks.isEmpty {
                    tracker.lastStartAddress  = placemarks[0].formattedName
                } else {
                    tracker.lastStartAddress  = "Unknown Address"
                }
            }
            accOnChanged = true
        }
        
        if(!self.tempTrackers.keys.contains(asset) || self.tempTrackers[asset]?.lastACCOfftime != tracker.lastACCOfftime)
        {
            self.geocodingDataTask1?.cancel()
            let options1 = ReverseGeocodeOptions(coordinate: CLLocationCoordinate2D(latitude: tracker.lastACCOffLat!, longitude: tracker.lastACCOffLng!))
            self.geocodingDataTask1 = self.geocoder.geocode(options1) {(placemarks, attribution, error) in
                if let error = error {
                    NSLog("%@", error)
                } else if let placemarks = placemarks, !placemarks.isEmpty {
                    tracker.lastStopAddress  = placemarks[0].formattedName
                } else {
                    tracker.lastStopAddress  = "Unknown Address"
                }
            }
            accOffChanged = true
        }
        
        if(!Global.shared.alertArray.keys.contains(asset.name) || Global.shared.alertArray[asset.name] != tracker.alert)
        {
            let alert = tracker.alert
            if alert != "no alert" && alert != ""{
                let alert_datetime_str = alert?.substring(from: (alert?.count)!-11, to: (alert?.count)!)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
                let alert_datetime = dateFormatter.date(from: "\(Date().year().toString())/\(alert_datetime_str!):00")
                print("\(Date().year().toString())/\(alert_datetime_str!)")

                if alert_datetime != nil && Date().date(plusDay: -1) < alert_datetime! {
                    requestAlarmData(trackerId: asset.trackerId!)
                    let appearance = SCLAlertView.SCLAppearance(showCircularIcon: true)
                    let alertView = SCLAlertView(appearance: appearance)
                    alertView.showInfo(asset.name!,subTitle: alert!,colorStyle:0xec9d20,animationStyle:.topToBottom)
                    
                    if Defaults[.alertSound] == nil || Defaults[.alertSound]! {
                        AudioServicesPlayAlertSound(1312)//1328
                    }
                    if Defaults[.vibration] == nil || Defaults[.vibration]! {
                        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                    }
                    Global.shared.alertArray[asset.name] = tracker.alert
                }
            }
        }
        
        let DELAY: Double! = 0.25
        DispatchQueue.main.asyncAfter(deadline: .now() + DELAY) {
            if(accOffChanged || accOnChanged) {
                self.trackers[asset] = tracker
                self.tempTrackers[asset] = tracker
            }
            else {
                self.trackers[asset] = self.tempTrackers[asset]
            }
            self.addTrackPoints(asset: asset, tracker: tracker)
            self.loadTrackersFrom(assetIdOnSelectedAssetList + 1)
        }
    }
    func addTrackPoints(asset:AssetModel,tracker:TrackerModel) {
        let maxLocationCount = 30
        if !asset.isSelected { return }
        if (!trackPoints.keys.contains(asset.trackerId)) {
            self.trackPoints[asset.trackerId] = [CLLocationCoordinate2D]()
        }
        var assetTrackPoints:[CLLocationCoordinate2D]! = self.trackPoints[asset.trackerId]
        let latitude = tracker.lat!
        let longitude = tracker.lng!
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        if(assetTrackPoints.count < maxLocationCount) {
            if(assetTrackPoints.count < 2) {
                assetTrackPoints.append(coordinate)
                self.trackPoints[asset.trackerId] = assetTrackPoints
                return
            }
            let prevCoordinate = assetTrackPoints[assetTrackPoints.count - 1]
            if(prevCoordinate.latitude == coordinate.latitude && prevCoordinate.longitude == coordinate.longitude) { return }
            assetTrackPoints.append(coordinate)
            self.trackPoints[asset.trackerId] = assetTrackPoints
        }
        else {
            let prevCoordinate = assetTrackPoints[assetTrackPoints.count - 1]
            if(prevCoordinate.latitude == coordinate.latitude && prevCoordinate.longitude == coordinate.longitude) { return }
            assetTrackPoints.remove(at: 0)
            assetTrackPoints.append(coordinate)
            self.trackPoints[asset.trackerId] = assetTrackPoints
        }
    }
    func showTrackPointsOnMap() {
        if trackAnnnotations == nil {
            trackAnnnotations = [MGLPointAnnotation]()
        }
        if self.trackAnnnotations?.count != nil{
            if let existingAnnotations = self.trackAnnnotations {
                mapView.removeAnnotations(existingAnnotations)
            }
            self.trackAnnnotations.removeAll()
        }
        for asset in self.assetList {
            if(trackPoints.keys.contains(asset.trackerId) && asset.isSelected) {
                let assetTrackPoints:[CLLocationCoordinate2D]! = self.trackPoints[asset.trackerId]
                if(assetTrackPoints != nil) {
                    for coordinate in assetTrackPoints {
                        let annotation = MGLPointAnnotation()
                        annotation.coordinate = coordinate
                        annotation.title = "track"
                        annotation.subtitle = ""
                        //mapView.addAnnotation(annotation)
                        self.trackAnnnotations.append(annotation)
                    }
                }
            }
        }
    }
    func onTrackersAllLoaded() {
        
        setRightPanelData()
        setVelocityData()
        showTrackPointsOnMap()
        showCarsOnMap()
        
        if stopLoading {
            return
        }
        
        let DELAY: Double! = 5.0
        DispatchQueue.main.asyncAfter(deadline: .now() + DELAY) {
            self.loadAllDrivers()
        }
    }
    
    func setVelocityData() {
        self.velocityTableView.setData(trackers)
        self.velocityTableView.reloadData()
        self.velocityTableHC.constant = self.velocityTableView.getHeight()
    }
    
    func setRightPanelData() {
        self.assetMultiSelectTableView.setData(assetList)
        self.assetMultiSelectTableView.reloadData()
        self.indicator.alpha = 0
        self.bottomTableHC.constant = self.assetMultiSelectTableView.getHeight()
        
        self.assetMultiSelectTableView.layer.borderColor = UIColor.gray.cgColor
        self.assetMultiSelectTableView.layer.borderWidth = 0.2
        self.assetMultiSelectTableView.layer.cornerRadius = 5.0
        self.assetMultiSelectTableView.layer.shadowColor = UIColor.black.cgColor
        self.assetMultiSelectTableView.layer.shadowOffset = CGSize(width:3.0,height:3.0)
        self.assetMultiSelectTableView.layer.shadowOpacity = 0.7
        self.assetMultiSelectTableView.layer.shadowRadius = 7.0
        self.assetMultiSelectTableView.layer.masksToBounds = false
        
        self.rateView.layer.borderColor = UIColor.white.cgColor
        self.rateView.layer.borderWidth = 0.2
        self.rateView.layer.cornerRadius = 5.0
        self.rateView.layer.shadowColor = UIColor.cyan.cgColor
        self.rateView.layer.shadowOffset = CGSize(width:3.0,height:3.0)
        self.rateView.layer.shadowOpacity = 0.7
        self.rateView.layer.shadowRadius = 7.0
        self.rateView.layer.masksToBounds = false
        
    }
    
    func showCarsOnMap() {
        
        var ifContainsAtLeastOnePoint = false
        for asset in selectedAssets {
            if(trackers.keys.contains(asset)) {
                let tracker = trackers[asset]
                let latitude = tracker!.lat!
                let longitude = tracker!.lng!
                
                if latitude == 0 && longitude == 0 {
                    continue
                }
                
                let bounds = mapView.visibleCoordinateBounds
                
                var rect = MKMapRectMake(bounds.sw.latitude, bounds.sw.longitude, bounds.ne.latitude - bounds.sw.latitude, bounds.ne.longitude - bounds.sw.longitude)
                
                if MKMapRectContainsPoint(rect, MKMapPointMake(latitude, longitude)) {
                    ifContainsAtLeastOnePoint  = true
                    break
                }
            }
        }
        
        if self.carAnnotations?.count != nil{
            if let existingAnnotations = self.carAnnotations {
                mapView.removeAnnotations(existingAnnotations)
            }
            self.carAnnotations.removeAll()
        }
        if self.polyLines?.count != nil{
            if let existingAnnotations = self.polyLines {
                mapView.removeAnnotations(existingAnnotations)
            }
            self.polyLines.removeAll()
        }
        
        var coordinates = [CLLocationCoordinate2D]()
        
        for asset in selectedAssets {
            if(trackers.keys.contains(asset)) {
                let tracker = trackers[asset]
                let latitude = tracker!.lat!
                let longitude = tracker!.lng!
                var points = [CLLocationCoordinate2D]()
                let annotation = MGLPointAnnotation()
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                points.append(coordinate)
                points.append(CLLocationCoordinate2D(latitude: tracker!.lat1!, longitude: tracker!.lng1!))
                points.append(CLLocationCoordinate2D(latitude: tracker!.lat2!, longitude: tracker!.lng2!))
                annotation.coordinate = coordinate
                annotation.title = "vehicle"
                annotation.subtitle = ""
                if tracker!.accStatus != 0 {
                let pointline = MGLPolyline(coordinates: points, count: UInt(points.count))
                    pointline.title = "pointLine"
                    mapView.addAnnotation(pointline)
                    self.polyLines.append(pointline)
                }
                self.scrollView.isScrollEnabled = true
                mapView.addAnnotation(annotation)
                self.carAnnotations.append(annotation)
               
                coordinates.append(coordinate)
                if showUserLocationFlag && userAnnotation != nil {
                    coordinates.append(userAnnotation.coordinate)
                }
            }
        }
        
        if(coordinates.count == 0)
        {
            return
        }
        
        mapView.camera = mapView.cameraThatFitsCoordinateBounds(MGLPolygon(coordinates: coordinates, count: UInt(coordinates.count)).overlayBounds, edgePadding: UIEdgeInsets(top: 140, left: 50, bottom: 70, right: 50))
        
        if(mapView.zoomLevel > Double(zoom_Slider.value))
        {
            mapView.zoomLevel = Double(zoom_Slider.value)
        }
        else {
            zoom_Slider.value = Float(mapView.zoomLevel)
        }
    }
    
    
    
    @IBAction func onBtnOptions(_ sender: Any) {
        if optionsView.isHidden {
            showOptions()
        } else {
            hideOptions()
        }
    }
   
    override func setResult(_ result: Any, from id: String) {
        if id == "AssetMultiSelectTableViewCell-selectedItem" {
            let row = (result as! (Int, Bool)).0
            let isSelected = (result as! (Int, Bool)).1
            
            if assetList.count <= row {
                return
            }
            self.assetList[row].isSelected = isSelected
            
            self.selectedAssets.removeAll()
            for asset in self.assetList {
                if asset.isSelected {
                    self.selectedAssets.append(asset)
                }
            }
            cameraMoveFlag = true
            showCarsOnMap()
            changeDisplayFlag = false
        }
        else if id == "AssetMultiSelectTableViewCell-replay" {
            let row = (result as! (Int, Bool)).0
            
            self.selectVelocityIndex = row
            let controller = ReplayViewController.getNewInstance()
            (controller as! ReplayViewController).selectedAsset = self.assetList[selectVelocityIndex]
            (controller as! ReplayViewController).display_mode = "oneVelocity"
            addChildViewController(controller)
            controller.willMove(toParentViewController: self)
            controller.view.frame = self.replayRouteView.bounds
            self.replayRouteView.addSubview(controller.view)
            controller.didMove(toParentViewController: self)
            self.replayRouteView.isHidden = false
            // self.performSegue(withIdentifier: "segReplay", sender: self)
        }
    }
    override func setTableViewHeight(_ value: CGFloat) {
        if(value > view.bounds.height * 0.9){
            self.mapViewFrameView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 0)
        }
        else{
            self.mapViewFrameView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: view.bounds.height * 0.9 - value)
        }
        self.assetMultiSelectTableView.frame = CGRect(x: 0, y: view.bounds.height * 0.9 - value, width: self.view.bounds.size.width, height: view.bounds.height * 0.1 + value)
    }
    func checkRoute() {
        let selectedAsset = self.assetList[selectVelocityIndex]
        let id = selectedAsset._id
        
        let startTime = Date().setTime()
        let endTime = startTime.date(plusDay: 1).setTime()
        
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
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.queryString, headers: headers)
        request.responseString { dataResponse in
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                self.loadAllDrivers()
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                //let items = json["items"]
                
                //if items.count != 0 {
                    self.performSegue(withIdentifier: "segReplay", sender: self)
                //}
                //else {
                    //var style = ToastStyle()
                    //style.backgroundColor = UIColor.white
                    //style.messageColor = UIColor.red
                    //self.view.makeToast("No data available.",position:.center,style:style)
                  //  self.view.makeToast("No data available.")
               // }
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
}

// MGLMapViewDelegate delegate
extension MonitorViewController: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        if let castAnnotation = annotation as? AddressAnnotation {
            if (!castAnnotation.displayFlag) {
                print("no")
                return nil
            }
        }
        var annotationImage:MGLAnnotationImage!
        if(annotation.title == "track") {
            annotationImage = MGLAnnotationImage(image: pinImage, reuseIdentifier: "pin")
        }
        else if annotation.title == "user" {
            annotationImage = MGLAnnotationImage(image: userImage.scaleImageToFitSize(size: CGSize(width:25,height:25)), reuseIdentifier: "user_icon")
        }
        else if annotation.title == "vehicle" {
            return nil
        }
        else {
            annotationImage = MGLAnnotationImage(image: carImage, reuseIdentifier: "car-image")
        }
        return annotationImage
    }
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        if annotation.title != "vehicle" {
            return nil
        }
        // Assign a reuse identifier to be used by both of the annotation views, taking advantage of their similarities.
        let reuseIdentifier = "reusableDotView"
        // For better performance, always try to reuse existing annotations.
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        // If there’s no reusable annotation view available, initialize a new one.
        if annotationView == nil {
            annotationView = MGLAnnotationView(reuseIdentifier: reuseIdentifier)
            annotationView?.frame = CGRect(x: 0, y: 0, width: 45, height: 45)
            annotationView?.layer.cornerRadius = (annotationView?.frame.size.width)! / 2
            annotationView?.layer.borderWidth = 4.0
            annotationView?.layer.borderColor = UIColor.white.cgColor
            let label = UILabel()
            for asset in selectedAssets {
                if(trackers.keys.contains(asset)) {
                    let tracker = trackers[asset]
                    let latitude = tracker!.lat!
                    let longitude = tracker!.lng!
                    if (annotation.coordinate.latitude == latitude && annotation.coordinate.longitude == longitude){
                        label.text = asset.driverName as String
                    }
                }
            }
            if (label.text?.count)! > 5 {
                label.text = label.text?.substring(from: 0, to: 5)
            }
            label.font = UIFont(name: "Symbol", size: 11.0)
            label.textAlignment = .center
            label.textColor = UIColor.white
            label.frame = CGRect(x: 3, y: 4, width: 40, height: 40)
            annotationView?.addSubview(label)
            annotationView!.backgroundColor = UIColor(hexInt: 0xffad70)
        }
        return annotationView
    }
    // Allow callout view to appear when an annotation is tapped.
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    func mapView(_ mapView: MGLMapView, calloutViewFor annotation: MGLAnnotation) -> MGLCalloutView? {
        print("callout")
        if let castAnnotation = annotation as? AddressAnnotation {
            if (!castAnnotation.displayFlag) {
                return nil
            }
        }
        let label_address = ""
        var label_drivername = ""
        var label_driverPhoneNumber = ""
        for asset in selectedAssets {
            if(trackers.keys.contains(asset)) {
                let tracker = trackers[asset]
                let latitude = tracker!.lat!
                let longitude = tracker!.lng!
                if (annotation.coordinate.latitude == latitude && annotation.coordinate.longitude == longitude){
                    label_drivername = asset.driverName as String
                    label_driverPhoneNumber = asset.driverPhoneNumber as String
                }
            }
        }
        let label_position = "\(annotation.coordinate.latitude), \(annotation.coordinate.longitude)"
        mapView.centerCoordinate = annotation.coordinate
        let customAnnotation = MyCustomAnnotation(coordinate: annotation.coordinate, title:  label_drivername ?? "no  driverName", subtitle: label_address ?? "no Address", description: label_position ?? "",
            phoneNumber: label_driverPhoneNumber ?? "")
        return MyCustomCalloutView(annotation: customAnnotation)
    }
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        return UIColor(hexInt: 0xF96F00)
    }
}
class MyCustomAnnotation: NSObject, MGLAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var position: String?
    var phoneNumber: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, description: String,phoneNumber: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.position = description
        self.phoneNumber = phoneNumber
    }
}
class MyCustomCalloutView: UIView, MGLCalloutView {
    var geocoder: Geocoder!
    var geocodingDataTask: URLSessionDataTask?
    func presentCallout(from rect: CGRect, in view: UIView, constrainedTo constrainedView: UIView, animated: Bool) {
        self.center = view.center.applying(CGAffineTransform(translationX: 0, y: -self.frame.height))
        view.addSubview(self)
    }
    var representedObject: MGLAnnotation
    let dismissesAutomatically: Bool = false
    let isAnchoredToAnnotation: Bool = true
    
    
    override var center: CGPoint {
        set {
            var newCenter = newValue
            newCenter.y = newCenter.y - bounds.midY
            super.center = newCenter
        }
        get {
            return super.center
        }
    }
    // Required views but unused for now, they can just relax
    lazy var leftAccessoryView = UIView()
    lazy var rightAccessoryView = UIView()
    
    weak var delegate: MGLCalloutViewDelegate?
    
    //MARK: Subviews -
    let titleLabel:UILabel = {
        let label = UILabel(frame: CGRect(x: 10, y: 10, width: 100, height: 20))
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = UIColor.black
        return label
    }()
    
    let subtitleLabel:UILabel = {
        let label = UILabel(frame: CGRect(x: 10, y: 50, width: UIScreen.main.bounds.width-60, height: 20))
        label.font = UIFont.systemFont(ofSize: 14.0)
        return label
    }()
    
    let positionLabel:UILabel = {
        let label = UILabel(frame: CGRect(x: 10, y: 70, width: UIScreen.main.bounds.width-60, height: 20))
        label.font = UIFont.systemFont(ofSize: 14.0)
        return label
    }()
    
    let phoneLabel:UILabel = {
        let label = UILabel(frame: CGRect(x: 10, y: 30, width: UIScreen.main.bounds.width-60, height: 20))
        label.font = UIFont.systemFont(ofSize: 14.0)
        return label
    }()
    
    required init(annotation: MyCustomAnnotation) {
        self.representedObject = annotation
        let MapboxAccessToken = "pk.eyJ1Ijoid29vbGVlMTA2IiwiYSI6ImNqbzNjdWRwbTBxcjEzcHFuOWwxdGs5NXIifQ.ZDt6AmvMcsM3SeT5zy8GBg"
        geocoder = Geocoder(accessToken: MapboxAccessToken)
        super.init(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: UIScreen.main.bounds.width * 0.75, height: 100.0)))
        self.titleLabel.text = self.representedObject.title ?? ""
        geocodingDataTask?.cancel()
        let options = ReverseGeocodeOptions(coordinate: annotation.coordinate)
        geocodingDataTask = geocoder.geocode(options) { [weak self] (placemarks, attribution, error) in
            
            if let error = error {
                print("%@", error)
            } else if let placemarks = placemarks, !placemarks.isEmpty {
                self!.subtitleLabel.text  = "\(placemarks[0].qualifiedName as! String)"
                self!.setup()
            }
        }
        self.positionLabel.text = annotation.position ?? ""
        self.phoneLabel.text = annotation.phoneNumber ?? ""
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        // setup this view's properties
        self.backgroundColor = UIColor.white
        self.frame = CGRect(origin: CGPoint(x: 20, y: UIScreen.main.bounds.height * 0.5 - 210), size: CGSize(width: UIScreen.main.bounds.width-40, height: 100.0))
        // And their Subviews
        self.addSubview(titleLabel)
        self.addSubview(subtitleLabel)
        self.addSubview(positionLabel)
        self.addSubview(phoneLabel)
        
    }
    
    
    func presentCallout(from rect: CGRect, in view: UIView, constrainedTo constrainedRect: CGRect, animated: Bool) {
        //Always, Slightly above center
        self.center = view.center.applying(CGAffineTransform(translationX: 0, y: -self.frame.height))
        view.addSubview(self)
    }
    
    func dismissCallout(animated: Bool) {
        if (superview != nil) {
            if animated {
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    self?.alpha = 0
                    }, completion: { [weak self] _ in
                        self?.removeFromSuperview()
                })
            } else {
                removeFromSuperview()
            }
        }
    }
}
extension MonitorViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locationCoordinate = locations.last?.coordinate else { return }
        locationManager.stopUpdatingLocation()
        userAnnotation = MGLPointAnnotation()
        userAnnotation.coordinate = locationCoordinate
        userAnnotation.title = "user"
        mapView.addAnnotation(userAnnotation)
    }
}
