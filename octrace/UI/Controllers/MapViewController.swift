import UIKit
import MapKit
import Alamofire

class MapViewController: UIViewController {
    
    private static let myLocationDistanceMeters = 3000
    
    private static let annotationIdentifier = "InfectedContactAnnotation"
    
    var rootViewController: RootViewController!
    
    private var mkContactPoints: [MKPointAnnotation] = []
    private var mkUserPolylines: [MKPolyline] = []
    private var mkSickPolylines: [MKPolyline] = []
    
    private var tracks: [TrackingPoint] = []
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var myLocationButton: UIButton!
    @IBOutlet weak var contactButton: UIButton!
    @IBOutlet weak var accuracyLabel: UILabel!
    
    @IBAction func zoomIn(_ sender: Any) {
        mapView.zoomLevel += 1
    }
    
    @IBAction func zoomOut(_ sender: Any) {
        mapView.zoomLevel -= 2
    }
    
    @IBAction func goToMyLocation(_ sender: Any) {
        guard let location = LocationManager.lastLocation else {
            return
        }
        
        goToLocation(location)
    }
    
    @IBAction func openBtLog(_ sender: Any) {
        let logsController = BtLogsViewController(nib: R.nib.btLogsViewController)
        
        rootViewController.navigationController?.present(logsController, animated: true)
    }
    
    @IBAction func openDp3tLog(_ sender: Any) {
        let logsController = Dp3tLogsViewController(nib: R.nib.dp3tLogsViewController)
        
        rootViewController.navigationController?.present(logsController, animated: true)
    }
    
    @IBAction func makeContact(_ sender: Any) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .denied:
                    self.showSettings(R.string.localizable.notifications_disabled())
                    
                case .notDetermined:
                    self.confirm(R.string.localizable.notifications_disabled()) {
                        UNUserNotificationCenter.current()
                            .requestAuthorization(options: [.alert, .badge, .sound]) { _, _  in
                        }
                    }
                    
                default:
                    let linkController = QrLinkViewController(nib: R.nib.qrLinkViewController)
                    
                    self.rootViewController.navigationController?.present(linkController, animated: true)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        goToMyLocation()
        
