import Foundation
import SwiftyJSON

class TrackerModel {

    var dataPlan: String!
    var LTEData: String!
    var speedInMph: Double!
    var lat: Double!
    var lng: Double!
    var lat1: Double!
    var lng1: Double!
    var lat2: Double!
    var lng2: Double!
    var expirationDate: Date!
    var lastLogDateTime: Date!
    var accStatus: Int!
    var trackerModel: String!
    var voltage: Double!
    var tankVolume: Double!
    var weekMile: Float!
    var dayMile: Float!
    var monthMile: Float!
    var yearMile: Float!
    var harshAcce: Int!
    var harshDece: Int!
    var speeding: Int!
    var lastACCOntime: Date!
    var lastACCOfftime: Date!
    var lastACCOnLat: Double!
    var lastACCOnLng: Double!
    var lastACCOffLat: Double!
    var lastACCOffLng: Double!
    var lastStartAddress: String!
    var lastStopAddress: String!
    var reportingId: String!
    var alert: String!
    
    static func parseJSON(_ json: JSON) -> TrackerModel {
        let item = TrackerModel()
        item.dataPlan = json["dataPlan"].stringValue
        item.LTEData = json["LTEData"].stringValue
        item.speedInMph = json["speedInMph"].doubleValue
        item.accStatus = json["ACCStatus"].intValue
        item.trackerModel = json["TrackerModel"].stringValue
        item.voltage = json["voltage"].doubleValue
        item.tankVolume = json["tankVolume"].doubleValue
        item.weekMile = json["weekMile"].floatValue
        item.dayMile = json["dayMile"].floatValue
        item.monthMile = json["monthMile"].floatValue
        item.yearMile = json["yearMile"].floatValue
        item.lastACCOntime = json["lastACCOnTime"].stringValue.toDate("yyyy-MM-dd'T'HH:mm:ss.SSSZ")
        item.lastACCOfftime = json["lastACCOffTime"].stringValue.toDate("yyyy-MM-dd'T'HH:mm:ss.SSSZ")
        item.lastACCOnLat = json["lastACCOnLat"].doubleValue
        item.lastACCOnLng = json["lastACCOnLng"].doubleValue
        item.lastACCOffLat = json["lastACCOffLat"].doubleValue
        item.lastACCOffLng = json["lastACCOffLng"].doubleValue
        item.harshAcce = json["dayAece"].intValue
        item.harshDece = json["dayDece"].intValue
        item.speeding = json["daySpeeding"].intValue
        item.alert = json["lastAlert"].stringValue
        item.reportingId = json["reportingId"].stringValue
        if (json["lat"] != JSON.null)
        {
            item.lat = json["lat"].doubleValue
        }
        if (json["lng"] != JSON.null)
        {
            item.lng = json["lng"].doubleValue
        }
        item.lng1 = json["lng1"].doubleValue
        item.lng2 = json["lng2"].doubleValue
        item.lat1 = json["lat1"].doubleValue
        item.lat2 = json["lat2"].doubleValue
        let sExpirationDate = json["expirationDate"].stringValue
        let sLastLogDateTime = json["lastLogDateTime"].stringValue
        item.expirationDate = sExpirationDate.toDate("yyyy-MM-dd'T'HH:mm:ss.SSSZ")
        item.lastLogDateTime = sLastLogDateTime.toDate("yyyy-MM-dd'T'HH:mm:ss.SSSZ")

        return item
    }
    
}
