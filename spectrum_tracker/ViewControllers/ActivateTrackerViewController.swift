//
//  ActivateTrackerViewController.swift
//  spectrum_tracker
//
//  Created by JO on 2018/5/7.
//  Copyright © 2018 JO. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Toast_Swift
import ActiveLabel
import DropDown
import SCLAlertView

class ActivateTrackerViewController: UIViewController {

    @IBOutlet var txtTrackerId: UITextField!
    @IBOutlet var txtPlateNumber: UITextField!
    @IBOutlet var txtDriverName: UITextField!
    @IBOutlet var topStackView: UIStackView!
    @IBOutlet var labelView: ActiveLabel!
    @IBOutlet var txtTrackerCountry: UILabel!
    @IBOutlet var txtCVCode: UITextField!
    @IBOutlet var txtCardExpiry: UITextField!
    @IBOutlet var txtCardNumber: UITextField!
    @IBOutlet var txtCardName: UITextField!
    @IBOutlet var btnTCountry: UIButton!
    @IBAction func onTrackerCountry(_ sender: Any) {
        if countryDropDown.isHidden {
            countryDropDown.show()
        }
        else {
            countryDropDown.hide()
        }
    }
    var countryDropDown: DropDown!
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "ActivateTrackerViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    override func viewWillAppear(_ animated: Bool) {

        let customType1 = ActiveType.custom(pattern: "\\sSPECTRUMID\\b")
        let customType2 = ActiveType.custom(pattern: "\\sHERE\\b")
        labelView.enabledTypes.append(customType1)
        labelView.enabledTypes.append(customType2)
        labelView.customize { (labelView) in
            labelView.font = labelView.font.withSize(11.0)
            labelView.text = "1:Put the SPECTRUMID on your device into the box below.\n\n" +
                "2:Plug the tracker into the OBD II port. Click HERE to locate OBD port.\n\n" +
                "3:You will not be charged when you cancel service 24 hours before the end of 7 day free trial.\n\n" +
                "Your vehicle should show on the map within 5~10 minutes. If you do not see it on the map, unplug the tracker, wait a few minutes and plug it back to reset.\n\n"
            labelView.numberOfLines = 15
            labelView.customColor[customType1] = UIColor(hexInt: 0xf96f00)
            labelView.customColor[customType2] = UIColor(hexInt: 0xf96f00)
            labelView.handleCustomTap(for: customType2) { (element) in
                print(element)
                guard let url = URL(string: "https://www.carmd.com/wp/locating-the-obd2-port-or-dlc-locator/") else {return}
                UIApplication.shared.open(url)
            }
        }
        
//        countryDropDown = DropDown()
//        countryDropDown.dataSource = [String]()
//        countryDropDown.dataSource.append("USA")
//        countryDropDown.dataSource.append("Canada or Mexico")
//        countryDropDown.dataSource.append("Other Countries")
//        countryDropDown.anchorView = btnTCountry
//        countryDropDown.backgroundColor = UIColor.groupTableViewBackground
//        countryDropDown.bottomOffset = CGPoint(x: 0, y:(countryDropDown.anchorView?.plainView.bounds.height)!)
//        countryDropDown.direction = .bottom
//        countryDropDown.selectionAction = { (index: Int, title: String) in
//            self.txtTrackerCountry.text = title
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    
    
