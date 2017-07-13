//
//  JDSwiftHeatMap.swift
//  JDSwiftHeatMap
//
//  Created by 郭介騵 on 2017/6/12.
//  Copyright © 2017年 james12345. All rights reserved.
//

import Foundation
import MapKit

public enum JDMapType
{
    case RadiusDistinct
    case FlatDistinct
    case RadiusBlurry
}

enum DataPointType
{
    case FlatPoint
    case RadiusPoint
}


public class JDSwiftHeatMap:MKMapView
{
    var heatmapdelegate: JDHeatMapDelegate?
    var missionController:JDHeatMapMissionController!
    var indicator:UIActivityIndicatorView?
    //
    public var showindicator:Bool = true{
        didSet{
            if(!showindicator)
            {
                indicator?.stopAnimating()
            }
        }
    }
    
    public init(frame: CGRect,delegate d:JDHeatMapDelegate,maptype type:JDMapType,BasicColors array:[UIColor] = [UIColor.blue,UIColor.green,UIColor.red],devideLevel:Int = 2)
    {
        super.init(frame: frame)
        self.showsScale = true
        self.delegate = self
        self.heatmapdelegate = d
        JDRowDataProducer.theColorMixer = JDHeatColorMixer(array: array, level: devideLevel)
        if(type == .RadiusBlurry)
        {
            missionController = JDHeatMapMissionController(JDSwiftHeatMap: self, datatype: .RadiusPoint,mode: .BlurryMode)
        }
        else if(type == .FlatDistinct)
        {
            missionController = JDHeatMapMissionController(JDSwiftHeatMap: self, datatype: .FlatPoint,mode: .DistinctMode)
        }
        else if(type == .RadiusDistinct)
        {
            missionController = JDHeatMapMissionController(JDSwiftHeatMap: self, datatype: .RadiusPoint,mode: .DistinctMode)
        }
        refresh()
        InitIndicator()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func refresh()
    {
        if(self.showindicator)
        {
            self.indicator?.startAnimating()
        }
        missionController.ExecuteRefreshMission()
    }
    
    public func setType(type:JDMapType)
    {
        if(type == .RadiusBlurry)
        {
            missionController = JDHeatMapMissionController(JDSwiftHeatMap: self, datatype: .RadiusPoint,mode: .BlurryMode)
        }
        else if(type == .FlatDistinct)
        {
            missionController = JDHeatMapMissionController(JDSwiftHeatMap: self, datatype: .FlatPoint,mode: .DistinctMode)
        }
        else if(type == .RadiusDistinct)
        {
            missionController = JDHeatMapMissionController(JDSwiftHeatMap: self, datatype: .RadiusPoint,mode: .DistinctMode)
        }
        refresh()
    }
    
    func reZoomRegion(biggestRegion:MKMapRect)
    {
        self.setRegion(MKCoordinateRegionForMapRect(biggestRegion), animated: true)
    }
    
    func InitIndicator()
    {
        indicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        indicator?.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(indicator!)
        let sizeWidth = NSLayoutConstraint(item: indicator!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 60)
        let sizeHeight = NSLayoutConstraint(item: indicator!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 60)
        let CenterX = NSLayoutConstraint(item: indicator!, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0)
        let CenterY = NSLayoutConstraint(item: indicator!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0)
        
        //let rightCon = NSLayoutConstraint(item: indicator!, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0)
        //let BottomCon = NSLayoutConstraint(item: indicator!, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0)
        indicator?.addConstraints([sizeWidth,sizeHeight])
        self.addConstraints([CenterX,CenterY])
        self.updateConstraints()
    }
}

extension JDSwiftHeatMap:MKMapViewDelegate
{
    
    public func heatmapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer?
    {
        if let FlatOverlay = overlay as? JDHeatFlatPointOverlay
        {
            let onlyRender = JDFlatPointOverlayRender(heat: FlatOverlay)
            return onlyRender
        }
        else if let radiusOverlay = overlay as? JDHeatRadiusPointOverlay
        {
            let render = JDRadiusPointOverlayRender(heat: radiusOverlay)
            return render
        }
        return MKOverlayRenderer()
    }
    
    public func heatmapViewWillStartRenderingMap(_ mapView: MKMapView)
    {
        missionController.mapViewWillStartRenderingMap()
    }
    
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
    {
        if let heatoverlay = self.heatmapView(mapView, rendererFor: overlay)
        {
            return heatoverlay
        }
        else
        {
            return MKOverlayRenderer()
        }
    }
    
    public func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
        self.heatmapViewWillStartRenderingMap(mapView)
    }
}

public protocol JDHeatMapDelegate {
    func heatmap(HeatPointCount heatmap:JDSwiftHeatMap) -> Int
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


