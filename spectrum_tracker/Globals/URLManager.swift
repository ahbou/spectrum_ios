import Foundation
import Alamofire

class URLManager {
    static var baseUrl = "https://api.spectrumtracking.com/v1/"
    static var imageBaseUrl = "https://app.spectrumtracking.com/"
    
    class var isConnectedToInternet:Bool {
        return NetworkReachabilityManager()!.isReachable
    }
    
    static func authLogin() -> (String, HTTPMethod) {
        return (baseUrl + "auth/login", .post)
    }
    
    static func authLoginGoogle() -> (String, HTTPMethod) {
        return (baseUrl + "auth/socialAppLogin", .post)
    }
    
    static func authResendPasswordReset() -> (String, HTTPMethod) {
        return (baseUrl + "auth/resend-password-reset", .post)
    }
    
    static func authRegister() -> (String, HTTPMethod) {
        return (baseUrl + "auth/register", .post)
    }
    
    static func authVerify() -> (String, HTTPMethod) {
        return (baseUrl + "auth/verify", .post)
    }
    
    static func authResetPassword() -> (String, HTTPMethod) {
        return (baseUrl + "auth/reset-password", .post)
    }
    
    static func assets() -> (String, HTTPMethod) {
        return (baseUrl + "assets", .get)
    }

    static func updateAsset(_ id: String!) -> (String, HTTPMethod) {
        return (baseUrl + "assets/" + id, .put)
    }

    static func tokenizeCreditCard() -> (String, HTTPMethod) {
        return ("https://app.spectrumtracking.com/php/route.php", .post)
    }

    static func doAuth() -> (String, HTTPMethod) {
        return (baseUrl + "auth", .get)
    }
    
    static func updateCreditCardInfoSecondary(_ id: String) -> (String, HTTPMethod) {
        return (baseUrl + "users/" + id, .put)
    }
    
    static func trackerRegister() -> (String, HTTPMethod) {
        return (baseUrl + "trackers/register", .post)
    }
    static func createAssets() -> (String, HTTPMethod) {
        return (baseUrl + "assets", .post)
    }

    static func ordersPayment() -> (String, HTTPMethod) {
        return (baseUrl + "orders/payment", .post)
    }
    
    static func trackers_id(_ id: String!) -> (String, HTTPMethod) {
        return (baseUrl + "trackers/" + id, .get)
    }
    
    static func assets_logs(_ id: String!) -> (String, HTTPMethod) {
        return (baseUrl + "assets/" + id + "/logs", .get)
    }
    
    static func trip_logs(_ id: String!) -> (String, HTTPMethod) {
        return (baseUrl + "triplog/" + id + "/logs", .get)
    }
    
    static func event_logs(_ id: String!) -> (String, HTTPMethod) {
        return (baseUrl + "alertlog/" + id + "/logs", .get)
    }
    
    static func generateToken() -> (String, HTTPMethod) {
        return (baseUrl + "orders/generateToken", .post)
    }
    
    //added by Robin
    static func setGeofence() -> (String, HTTPMethod) {
        return (baseUrl + "trackers/setGeoFence" , .post)
    }
    
    //added by Robin
    static func alarm(_ id: String!) -> (String, HTTPMethod) {
        return (baseUrl + "trackers/byAssetName/" + id, .get)
    }
    
    //added by Robin
    static func modify() -> (String, HTTPMethod) {
        return (baseUrl + "trackers/modify" , .post)
    }
    
    static func testUrl() -> (String, HTTPMethod) {
        return ("http://192.168.0.104/test.php", .get)
    }
    
}
