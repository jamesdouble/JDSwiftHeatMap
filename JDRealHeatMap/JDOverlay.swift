//
//  JDOverlay.swift
//  JDRealHeatMap
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
    var EstimatedScale:Double = 0.0
    
    var coordinate: CLLocationCoordinate2D
    {
        return HeatPointsArray[0].coordinate
    }
    /*
     If you project the curved surface of the globe onto a flat surface, what you get is a two-dimensional version of a map where longitude lines appear to be parallel. Such maps are often used to show the entire surface of the globe all at once. An MKMapRect data structure represents a rectangular area as seen on this two-dimensional map.
     **/
    var boundingMapRect: MKMapRect
    {
        guard let BeenCaculatedMapRect = CaculatedMapRect else {
            return MKMapRect()
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
        var MaxX:Double = 0
        var MaxY:Double = 0
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
    
    /**
     新的點進來先放在Buffer裡，等CluseOverlay結束一並計算
     */
    func insertHeatpoint(input:JDHeatPoint)
    {
        NewHeatPointBuffer.append(input)
    }
    
    /**
     一個Refresh，執行一次，
     這樣不用讓Render裡的caculateRowFormData執行多次
     */
    func lauchBuffer()
    {
        for newpoint in NewHeatPointBuffer
        {
            caculateMaprect(newPoint: newpoint)
            HeatPointsArray.append(newpoint)
        }
        NewHeatPointBuffer = []
    }
}

class JDHeatDotPointOverlay:JDHeatOverlay
{
    /**
     有新的點加進來 ->
     重新計算這個Overlay的涵蓋
     */
    override func caculateMaprect(newPoint:JDHeatPoint)
    {
        
    }
}