    @IBAction func onActivate(_ sender: Any) {
        //self.dismiss(animated: true, completion: nil)
        var trackerId:String = txtTrackerId.text ?? ""
        let driverName = txtDriverName.text ?? "driver"
        let card_holder_name = txtCardName.text ?? ""
        var cardNumber = txtCardNumber.text ?? ""
        let cardExpiry = txtCardExpiry.text ?? ""
        var cardCVV = txtCVCode.text ?? ""
        
        if cardExpiry.count != 4 {
            self.view.makeToast("expiration date format is wrong. Use mmyy. For example, if expiration date is December 2030, use 1230")
            return
        }
        
        if trackerId  == "" {
            self.view.makeToast("please enter tracker ID")
            return
        }
       
        let regex = try! NSRegularExpression(pattern: "/(^\\s+|\\s+$)/", options: .caseInsensitive)
        let range = NSMakeRange(0, trackerId.count)
        trackerId = regex.stringByReplacingMatches(in: trackerId, options: [], range: range, withTemplate: "").uppercased()
        trackerId = trackerId.replacingOccurrences(of: " ", with: "")
        
        let regexCard = try! NSRegularExpression(pattern: "/\\s+/g", options: .caseInsensitive)
        let rangeNumber = NSMakeRange(0, cardNumber.count)
        let rangeCVV = NSMakeRange(0, cardCVV.count)
        cardNumber = regexCard.stringByReplacingMatches(in: cardNumber, options: [], range: rangeNumber, withTemplate: "").replacingOccurrences(of: " ", with: "")
        cardCVV = regexCard.stringByReplacingMatches(in: cardCVV, options: [], range: rangeCVV, withTemplate: "").replacingOccurrences(of: " ", with: "")
        
        let plateNumber = txtPlateNumber.text ?? trackerId
        
        let activateTrackerFormItem = ActivateTrackerFormModel(trackerId, plateNumber, driverName, card_holder_name, cardNumber, cardExpiry, cardCVV)
        
        self.view.endEditing(true)
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Internet Connection Error")
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.doAuth()
        let parameters: Parameters = [
            :
        ]
        
        let headers: HTTPHeaders = [
            :
//         "X-CSRFToken": Global.shared.csrfToken
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
                let userId = json["userId"].stringValue
                let email = json["email"].stringValue
                //self.registerTracker(userId,email, trackerId, activateTrackerFormItem)
                self.generateToken(userId, email, activateTrackerFormItem)
            } else {
                self.view.makeToast("failed to auth")
            }
        }
    }
    func generateToken(_ userId: String, _ email: String, _ activateTrackerFormItem: ActivateTrackerFormModel) {
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Internet Connection Error")
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.generateToken()
        
        let parameters: Parameters = [
            "auth" : userId,
            "card_cvv" : activateTrackerFormItem.cvCode,
            "card_expiry" : activateTrackerFormItem.cardExpiry,
            "card_number" : activateTrackerFormItem.cardNumber,
            "card_holder_name" : activateTrackerFormItem.cardName
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
                if json["error"] == JSON.null || json["error"] == ""{
                    self.registerTracker(userId,email,activateTrackerFormItem)
                }
                else {
                    self.view.makeToast(json["error"].stringValue)
                }
            } else {
                self.view.makeToast("Credit card information wrong")
            }
            
        }

    }
    
    func registerTracker(_ userId: String, _ email: String, _ activateTrackerFormItem: ActivateTrackerFormModel) {
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Internet Connection Error")
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.trackerRegister()
        
        let parameters: Parameters = [
            "spectrumId": activateTrackerFormItem.spectrumId,
            "userId": userId,
            "email": email
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            self.hideLoader()
            
            print("register\(dataResponse)")
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                let _trackerId = json["_id"].stringValue
                self.modify(userId, _trackerId, activateTrackerFormItem)
                //self.doFinalRegisterTrackerWork(userId, _trackerId, activateTrackerFormItem)
            } else {
                self.view.makeToast("failed to register tracker")
            }
            
        }
    }
    func modify(_ userId: String, _ trackerId: String, _ activateTrackerFormItem: ActivateTrackerFormModel) {
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Internet Connection Error")
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.modify()
        
        let parameters: Parameters = [
            "id": trackerId,
            "driverName": activateTrackerFormItem.driverName,
            "operation": "createNew",
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            self.hideLoader()
            
           print("modify\(dataResponse)")
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            //let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                self.doFinalRegisterTrackerWork(userId, trackerId, activateTrackerFormItem)
            } else {
                self.view.makeToast("Update failed!!!")
            }
            
        }
    }
    func doFinalRegisterTrackerWork(_ userId: String, _ trackerId: String, _ activateTrackerFormItem: ActivateTrackerFormModel) {
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Internet Connection Error")
            return
            // do some tasks..
        }
        
        
        let reqInfo = URLManager.createAssets()
        let spectrumId : String = activateTrackerFormItem.spectrumId
        let parameters: Parameters = [
            "name": activateTrackerFormItem.plateNumber ?? spectrumId,
            "trackerId": trackerId,
            "spectrumId": activateTrackerFormItem.spectrumId,
            "userId": userId,
            "driverName": activateTrackerFormItem.driverName ?? "driver",
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            self.hideLoader()
            
            print("final\(dataResponse)")
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            if(code == 201) {
                let appearance = SCLAlertView.SCLAppearance(showCloseButton: false, showCircularIcon: true)
                let alertView = SCLAlertView(appearance: appearance)
                alertView.addButton("Done", action: {
                    self.dismiss(animated: true, completion: nil)
                })
                alertView.showSuccess("Congratulations",subTitle: "Your tracker is now activated. Please wait for 5 minutes for the tracker to start. If it does not show on the map, unplug the tracker form the OBD port and then plug it back go reset the device. Contact contact@spectrumtracking.com for assistance.",animationStyle:.topToBottom)
            } else {
                self.view.makeToast("asset creation failed")
            }
            
        }
    }
}
