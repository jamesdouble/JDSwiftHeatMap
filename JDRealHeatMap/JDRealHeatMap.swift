//
//  JDRealHeatMap.swift
//  JDRealHeatMap
//
//  Created by 郭介騵 on 2017/6/12.
//  Copyright © 2017年 james12345. All rights reserved.
//

import Foundation
import MapKit

public class JDRealHeatMap:MKMapView
{
    var heatmapdelegate: JDHeatMapDelegate?
    var missionController:JDHeatMapMissionController!
    public init(frame: CGRect,delegate d:JDHeatMapDelegate) {
        super.init(frame: frame)
        self.showsScale = true
        self.delegate = self
        self.heatmapdelegate = d
        missionController = JDHeatMapMissionController(JDRealHeatMap: self)
        refresh()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func refresh()
    {
        missionController.ExecuteRefreshMission()
    }
    
    func reZoomRegion(biggestRegion:MKMapRect)
    {
        self.setRegion(MKCoordinateRegionForMapRect(biggestRegion), animated: true)
    }
}

extension JDRealHeatMap:MKMapViewDelegate
{
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
    {
        print(#function)
        if let jdoverlay = overlay as? JDHeatOverlay
        {
            if let createdRender:JDHeatOverlayRender = missionController.Overlay_RenderPair[jdoverlay]
            {
                return createdRender
            }
        }
        return MKOverlayRenderer()
    }
    
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        let aview = MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
        aview.backgroundColor = UIColor.white
        aview.frame.size = CGSize(width: 100, height:100)
        return aview
    }
}

public protocol JDHeatMapDelegate {
    func heatmap(HeatPointCount heatmap:JDRealHeatMap) -> Int
    func heatmap(HeatLevelFor index:Int) -> Int
    func heatmap(RadiusInKMFor index:Int) -> Double
    func heatmap(CoordinateFor index:Int) -> CLLocationCoordinate2D
}

extension JDHeatMapDelegate
{
    func heatmap(RadiusInKMFor index:Int) -> Double
    {
        return 100
    }
}

struct JDHeatPoint
{
    var HeatLevel:Int = 0
    var coordinate:CLLocationCoordinate2D = CLLocationCoordinate2D.init()
    
    var radiusInKillometer:Double = 100
    var MidMapPoint:MKMapPoint
    {
        return MKMapPointForCoordinate(self.coordinate)
    }
    var radiusInMKDistance:Double
    {
        let locationdegree:CLLocationDegrees = coordinate.latitude
        let MeterPerMapPointInNowLati:Double = MKMetersPerMapPointAtLatitude(locationdegree)
        let KMPerPerMapPoint:Double = MeterPerMapPointInNowLati / 1000
        let MapPointPerKM:Double = 1 / KMPerPerMapPoint
        return radiusInKillometer * MapPointPerKM
    }
    
    var MapRect:MKMapRect
    {
        let origin:MKMapPoint = MKMapPoint(x: MidMapPoint.x - radiusInMKDistance, y: MidMapPoint.y - radiusInMKDistance)
        let size:MKMapSize = MKMapSize(width: 2 * radiusInMKDistance, height: 2 * radiusInMKDistance)
        return MKMapRect(origin: origin, size: size)
    }
    
    init()
    {
        
    }
  
    init(heat level:Int,coor:CLLocationCoordinate2D,heatradius inKM:Double)
    {
        radiusInKillometer = inKM
        HeatLevel = level
        coordinate = coor
    }
    
    func distanceto(anoter point:JDHeatPoint)->CGFloat
    {
        let latidiff = (point.coordinate.latitude - self.coordinate.latitude)
        let longdiff = (point.coordinate.longitude - self.coordinate.longitude)
        let sqrts = sqrt((latidiff * latidiff) + (longdiff * longdiff))
        return CGFloat(sqrts)
    }
    
   
}


