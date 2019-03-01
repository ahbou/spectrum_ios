//
//  SetAlarmViewController.swift
//  spectrum_tracker
//
//  Created by Robin on 2018/09/28.
//  Copyright © 2018 Robin. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Toast_Swift
import Mapbox
import SwiftyUserDefaults
import MapKit

class SetAlarmViewController: ViewControllerWaitingResult,UIScrollViewDelegate {

    @IBOutlet var indicator: UIActivityIndicatorView!
    
    @IBOutlet var s_speedingAlarmStatus: UISwitch!
    @IBOutlet var s_fatigueAlarmStatus: UISwitch!
    @IBOutlet var s_harshTurnAlarmStatus: UISwitch!
    @IBOutlet var s_harshAcceAlarmStatus: UISwitch!
    @IBOutlet var s_harshDeceAlarmStatus: UISwitch!
    @IBOutlet var s_tamperAlarmStatus: UISwitch!
    @IBOutlet var s_geoFenceAlarmStatus: UISwitch!
    @IBOutlet var s_emailAlarmStatus: UISwitch!
    @IBOutlet var s_phoneAlarmStatus: UISwitch!
    @IBOutlet var s_engineOnAlarmStatus: UISwitch!
    @IBOutlet var s_alertSoundAlarmStatus: UISwitch!
    @IBOutlet var s_engineOffAlarmStatus: UISwitch!
    @IBOutlet var s_vibrationAlarmStatus: UISwitch!
    
    @IBOutlet var topView: UIScrollView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var tableViewHC: NSLayoutConstraint!
    @IBOutlet var txt_userTracker_speedLimit: UITextField!
    @IBOutlet var txt_userTracker_fatigueTime: UITextField!
    @IBOutlet var txt_userTracker_email: UITextField!
    @IBOutlet var txt_userTracker_phoneNumber: UITextField!
    
    
    @IBOutlet var assetSingleSelectTableView: AssetSingleSelectTableView! {
        didSet {
            assetSingleSelectTableView.parentVC = self
        }
    }
    
    var stopLoading: Bool! = false
    
    var mapView: MGLMapView!
    
    var assetList: [AssetModel]!
    var selectedAsset: AssetModel? = nil
    
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "SetAlarmViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.panGestureRecognizer.delaysTouchesBegan = true
        self.scrollView.delegate = self
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.topView.frame.origin.y = scrollView.contentOffset.y
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopLoading = true
        
