//
//  AppDelegate.swift
//  spectrum_tracker
//
//  Created by JO on 2018/5/7.
//  Copyright © 2018 JO. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import Google
import GoogleSignIn
import FacebookCore
import FacebookLogin

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
       // self.configureUserInteractions()
        UIApplication.shared.registerForRemoteNotifications()
        IQKeyboardManager.sharedManager().enable = true
        SDKApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let scheme = url.scheme else {
            return false
        }
        if scheme.hasPrefix("fb\(SDKSettings.appId)") {
            return SDKApplicationDelegate.shared.application(app, open: url,options: options)
        }
        else if scheme.hasPrefix("com.googleusercontent.apps.215524246357-85akj7anrcs3l3ulhh874kdrd4du5ajf") {
            return GIDSignIn.sharedInstance().handle(url as URL!,
                sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        }
        return false
    }
    
    func application(_ app: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return SDKApplicationDelegate.shared.application(app,open:url as URL,sourceApplication:sourceApplication,annotation: annotation)
    }
    
    func application(_ application: UIApplication, didFailToRegisterRemoteNotificationsWithError error: Error) {
        //self.disableRemoteNotificationFeatures()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
       // self.enableRemoteNotificationFeatures()
       // self.forwardTokenToServer(token: deviceToken)
    }
}

