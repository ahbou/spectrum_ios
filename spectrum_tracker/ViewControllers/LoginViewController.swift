//
//  LoginViewController.swift
//  spectrum_tracker
//
//  Created by JO on 2018/5/7.
//  Copyright © 2018 JO. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Toast_Swift
import SwiftyUserDefaults
import GoogleSignIn
import Google
import FacebookLogin
import FBSDKLoginKit
class LoginViewController: UIViewController,GIDSignInDelegate,GIDSignInUIDelegate,FBSDKLoginButtonDelegate{
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil {
            print(error)
            
        }
        else if result.isCancelled {
            print("Cancelled")
        }
        else {
            self.goToMain()
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        return
    }
    
    
    
    @IBOutlet var FacebookSignInButton: FBSDKLoginButton!
   
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error != nil{
            print(error ?? "google error")
            return
        }
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Internet Connection Error")
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.authLoginGoogle()
        
        let parameters: Parameters = [
            "email" : user.profile.email,
            "userid": user.userID,
            "firstName": user.profile.givenName,
            "lastName": user.profile.familyName
        ]
        
        let headers: HTTPHeaders = [
            :
        ]
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            print(dataResponse)
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                
                self.goToMain()
                
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }
    }
    
    
    @IBOutlet var txtUsername: UITextField!
    @IBOutlet var txtPassword: UITextField!
    @IBOutlet var txtEmail: UITextField!
    @IBOutlet var labelCopyright: UILabel!
    @IBOutlet var indicator: UIActivityIndicatorView!
    
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "LoginViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    @IBAction func onGoogleSignIn(_ sender: Any) {
        GIDSignIn.sharedInstance()?.signIn()
    }
    @IBOutlet var forgotPasswordDlg: UIView!
    
    override func viewWillAppear(_ animated: Bool) {
        forgotPasswordDlg.isHidden = true
        forgotPasswordDlg.alpha = 0
        labelCopyright.text = "Copyright @ " + Date().year().toString() + " Spectrum Tracking | All rights reserved"
        let isLoggedIn = Defaults[.isLoggedIn] ?? false
        if(!isLoggedIn) {
            let username = ""
            let password = ""
            self.txtUsername.text = username
            self.txtPassword.text = password
            Defaults[.username] = ""
            Defaults[.password] = ""
        }
        else {
            let username = Defaults[.username]
            let password = Defaults[.password]
            self.txtUsername.text = username
            self.txtPassword.text = password
            login_func()
        }
        GIDSignIn.sharedInstance()?.signOut()
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let isLoggedIn = Defaults[.isLoggedIn] ?? false
        if(isLoggedIn) {
            let username = Defaults[.username]
            let password = Defaults[.password]
            self.txtUsername.text = username
            self.txtPassword.text = password
            login_func()
        }
        GIDSignIn.sharedInstance()?.clientID = "215524246357-85akj7anrcs3l3ulhh874kdrd4du5ajf.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        FacebookSignInButton.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onForgotPassword(_ sender: Any) {
        
        
        self.view.endEditing(true)
        
        self.forgotPasswordDlg.alpha = 0
        self.forgotPasswordDlg.isHidden = false
        UIView.animate(withDuration: 0.2, animations: {
            self.forgotPasswordDlg.alpha = 1

        })

    }
    
    func cancelForgotPasswordDlg() {
        UIView.animate(withDuration: 0.2, animations: {
            self.forgotPasswordDlg.alpha = 0
            
        }) { (value) in
            self.forgotPasswordDlg.isHidden = true
            self.view.endEditing(true)
        }
    }
    
    @IBAction func onForgotPasswordBk(_ sender: Any) {
        
        cancelForgotPasswordDlg()
        
    }
    
    @IBAction func onCancelForgotPassword(_ sender: Any) {
        
        cancelForgotPasswordDlg()

    }
    @IBAction func unwindLoginViewSegue(_ sender:UIStoryboardSegue)
    {
        
    }
    
    @IBAction func onRegister(_ sender: Any) {
        self.present(RegisterViewController.getNewInstance(), animated: true, completion: nil)
    }
    func login_func()
    {
        var username = txtUsername.text ?? ""
        if(username == "") {
            self.view.makeToast("please enter username")
            return
        }
        if(username[username.startIndex]==" "){
            username.removeFirst()
        }
        if(username.last==" "){
            username.removeLast()
        }
        //txtUsername.text = username
        
        let password = txtPassword.text ?? ""
        if(password == "") {
            self.view.makeToast("please enter password")
            return
        }
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Internet Connection Error")
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.authLogin()
        
        let parameters: Parameters = [
            "email": username,
            "password": password
        ]
        
        let headers: HTTPHeaders = [
            :
        ]
        
        indicator.isHidden = false
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
    
            print(dataResponse)
            self.indicator.isHidden = true
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                
                Defaults[.isLoggedIn] = true
                Defaults[.username] = username
                Defaults[.password] = password
                
                let csrfToken: String = dataResponse.response!.allHeaderFields["x-csrftoken"] as? String ?? ""
                Global.shared.csrfToken = csrfToken
                
                Global.shared.username = username
                
                UIApplication.shared.beginIgnoringInteractionEvents()
                //self.view.makeToast("login success") { didTap in
                UIApplication.shared.endIgnoringInteractionEvents()
                
                self.goToMain()
                //}
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }
    }
    @IBAction func onLogin(_ sender: Any) {
        self.view.endEditing(true)
        login_func()
    }
    
    @IBAction func onRequestPassword(_ sender: Any) {
        self.view.endEditing(true)
        let email = (txtEmail.text ?? "").lowercased()
        if(email == "") {
            self.view.makeToast("plase enter email")
            return
        }
        
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Internet Connection Error")
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.authResendPasswordReset()
        
        let parameters: Parameters = [
            "email": email
        ]
        
        let headers: HTTPHeaders = [
            :
        ]
        
        indicator.isHidden = false
        
        
        Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers).responseString { dataResponse in
            
            self.indicator.isHidden = true
            
            print(dataResponse)
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                self.view.makeToast("email sent") { didTap in
                }
                self.cancelForgotPasswordDlg()
                let forgetViewController = ForgetViewController.getNewInstance() as! ForgetViewController
                forgetViewController.email = email
                self.present(forgetViewController, animated: true, completion: nil)
                
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }
    }
    
    func goToMain() {
        //self.present(WeatherViewController.getNewInstance(), animated: true, completion: nil)
        //let mainSlideMenuController = MainSlideMenuController.getNewInstance()
        //VCManager.shared.mainSlideMenuC = mainSlideMenuController
        self.present(MainContainerViewController.getNewInstance(), animated: true, completion: nil)
        //self.present(VCManager.shared.mainSlideMenuC, animated: true, completion: nil)
       // VCManager.shared.mainSlideMenuC.view.makeToast("login success")
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
