//
//  JDRealHeatMap.swift
//  JDRealHeatMap
//
//  Created by 郭介騵 on 2017/6/12.
//  Copyright © 2017年 james12345. All rights reserved.
//

import Foundation
import MapKit

class JDRealHeatMap:MKMapView
{
    var heatmapdelegate: JDHeatMapDelegate?
    
    public init(frame: CGRect,delegate d:JDHeatMapDelegate) {
        super.init(frame: frame)
        self.showsScale = true
        self.delegate = self
        self.heatmapdelegate = d
        refresh()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refresh()
    {
        var HeatPointsBuffer:[JDHeatPoint] = []
        self.removeOverlays(overlays)
        //
        guard let heatdelegate = heatmapdelegate else {
            return
        }
        let datacount = heatdelegate.heatmap(HeatPointCount: self)
        for i in 0..<datacount
        {
            let coor = heatdelegate.heatmap(CoordinateFor: i)
            let heat = heatdelegate.heatmap(HeatLevelFor: i)
            let raius = heatdelegate.heatmap(RadiusInKMFor: i)
            let newHeatPoint:JDHeatPoint = JDHeatPoint(heat: heat, coor: coor, heatradius: raius)
            HeatPointsBuffer.append(newHeatPoint)
        }
        //
        func CluseOverlay()
        {
            for heatpoint in HeatPointsBuffer
            {
                for overlay in overlays
                {
                    let heatmkmappoint = MKMapPointForCoordinate(heatpoint.coordinate)
                    let overlaymaprect = overlay.boundingMapRect
                    if(MKMapRectContainsPoint(overlaymaprect, heatmkmappoint))
                    {
                        if let heatoverlay = overlay as? JDHeatOverlay
                        {
                            heatoverlay.insertHeatpoint(input: heatpoint)
                            return
                        }
                    }
                }
                //Create New OverLay
                let heatoverlay = JDHeatOverlay(first: heatpoint)
                self.add(heatoverlay)
            }
        }
        CluseOverlay()
        self.setNeedsDisplay()
    }
}

extension JDRealHeatMap:MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
    {
        print(#function)
        if let jdoverlay = overlay as? JDHeatOverlay
        {
            let render = JDHeatOverlayRender(heat: jdoverlay)
            return render
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        let aview = MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
        aview.backgroundColor = UIColor.white
        aview.frame.size = CGSize(width: 100, height:100)
        return aview
    }
}

protocol JDHeatMapDelegate {
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
    var radiusInMKDistance:Double
    {
        let locationdegree:CLLocationDegrees = coordinate.latitude
        let MeterPerMapPointInNowLati:Double = MKMetersPerMapPointAtLatitude(locationdegree)
        let KMPerPerMapPoint:Double = MeterPerMapPointInNowLati / 1000
        let MapPointPerKM:Double = 1 / KMPerPerMapPoint
        return radiusInKillometer * MapPointPerKM
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