        updateExtTracks()
        updateContacts()
    }
    
    func updateUserTracks() {
        print("Updating user tracks...")
        
        let polylines = makePolylines(TrackingManager.trackingData)
        
        print("Got \(polylines.count) user polylines.")
        
        mkUserPolylines.forEach(mapView.removeOverlay)
        mkUserPolylines = polylines.map { MKPolyline(coordinates: $0, count: $0.count) }
        mkUserPolylines.forEach(mapView.addOverlay)
    }
    
    func updateExtTracks() {
        print("Updating external tracks...")
        
        var sickPolylines: [[CLLocationCoordinate2D]] = []
        
        TracksManager.tracks.forEach { track in
            let trackPolylines = makePolylines(track.points)
            sickPolylines.append(contentsOf: trackPolylines)
        }
        
        print("Got \(sickPolylines.count) sick polylines.")
        
        let now = Date.timeIntervalSinceReferenceDate
        
        mkSickPolylines.forEach(mapView.removeOverlay)
        mkSickPolylines = sickPolylines.map { MKPolyline(coordinates: $0, count: $0.count) }
        mkSickPolylines.forEach(mapView.addOverlay)
        
        let renderTime = Int(Date.timeIntervalSinceReferenceDate - now)
        
        print("Rendered \(sickPolylines.count) sick polylines in \(renderTime) seconds.")
        
        // So that user tracks are always above
        updateUserTracks()
    }
    
    private func makePolylines(_ points: [TrackingPoint]) -> [[CLLocationCoordinate2D]] {
        var polylines: [[CLLocationCoordinate2D]] = []
        var lastPolyline: [CLLocationCoordinate2D] = []
        var lastTimestamp: Int64 = 0
        
        func addPolyline() {
            if lastPolyline.count == 1 {
                // Each polyline should have at least 2 points
                lastPolyline.append(lastPolyline.first!)
            }
            
            polylines.append(lastPolyline)
        }
        
        points.forEach { point in
            let timestamp = point.tst
            let coordinate = point.coordinate()
            
            if lastTimestamp == 0 {
                lastPolyline = [coordinate]
            } else if timestamp - lastTimestamp > TrackingManager.trackingIntervalMs * 2 {
                addPolyline()
                
                lastPolyline = [coordinate]
            } else {
                lastPolyline.append(coordinate)
            }
            
            lastTimestamp = timestamp
        }
        
        addPolyline()
        
        return polylines
    }
    
    private func goToMyLocation() {
        LocationManager.registerCallback { location in
            self.goToLocation(location)
            
            let distance = MapViewController.myLocationDistanceMeters
            
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: CLLocationDistance(exactly: distance)!,
                longitudinalMeters: CLLocationDistance(exactly: distance)!
            )
            
            self.mapView.setRegion(self.mapView.regionThatFits(region), animated: true)
            
            self.myLocationButton.isEnabled = true
        }
    }
    
    func updateContacts() {
        mkContactPoints.forEach(mapView.removeAnnotation)
        mkContactPoints.removeAll()
        
        func addContactPoint(_ metaData: ContactMetaData, _ coord: ContactCoord) {
            let annotation = MKPointAnnotation()
            
            annotation.coordinate = coord.coordinate()
            let date = AppDelegate.dateFormatter.string(from: metaData.date)
            annotation.title = R.string.localizable.contact_at_date(date)
            
            mkContactPoints.append(annotation)
        }
        
        BtContactsManager.contacts.values.forEach { contact in
            contact.encounters.forEach { encounter in
                if let metaData = encounter.metaData,
                    let coord = metaData.coord {
                    addContactPoint(metaData, coord)
                }
            }
        }
        
        QrContactsManager.contacts.forEach { contact in
            if let metaData = contact.metaData,
                let coord = metaData.coord {
                addContactPoint(metaData, coord)
            }
        }
        
        mkContactPoints.forEach(mapView.addAnnotation)
    }
    
    func goToContact(_ coord: ContactCoord) {
        goToLocation(CLLocation(latitude: coord.lat, longitude: coord.lng))
    }
    
    private func goToLocation(_ location: CLLocation) {
        mapView.setCenter(location.coordinate, animated: true)
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer()
        }
        
        let renderer = MKPolylineRenderer(polyline: polyline)
        
        renderer.lineWidth = 3.0
        
        if mkUserPolylines.contains(polyline) {
            renderer.strokeColor = UIColor.systemBlue
        } else if mkSickPolylines.contains(polyline) {
            renderer.strokeColor = UIColor.systemRed
        }
        
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }
        
        var annotationView: MKAnnotationView?
        
        annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: MapViewController.annotationIdentifier)
        
        if annotationView == nil {
            let pinAnnotationView = MKPinAnnotationView(
                annotation: annotation,
                reuseIdentifier: MapViewController.annotationIdentifier
            )
            pinAnnotationView.pinTintColor = UIColor.systemRed
            annotationView = pinAnnotationView
            annotationView!.canShowCallout = true
        } else {
            annotationView!.annotation = annotation
        }
        
        return annotationView
    }
    
}


extension MKMapView {
    
    var zoomLevel: Int {
        get {
            return Int(log2(360 * (Double(frame.size.width/256) / region.span.longitudeDelta)) + 1)
        }
        
        set (newZoomLevel) {
            setCenterCoordinate(coordinate: centerCoordinate, zoomLevel: newZoomLevel, animated: true)
        }
    }
    
    private func setCenterCoordinate(coordinate: CLLocationCoordinate2D, zoomLevel: Int, animated: Bool) {
        let span = MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 360 / pow(2, Double(zoomLevel)) *
            Double(self.frame.size.width) / 256)
        setRegion(MKCoordinateRegion(center: coordinate, span: span), animated: animated)
    }
    
}
