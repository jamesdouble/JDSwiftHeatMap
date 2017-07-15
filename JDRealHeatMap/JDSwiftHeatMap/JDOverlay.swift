//
//  JDOverlay.swift
//  JDSwiftHeatMap
//
//  Created by 郭介騵 on 2017/6/14.
//  Copyright © 2017年 james12345. All rights reserved.
//

import UIKit
import MapKit

/**
    這個類別只需要知道MapRect層面，不需要知道CGRect層面的事
 */

class JDHeatOverlay:NSObject, MKOverlay
{
    var HeatPointsArray:[JDHeatPoint] = []
    var CaculatedMapRect:MKMapRect?
    /* Overlay的中心 */
    var coordinate: CLLocationCoordinate2D
    {
        let midMKPoint = MKMapPoint(x: MKMapRectGetMidX(boundingMapRect), y: MKMapRectGetMidY(boundingMapRect))
        return MKCoordinateForMapPoint(midMKPoint)
    }
    /* Overlay涵蓋的範圍 */
    var boundingMapRect: MKMapRect
    {
        guard let BeenCaculatedMapRect = CaculatedMapRect else {
            fatalError("boundingMapRect Error")
        }
        return BeenCaculatedMapRect
    }
    
    init(first Heatpoint:JDHeatPoint)
    {
        super.init()
        caculateMaprect(newPoint: Heatpoint)
        HeatPointsArray.append(Heatpoint)
    }
    
    func caculateMaprect(newPoint:JDHeatPoint)
    {
        fatalError("Should implement this method in child class")
    }
    
    /**
     新的點進來先放在Buffer裡
     */
    func insertHeatpoint(input:JDHeatPoint)
    {
        caculateMaprect(newPoint: input)
        HeatPointsArray.append(input)
    }
}

class JDHeatRadiusPointOverlay:JDHeatOverlay
{
    var NewHeatPointBuffer:[JDHeatPoint] = []
    /**
     有新的點加進來 ->
     重新計算這個Overlay的涵蓋
     */
    override func caculateMaprect(newPoint:JDHeatPoint)
    {
        var MaxX:Double = -9999999999999
        var MaxY:Double = -9999999999999
        var MinX:Double = 99999999999999
        var MinY:Double = 99999999999999
        if let BeenCaculatedMapRect = CaculatedMapRect
        {
            //Not the First Time
            MaxX = MKMapRectGetMaxX(BeenCaculatedMapRect)
            MaxY = MKMapRectGetMaxY(BeenCaculatedMapRect)
            MinX = MKMapRectGetMinX(BeenCaculatedMapRect)
            MinY = MKMapRectGetMinY(BeenCaculatedMapRect)
            //
            let heatmaprect = newPoint.MapRect
            let tMaxX = MKMapRectGetMaxX(heatmaprect)
            let tMaxY = MKMapRectGetMaxY(heatmaprect)
            let tMinX = MKMapRectGetMinX(heatmaprect)
            let tMinY = MKMapRectGetMinY(heatmaprect)
            MaxX = (tMaxX > MaxX) ? tMaxX : MaxX
            MaxY = (tMaxY > MaxY) ? tMaxY : MaxY
            MinX = (tMinX < MinX) ? tMinX : MinX
            MinY = (tMinY < MinY) ? tMinY : MinY
        }
        else
        {
            //First Time Caculate Fitst Point Only
            let heatmaprect = newPoint.MapRect
            MaxX = MKMapRectGetMaxX(heatmaprect)
            MaxY = MKMapRectGetMaxY(heatmaprect)
            MinX = MKMapRectGetMinX(heatmaprect)
            MinY = MKMapRectGetMinY(heatmaprect)
        }
        let rect = MKMapRectMake(MinX, MinY, MaxX - MinX, MaxY - MinY)
        CaculatedMapRect = rect
    }
    
    
}

class JDHeatFlatPointOverlay:JDHeatOverlay
{
    
    /**
     有新的點加進來 ->
     重新計算這個Overlay的涵蓋
     */
    override func caculateMaprect(newPoint:JDHeatPoint)
    {
        var MaxX:Double = -9999999999999
        var MaxY:Double = -9999999999999
        var MinX:Double = 99999999999999
        var MinY:Double = 99999999999999
        if let BeenCaculatedMapRect = CaculatedMapRect
        {
            //Not the First Time
            MaxX = MKMapRectGetMaxX(BeenCaculatedMapRect)
            MaxY = MKMapRectGetMaxY(BeenCaculatedMapRect)
            MinX = MKMapRectGetMinX(BeenCaculatedMapRect)
            MinY = MKMapRectGetMinY(BeenCaculatedMapRect)
            //
            let heatmaprect = newPoint.MapRect
            let tMaxX = MKMapRectGetMaxX(heatmaprect)
            let tMaxY = MKMapRectGetMaxY(heatmaprect)
            let tMinX = MKMapRectGetMinX(heatmaprect)
            let tMinY = MKMapRectGetMinY(heatmaprect)
            MaxX = (tMaxX > MaxX) ? tMaxX : MaxX
            MaxY = (tMaxY > MaxY) ? tMaxY : MaxY
            MinX = (tMinX < MinX) ? tMinX : MinX
            MinY = (tMinY < MinY) ? tMinY : MinY
        }
        else
        {
            //First Time Caculate Fitst Point Only
            let heatmaprect = newPoint.MapRect
            MaxX = MKMapRectGetMaxX(heatmaprect)
            MaxY = MKMapRectGetMaxY(heatmaprect)
            MinX = MKMapRectGetMinX(heatmaprect)
            MinY = MKMapRectGetMinY(heatmaprect)
        }
        let rect = MKMapRectMake(MinX, MinY, MaxX - MinX, MaxY - MinY)
        CaculatedMapRect = rect
    }
    
}
