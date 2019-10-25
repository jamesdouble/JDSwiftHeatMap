//
//  JDHeatPoint.swift
//  JDSwiftHeatMap
//
//  Created by JamesDouble on 2019/10/24.
//

import Foundation
import CoreLocation
import MapKit

struct HeatPoint
{
    let HeatLevel: Int
    let coordinate: CLLocationCoordinate2D
    let radiusInKillometer: Double
    var midMapPoint: MKMapPoint { return MKMapPoint(self.coordinate) }
    
    var radiusInMKDistance:Double {
        let locationdegree:CLLocationDegrees = coordinate.latitude
        let MeterPerMapPointInNowLati:Double = MKMetersPerMapPointAtLatitude(locationdegree)
        let KMPerPerMapPoint:Double = MeterPerMapPointInNowLati / 1000
        let MapPointPerKM:Double = 1 / KMPerPerMapPoint
        return radiusInKillometer * MapPointPerKM
    }
    
    var MapRect: MKMapRect {
        let origin:MKMapPoint = MKMapPoint(x: midMapPoint.x - radiusInMKDistance, y: midMapPoint.y - radiusInMKDistance)
        let size:MKMapSize = MKMapSize(width: 2 * radiusInMKDistance, height: 2 * radiusInMKDistance)
        return MKMapRect(origin: origin, size: size)
    }
    
    init() {
        radiusInKillometer = 100
        HeatLevel = 0
        coordinate = .init()
    }
    
    init(heat level: Int, coor: CLLocationCoordinate2D, heatradius inKM:Double) {
        radiusInKillometer = inKM
        HeatLevel = level
        coordinate = coor
    }
    
    func distanceto(anoter point: HeatPoint) -> CGFloat {
        let latidiff = (point.coordinate.latitude - self.coordinate.latitude)
        let longdiff = (point.coordinate.longitude - self.coordinate.longitude)
        let sqrts = sqrt((latidiff * latidiff) + (longdiff * longdiff))
        return CGFloat(sqrts)
    }
}


