//
//  CurrentLocationViewController.swift
//  Crossfire
//
//  Created by Kordel France on 5/29/16.
//  Copyright © 2016 Kade France. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import CoreData

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: NSError?
    var managedObjectContext: NSManagedObjectContext!
    
    //for reverse geocoding
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: NSError?
    var timer: NSTimer?
    
    override func viewDidLoad() {
        print("loaded")
        super.viewDidLoad()
        updateLabels()
        configureGetButton()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func getLocation() {
        //ask permission from the user to use location
        let authStatus = CLLocationManager.authorizationStatus()
        
        //app has not asked for permission  yet. There is an "Always" authorization that will get the users location evern when the app is not in use. "NotDetermined lets the app get the location updates when in use. "Always" is used for apps like Navigation. See info.plist
        if authStatus == .NotDetermined {
            locationManager.requestWhenInUseAuthorization()
            //locationManager.requestAlwaysAuthorization()
            return
        }
        
        if authStatus == .Denied || authStatus == .Restricted {
            showLocationServicesDeniedAlert()
            return
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        
        //startLocationManager()
        if updatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocationManager()
        }
        updateLabels()
        configureGetButton()
    }
    
    func showLocationServicesDeniedAlert() {
        let alert  = UIAlertController(title: "Location Services Disabled", message: "Please enable location services in Settings", preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(okAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func addText(text: String?, toLine line: String, withSeparator separator: String) -> String {
        var result = line
        if let text = text {
            if !line.isEmpty {
                result += separator
            }
            result += text
        }
        return result
    }
    
    //MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("didFailWithError \(error)")
        
        if error.code == CLError.LocationUnknown.rawValue {
            return
        }
        
        lastLocationError = error
        stopLocationManager()
        updateLabels()
        configureGetButton()
    }
    
    //  MARK: - Keep this for constant location updates, live location updates for navigation
    //    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    //        let newLocation = locations.last!
    //        print("didUpdateLocations \(newLocation)")
    //
    //        //store CLLocation object from Location manager and update labels
    //        lastLocationError = nil
    //        location = newLocation
    //        updateLabels()
    //    }
    
    //  MARK: - This function will stop location updates after consecutive location updates are equivalent
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateLocations \(newLocation)")
        
        //if time at which location object was determined was longer than 5 seconds ago, then this is a cached result. If user has not moved, then the last cached location will be submitted as current location
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        
        //only want positive horizontal accuracy measurements
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        //calculates distance between new and previous readings. if there was no previous reading then the previous reading is DBL_MAX
        var distance =  CLLocationDistance(DBL_MAX)
        if let location = location {
            distance = newLocation.distanceFromLocation(location)
        }
        
        //check if new location is more accurate than older one
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            //clear out previous errors if any and store new location object into location variable
            lastLocationError = nil
            location = newLocation
            updateLabels()
            
            //stop location manager if new location is within desired accuracy of older one.
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
                print("Location stopped updating")
                stopLocationManager()
                configureGetButton()
                
                //force reverse geocoding of last determined location
                if distance > 0 {
                    performingReverseGeocoding = false
                }
            }
            
            //for reverse geocoding
            if !performingReverseGeocoding {
                print("Currently geocoding location coordinaes")
                performingReverseGeocoding = true
                geocoder.reverseGeocodeLocation(newLocation, completionHandler: { placemarks, error in
                    print("Found placemarks: \(placemarks), error: \(error)")
                    self.lastGeocodingError = error
                    if error == nil, let p = placemarks where !p.isEmpty {
                        self.placemark = p.last!
                    } else {
                        self.placemark = nil
                    }
                    self.performingReverseGeocoding = false
                    self.updateLabels()
                })
            }
            
            //if new reading is not significantly different than the previous one and it has been more than 10 seconds since that previous reading, then stop.
        } else if distance < 1.0 {
            let timeInterval = newLocation.timestamp.timeIntervalSinceDate(location!.timestamp)
            if timeInterval > 10 {
                print("FORCE DONE")
                stopLocationManager()
                updateLabels()
                configureGetButton()
            }
        }
    }
    
    func updateLabels() {
        if let location = location {
            //placeholders always start with a '%' sign. '%f' is used for decimals and the 8 tells the label to truncate after 8 decimal places
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.hidden = false
            messageLabel.text = ""
            
            if let placemark = placemark {
                addressLabel.text = stringFromPlacemark(placemark)
            } else if performingReverseGeocoding {
                addressLabel.text = "Searching for address"
            } else if lastGeocodingError != nil {
                addressLabel.text = "Error Finding Address"
            } else {
                addressLabel.text = "No address found"
            }
        } else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.hidden = true
            
            //error handling in getting location
            let statusMessage: String
            if let error = lastLocationError {
                if error.domain == kCLErrorDomain && error.code == CLError.Denied.rawValue {
                    statusMessage = "Location Services is Disabled"
                } else {
                    statusMessage = "Error Getting Location"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Location Services is Disabled"
            } else if updatingLocation {
                statusMessage = "Searching..."
            } else {
                statusMessage = "GEOLOCATOR"
            }
            
            messageLabel.text = statusMessage
        }
    }
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
            
            timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: Selector("didTimeOut"), userInfo: nil, repeats: false)
        }
    }
    
    func stopLocationManager() {
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    func configureGetButton() {
        if updatingLocation {
            if let timer = timer {
                timer.invalidate()
            }
            getButton.setTitle("Stop", forState: .Normal)
        } else {
            getButton.setTitle("Get My Location", forState: .Normal)
        }
    }
    
    func stringFromPlacemark(placemark: CLPlacemark) -> String {
        
        var line1 = ""
        
        //if there is a house number, add to the string
        if let s = placemark.subThoroughfare {
            line1 += s + " "
        }
        
        //if there is a street number, add to the string
        if let s = placemark.thoroughfare {
            line1 += s
        }
        
        var line2 = ""
        
        //if there is a city, add to the second string
        if let s = placemark.locality {
            line2 += s + " "
        }
        
        if let s = placemark.administrativeArea {
            line2 += s + " "
        }
        
        //if there is a postal code, add to the second string
        if let s = placemark.postalCode {
            line2 += s
        }
        
        return line1 + "\n" + line2
    }
    
    //always called after sixty seconds
    func didTimeOut() {
        print("TIME OUT")
        
        if location == nil {
            stopLocationManager()
            
            lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
            
            updateLabels()
            configureGetButton()
        }
    }
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == "Tag Location" {
//            let navigationController = segue.destinationViewController as! UINavigationController
//            let controller = navigationController.topViewController as! LocationDetailsViewController
//            controller.coordinate = location!.coordinate
//            controller.placemark = placemark
////            controller.managedObjectContext = managedObjectContext
//        }
//    }
}
