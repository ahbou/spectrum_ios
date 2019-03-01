//
//  MainContainerViewController.swift
//  spectrum_tracker
//
//  Created by Admin on 2/20/19.
//  Copyright © 2019 JO. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class MainContainerViewController: ViewControllerWaitingResult {
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "MainContainerViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    @IBOutlet var lineView: UIView!
    @IBOutlet var mainContainerView: UIView!
    @IBOutlet var backView: UIView!
    @IBOutlet var menuView: UIView!
    @IBOutlet var icon_monitor: UIImageView!
    @IBOutlet var icon_reports: UIImageView!
    @IBOutlet var icon_alarm: UIImageView!
    @IBOutlet var icon_order_service: UIImageView!
    @IBOutlet var icon_geofence: UIImageView!
    @IBOutlet var icon_driver_info: UIImageView!
    @IBOutlet var icon_activate: UIImageView!
    @IBOutlet var icon_order_tracker: UIImageView!
    @IBOutlet var icon_replay: UIImageView!
    @IBOutlet var icon_setAlarms: UIImageView!
    
    @IBAction func onLogout(_ sender: Any) {
        Defaults[.isLoggedIn] = false
        Global.shared.csrfToken = ""
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onOrderTracker(_ sender: Any) {
        let controller = OrderTrackerViewController.getNewInstance()
        setPage(controller: controller)
        icon_order_tracker.tintColor = selectedColor
        hideMenuView(self)
    }
    
    @IBAction func onActicate(_ sender: Any) {
        let controller = ActivateTrackerViewController.getNewInstance()
        setPage(controller: controller)
        icon_activate.tintColor = selectedColor
        hideMenuView(self)
    }
    
    @IBAction func onDriverInfo(_ sender: Any) {
        let controller = UpdateDriverInfoViewController.getNewInstance()
        setPage(controller: controller)
        icon_driver_info.tintColor = selectedColor
        hideMenuView(self)
    }
    
    @IBAction func onGeofence(_ sender: Any) {
        let controller = GeofenceViewController.getNewInstance()
        setPage(controller: controller)
        icon_geofence.tintColor = selectedColor
        hideMenuView(self)
    }
    
    @IBAction func onService(_ sender: Any) {
        let controller = OrderServiceViewController.getNewInstance()
        setPage(controller: controller)
        icon_order_service.tintColor = selectedColor
        hideMenuView(self)
    }
    
    @IBAction func onAlarms(_ sender: Any) {
        let controller = AlarmsViewController.getNewInstance()
        setPage(controller: controller)
        icon_alarm.tintColor = selectedColor
    }
    
    @IBAction func onReports(_ sender: Any) {
        let controller = ReportsViewController.getNewInstance()
        setPage(controller: controller)
        icon_reports.tintColor = selectedColor
    }
    
    @IBAction func onSetAlarms(_ sender: Any) {
        let controller = SetAlarmViewController.getNewInstance()
        setPage(controller: controller)
        icon_setAlarms.tintColor = selectedColor
        hideMenuView(self)
    }
    
    @IBAction func onMonitor(_ sender: Any) {
        let controller = MonitorViewController.getNewInstance()
        setPage(controller: controller)
        icon_monitor.tintColor = selectedColor
    }
    
    @IBAction func onReplay(_ sender: Any) {
        let controller = ReplayViewController.getNewInstance()
        setPage(controller: controller)
        icon_replay.tintColor = selectedColor
    }
    
    @IBAction func showMenuView(_ sender: Any) {
        self.backView.isHidden = false
        self.menuView.isHidden = false
    }
    
    @IBAction func hideMenuView(_ sender: Any) {
        self.backView.isHidden = true
        self.menuView.isHidden = true
    }
    
    let normalColor: UIColor = UIColor(hexString: "#777777")
    let selectedColor: UIColor = UIColor(hexString: "#d185f5")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        icon_monitor.image = icon_monitor.image?.withRenderingMode(.alwaysTemplate)
        icon_monitor.tintColor = selectedColor
        
        self.lineView.layer.shadowColor = selectedColor.cgColor
        self.lineView.layer.shadowOffset = CGSize(width:5.0,height:5.0)
        self.lineView.layer.shadowOpacity = 0.9
        self.lineView.layer.shadowRadius = 6.0
        self.lineView.layer.masksToBounds = false
    }
    
    func setPage(controller: UIViewController) {
        addChildViewController(controller)
        controller.willMove(toParentViewController: self)
        controller.view.frame = mainContainerView.bounds
        mainContainerView.addSubview(controller.view)
        controller.didMove(toParentViewController: self)
        
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.topAnchor.constraint(equalTo: mainContainerView.topAnchor).isActive = true
        controller.view.leadingAnchor.constraint(equalTo: mainContainerView.leadingAnchor).isActive = true
        controller.view.trailingAnchor.constraint(equalTo: mainContainerView.trailingAnchor).isActive = true
        controller.view.bottomAnchor.constraint(equalTo: mainContainerView.bottomAnchor).isActive = true
        resetAllViews()
    }
    
    func resetAllViews() {
        icon_monitor.image = icon_monitor.image?.withRenderingMode(.alwaysTemplate)
        icon_monitor.tintColor = normalColor
        
        icon_activate.image = icon_activate.image?.withRenderingMode(.alwaysTemplate)
        icon_activate.tintColor = normalColor
        
        icon_replay.image = icon_replay.image?.withRenderingMode(.alwaysTemplate)
        icon_replay.tintColor = normalColor
        
        icon_reports.image = icon_reports.image?.withRenderingMode(.alwaysTemplate)
        icon_reports.tintColor = normalColor
        
        icon_geofence.image = icon_geofence.image?.withRenderingMode(.alwaysTemplate)
        icon_geofence.tintColor = normalColor
        
        icon_alarm.image = icon_alarm.image?.withRenderingMode(.alwaysTemplate)
        icon_alarm.tintColor = normalColor
        
        icon_setAlarms.image = icon_alarm.image?.withRenderingMode(.alwaysTemplate)
        icon_setAlarms.tintColor = normalColor
        
        icon_order_tracker.image = icon_order_tracker.image?.withRenderingMode(.alwaysTemplate)
        icon_order_tracker.tintColor = normalColor
        
        icon_order_service.image = icon_order_service.image?.withRenderingMode(.alwaysTemplate)
        icon_order_service.tintColor = normalColor
        
        icon_driver_info.image = icon_driver_info.image?.withRenderingMode(.alwaysTemplate)
        icon_driver_info.tintColor = normalColor
    }
}
