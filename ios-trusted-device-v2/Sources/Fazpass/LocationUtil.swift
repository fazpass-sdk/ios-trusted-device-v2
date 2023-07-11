
import CoreLocation

internal class LocationUtil: NSObject, CLLocationManagerDelegate {
    
    private static _const let LOCATION_DELAY = 2.0
    
    private let locationManager: CLLocationManager
    private var savedLocations: [CLLocation]
    private var currentCallback: ((CLLocation?, Bool) -> Void)? = nil
    private var hasReceivedAuthStatus = false
    
    init(_ locManager: CLLocationManager) {
        self.locationManager = locManager
        self.savedLocations = []
        super.init()
    }
    
    func getLocation(_ callback: @escaping (CLLocation?, Bool) -> Void) {
        currentCallback = callback
        
        let status = getAuthorizationStatus()
        switch status {
        case .notDetermined:
            requestToUseLocation()
        case .authorizedWhenInUse:
            requestLocation()
        default:
            currentCallback!(nil, false)
        }
    }
    
    private func requestToUseLocation() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func requestLocation() {
        locationManager.startUpdatingLocation()
    }
    
    private func getAuthorizationStatus() -> CLAuthorizationStatus {
        if #available(iOS 14, *) {
            return locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }
    
    private func delay(_ delay: Double, closure: @escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
    
    private func checkForMockPossibility(_ locations: [CLLocation]) -> Bool {
        let threeNewestLocations = locations[locations.count-3...locations.count-1]
        let comparingLocation = locations.last!
        
        let isSuspectedMock = threeNewestLocations.allSatisfy {
            $0.coordinate.latitude == comparingLocation.coordinate.latitude
            && $0.coordinate.longitude == comparingLocation.coordinate.longitude }
        || threeNewestLocations.contains { $0.altitude == 0.0 }
        
        return isSuspectedMock
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if !hasReceivedAuthStatus {
            hasReceivedAuthStatus = true
            return
        }
        
        let status = getAuthorizationStatus()
        switch status {
        case .authorizedWhenInUse:
            requestLocation()
        default:
            currentCallback!(nil, false)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        savedLocations.append(contentsOf: locations)
        
        if savedLocations.count >= 3 {
            let location = savedLocations.last!
            let isSuspectedMock = checkForMockPossibility(savedLocations)
            currentCallback!(location, isSuspectedMock)
        } else {
            delay(LocationUtil.LOCATION_DELAY) {
                self.locationManager.startUpdatingLocation()
            }
        }
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
        locationManager.stopUpdatingLocation()
        currentCallback!(nil, false)
    }
}
