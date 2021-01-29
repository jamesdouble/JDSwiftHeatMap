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
        let midMKPoint = MKMapPoint(x: boundingMapRect.midX, y: boundingMapRect.midY)
        return midMKPoint.coordinate
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
            MaxX = BeenCaculatedMapRect.maxX
            MaxY = BeenCaculatedMapRect.maxY
            MinX = BeenCaculatedMapRect.minX
            MinY = BeenCaculatedMapRect.minY
            //
            let heatmaprect = newPoint.MapRect
            let tMaxX = heatmaprect.maxX
            let tMaxY = heatmaprect.maxY
            let tMinX = heatmaprect.minX
            let tMinY = heatmaprect.minY
            MaxX = (tMaxX > MaxX) ? tMaxX : MaxX
            MaxY = (tMaxY > MaxY) ? tMaxY : MaxY
            MinX = (tMinX < MinX) ? tMinX : MinX
            MinY = (tMinY < MinY) ? tMinY : MinY
        }
        else
        {
            //First Time Caculate Fitst Point Only
            let heatmaprect = newPoint.MapRect
            MaxX = heatmaprect.maxX
            MaxY = heatmaprect.maxY
            MinX = heatmaprect.minX
            MinY = heatmaprect.minY
        }
        let rect = MKMapRect.init(x: MinX, y: MinY, width: MaxX - MinX, height: MaxY - MinY)
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
            MaxX = BeenCaculatedMapRect.maxX
            MaxY = BeenCaculatedMapRect.maxY
            MinX = BeenCaculatedMapRect.minX
            MinY = BeenCaculatedMapRect.minY
            //
            let heatmaprect = newPoint.MapRect
            let tMaxX = heatmaprect.maxX
            let tMaxY = heatmaprect.maxY
            let tMinX = heatmaprect.minX
            let tMinY = heatmaprect.minY
            MaxX = (tMaxX > MaxX) ? tMaxX : MaxX
            MaxY = (tMaxY > MaxY) ? tMaxY : MaxY
            MinX = (tMinX < MinX) ? tMinX : MinX
            MinY = (tMinY < MinY) ? tMinY : MinY
        }
        else
        {
            //First Time Caculate Fitst Point Only
            let heatmaprect = newPoint.MapRect
            MaxX = heatmaprect.maxX
            MaxY = heatmaprect.maxY
            MinX = heatmaprect.minX
            MinY = heatmaprect.minY
        }
        let rect = MKMapRect.init(x: MinX, y: MinY, width: MaxX - MinX, height: MaxY - MinY)
        CaculatedMapRect = rect
    }
    
}
