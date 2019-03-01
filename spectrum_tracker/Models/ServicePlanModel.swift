//
//  OrderTrackerModel.swift
//  spectrum_tracker
//
//  Created by JO on 2018/5/7.
//  Copyright © 2018 JO. All rights reserved.
//

import Foundation

class ServicePlanModel {
    var servicePlan: String!
    var price: Double!
    
    init(_ servicePlan: String,
    _ price: Double) {
        self.servicePlan = servicePlan
        self.price = price
    }
}
