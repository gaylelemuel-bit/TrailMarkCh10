import Foundation
import CoreLocation
import Observation

extension LocationManager: CLLocationManagerDelegate {
    nonisolated public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let points = locations.map(TrackPoint.init(location:))
        Task { @MainActor in
            self.currentLocation = locations.last

            if self.isLocationBeingRecorded {
                self.track.points.append(contentsOf: points)
            }
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
    }
}
