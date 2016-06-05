//
//  ViewController.swift
//  Crossfire
//
//  Created by Kordel France on 5/29/16.
//  Copyright © 2016 Kade France. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    
//    @IBAction func showUser() {
//        let region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 1000, 1000)
//        mapView.setRegion(mapView.regionThatFits(region), animated: true)
//    }
//    
//    //calculate reasonable region that fits all Location objects and set that region on the map
//    @IBAction func showLocations() {
//        let region = regionForAnnotations(locations)
//        mapView.setRegion(region, animated: true)
//    }
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        self.mapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
        self.mapView.showsUserLocation = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func locationManager(manager: CLLocationManager, didupdateLocations locations: [CLLocation]) {
        let location = locations.last
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        self.mapView.setRegion(region, animated: true)
        self.locationManager.stopUpdatingLocation()
    }
    
    func regionForAnnotations(annotations: [MKAnnotation]) -> MKCoordinateRegion {
        var region: MKCoordinateRegion
        
        switch annotations.count {
            
        //there are no annotations. center the map on user's current position
        case 0 :
            region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 1000, 1000)
            
        //there is one annotation. center map on that one annotation
        case 1:
            let annotation = annotations[annotations.count - 1]
            region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 1000, 1000)
            
        //there are 2+ annotations. find extent of their reach and add "extra space." always return positive number.
        default:
            var topLeftCoord = CLLocationCoordinate2D(latitude: -90, longitude: 180)
            var bottomRightCoord = CLLocationCoordinate2D(latitude: 90, longitude: -180)
            
            for annotation in annotations {
                topLeftCoord.latitude = max(topLeftCoord.latitude, annotation.coordinate.latitude)
                topLeftCoord.longitude = min(topLeftCoord.longitude, annotation.coordinate.longitude)
                bottomRightCoord.latitude = min(bottomRightCoord.latitude, annotation.coordinate.latitude)
                bottomRightCoord.longitude = max(bottomRightCoord.longitude, annotation.coordinate.longitude)
            }
            
            let center = CLLocationCoordinate2D(
                latitude: topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) / 2,
                longitude: topLeftCoord.longitude - (topLeftCoord.longitude - bottomRightCoord.longitude) / 2)
            
            let extraSpace = 1.1
            let span = MKCoordinateSpan(
                latitudeDelta: abs(topLeftCoord.latitude - bottomRightCoord.latitude) * extraSpace,
                longitudeDelta: abs(topLeftCoord.longitude - bottomRightCoord.longitude) * extraSpace)
            
            region = MKCoordinateRegion(center: center, span: span)
        }
        
        return mapView.regionThatFits(region)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error shit went wrong")
    }
    
    //tap a pin and it does an action
//    func showLocationDetails(sender: UIButton) {
//        
//        performSegueWithIdentifier("EditLocation", sender: sender)
//    }
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == "EditLocation" {
//            let navigationController = segue.destinationViewController as! UINavigationController
//            let controller = navigationController.topViewController as! LocationDetailsViewController
//            controller.managedObjectContext = managedObjectContext
//            
//            let button = sender as! UIButton
//            let location = locations[button.tag]
//            controller.locationToEdit = location
//        }
//    }
}

//extension MapViewController: MKMapViewDelegate {
//    
//    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
//        MKMapType.Hybrid
//        //check if the annotation is really a Location object. If it isn't return nil so we dont make annotation for this other kind of object, such as the blue dot that usually represents a users current location
//        guard annotation is Location else {
//            return nil
//        }
//        
//        //similar to creating a tableView cell. ask the map to reuse annotation object or create a new one if there is none recyclable
//        let identifier = "Location"
//        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as! MKPinAnnotationView!
//        
//        if annotationView == nil {
//            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
//            MKMapType.Hybrid
//            //configure UI
//            annotationView.enabled = true
//            annotationView.canShowCallout = true
//            annotationView.animatesDrop = false
//            annotationView.pinTintColor = UIColor(red: 0.8, green: 0.82, blue: 0.4, alpha: 1)
//            annotationView.tintColor = UIColor(white: 0.0, alpha: 0.5)
//            
//            let rightButton = UIButton(type: .DetailDisclosure)
//            rightButton.addTarget(self, action: Selector("showLocationDetails:"), forControlEvents: .TouchUpInside)
//            annotationView.rightCalloutAccessoryView = rightButton
//        } else {
//            annotationView.annotation = annotation
//        }
//        
//        //once annotation view is constructed and configured, obtain a reference to the detail disclosure button again and set its tag to index of Location object in locations array so location can be found later in showLocationDetails()
//        let button = annotationView.rightCalloutAccessoryView as! UIButton
//        if let index = locations.indexOf(annotation as! Location) {
//            button.tag = index
//        }
//        
//        return annotationView
//    }
//}
//
////extend nav bar under status bar area
//extension MapViewController: UINavigationBarDelegate {
//    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
//        return .TopAttached
//    }
//}