        print("============================")
    }

    override func viewWillAppear(_ animated: Bool) {
        initialize_comps()
        loadAllDrivers()
        setSwitchHeight()
        setRightPanelData()
        self.indicator.alpha = 0
        //commented by Robin hideOptions()
    }
    
    func setSwitchHeight() {
        let scaleY = 0.6
        let scaleX = 0.6
        s_speedingAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_fatigueAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_harshTurnAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_harshAcceAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_harshDeceAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_tamperAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_geoFenceAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_emailAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_phoneAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_engineOnAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_engineOffAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_alertSoundAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_vibrationAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
    }
    
    @IBAction func OnSetAlarmButtonClick(_ sender: Any) {
        if selectedAsset == nil {
            self.view.makeToast("Please choose vehicle")
            return
        }
        
        if ( s_emailAlarmStatus.isOn == true) && (txt_userTracker_email.text?.contains("@") == false){
            self.view.makeToast("Use valid email address.")
            return
        }
        
        if ( s_phoneAlarmStatus.isOn == true) && (txt_userTracker_phoneNumber.text?.count != 10){
            self.view.makeToast("The 10 digits phone number only. For example, use 3525021234. Not 352-50201234 nor 5021234.")
            return
        }
        
        // send alarm setting
        let reqInfo = URLManager.modify()
        let parameters: Parameters = [
            "id" : selectedAsset!.trackerId as String,
            "speedLimit" : txt_userTracker_speedLimit.text!,
            "fatigueTime" : txt_userTracker_fatigueTime.text!,
            "harshTurn": "120",
            "harshAcceleration" : "1",
            "harshDeceleration" : "1",
            "email" : txt_userTracker_email.text!,
            "phoneNumber" : txt_userTracker_phoneNumber.text!,
            "speedingAlarmStatus" : s_speedingAlarmStatus.isOn,
            "fatigueAlarmStatus": s_fatigueAlarmStatus.isOn,
            "harshTurnAlarmStatus": s_harshTurnAlarmStatus.isOn,
            "harshAcceAlarmStatus": s_harshAcceAlarmStatus.isOn,
            "harshDeceAlarmStatus": s_harshDeceAlarmStatus.isOn,
            "geoFenceAlarmStatus": s_geoFenceAlarmStatus.isOn,
            "tamperAlarmStatus": s_tamperAlarmStatus.isOn,
            "emailAlarmStatus": s_emailAlarmStatus.isOn,
            "phoneAlarmStatus": s_phoneAlarmStatus.isOn,
            "accAlarmStatus": s_engineOnAlarmStatus.isOn,
            "stopAlarmStatus": s_engineOffAlarmStatus.isOn,
            "soundAlarmStatus": s_alertSoundAlarmStatus.isOn,
            "vibrationAlarmStatus": s_vibrationAlarmStatus.isOn
        ]
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        //showIndicator()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString {
            dataResponse in
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                self.view.makeToast("Success")
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    
    func showIndicator() {
//        if self.indicator.alpha == 1 {
//            return
//        }
//        UIView.animate(withDuration: 0.2) {
//            self.indicator.alpha = 1
//        }
    }
    
    func hideIndicator() {
//        if self.indicator.alpha == 0 {
//            return
//        }
//        UIView.animate(withDuration: 0.2) {
//            self.indicator.alpha = 0
//        }
    }
    
    @objc func loadAllDrivers() {
       
        if assetList == nil {
            assetList = [AssetModel]()
        }
        self.view.endEditing(true)
        
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Internet Connection Error")
            
            let DELAY: Double! = 15.0
            DispatchQueue.main.asyncAfter(deadline: .now() + DELAY) {
                self.loadAllDrivers()
            }
            
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
        
        showIndicator()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            self.hideIndicator()
            
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
                self.tableViewHC.constant = self.assetSingleSelectTableView.getHeight()
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
    
    func setRightPanelData() {
        self.assetSingleSelectTableView.setData(assetList)
        self.assetSingleSelectTableView.reloadData()
    }

    override func setResult(_ result: Any, from id: String) {
        
        if id == "AssetSingleSelectTableViewCell-selectedItem" {
            self.selectedAsset = result as! AssetModel
            
            requestAlarmData()
        }
        
    }

    func requestAlarmData()
    {
        if selectedAsset == nil{
            return
        }

        initialize_comps()

        let trackerId : String = self.selectedAsset!.trackerId
        let reqInfo = URLManager.alarm(trackerId)

        let parameters: Parameters = [
            :
        ]

        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]

        showIndicator()

        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)

        request.responseString {
            dataResponse in

            self.hideIndicator()
            print(dataResponse)

            if(dataResponse.data == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }

            let code = dataResponse.response!.statusCode
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                let data : AlarmModel = AlarmModel.parseJSON(json)
                self.loadAlarmValues(values: data)
                
            } else {
               
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    
    func loadAlarmValues(values : AlarmModel)
    {
        txt_userTracker_speedLimit.text = values.speedLimit
        txt_userTracker_fatigueTime.text = values.fatigueTime
       // txt_userTrarcker_harshTurn.text = values.harshTurn
       // txt_userTracker_harshAcceleration.text = values.harshAcceleration
       // txt_userTracker_harshDeceleration.text = values.harshDeceleration
        txt_userTracker_email.text = values.email
        txt_userTracker_phoneNumber.text = values.phoneNumber
        
        s_speedingAlarmStatus.isOn = values.speedingAlarmStatus
        s_fatigueAlarmStatus.isOn = values.fatigueAlarmStatus
        s_harshTurnAlarmStatus.isOn = values.harshTurnAlarmStatus
        s_harshAcceAlarmStatus.isOn = values.harshAcceAlarmStatus
        s_harshDeceAlarmStatus.isOn = values.harshDeceAlarmStatus
        s_tamperAlarmStatus.isOn = values.tamperAlarmStatus
        s_geoFenceAlarmStatus.isOn = values.geoFenceAlarmStatus
        s_emailAlarmStatus.isOn = values.emailAlarmStatus
        s_phoneAlarmStatus.isOn = values.phoneAlarmStatus
        s_engineOnAlarmStatus.isOn = values.engineAlarmStatus
        s_engineOffAlarmStatus.isOn = values.stopAlarmStatus
        s_alertSoundAlarmStatus.isOn = values.soundAlarmStatus
        s_vibrationAlarmStatus.isOn = values.vibrationAlarmStatus
    }
    
    func initialize_comps() {
        txt_userTracker_speedLimit.text = ("")
        txt_userTracker_fatigueTime.text = ("")
       // txt_userTrarcker_harshTurn.text = ("")
       // txt_userTracker_harshAcceleration.text = ("")
       // txt_userTracker_harshDeceleration.text = ("")
        txt_userTracker_email.text = ("")
        txt_userTracker_phoneNumber.text = ("")
    
        s_speedingAlarmStatus.isOn = false
        s_fatigueAlarmStatus.isOn = (false)
        s_harshTurnAlarmStatus.isOn = (false)
        s_harshAcceAlarmStatus.isOn = (false)
        s_harshDeceAlarmStatus.isOn = (false)
        s_tamperAlarmStatus.isOn = (false)
        s_geoFenceAlarmStatus.isOn = (false)
        s_engineOffAlarmStatus.isOn = (false)
        s_emailAlarmStatus.isOn = (false)
        s_phoneAlarmStatus.isOn = (false)
        s_engineOnAlarmStatus.isOn = (false)
        s_vibrationAlarmStatus.isOn = (false)
        s_alertSoundAlarmStatus.isOn = (false)
        
    }
    @IBAction func actionAlertSound(_ sender: UISwitch) {
        //Defaults[.alertSound] = sender.isOn
    }
    @IBAction func actionVibration(_ sender: UISwitch) {
        //Defaults[.vibration] = sender.isOn
    }
    
}

