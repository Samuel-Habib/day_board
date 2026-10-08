import Foundation
import CoreLocation
import Observation

@Observable
public class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    public var location: CLLocation?
    public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers // Coarse accuracy is perfect for general weather.
        
        // Start requesting location access and update location
        DispatchQueue.main.async {
            self.requestLocation()
        }
    }
    
    public func requestLocation() {
        self.authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            // Denied or restricted, fall back to default coordinate
            break
        }
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations.last
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("CoreLocation failed: \(error.localizedDescription)")
    }
}
