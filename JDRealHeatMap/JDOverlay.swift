//
//  JDOverlay.swift
//  JDRealHeatMap
//
//  Created by 郭介騵 on 2017/6/14.
//  Copyright © 2017年 james12345. All rights reserved.
//

import UIKit
import MapKit

class JDHeatOverlay:NSObject, MKOverlay
{
    var HeatPointsArray:[JDHeatPoint] = []
    var CaculatedMapRect:MKMapRect?
    
    var coordinate: CLLocationCoordinate2D
    {
        var maxheat:Int = 0
        var maxpoint:JDHeatPoint = JDHeatPoint()
        
        for point in HeatPointsArray
        {
            if(point.HeatLevel > maxheat)
            {
                maxheat = point.HeatLevel
                maxpoint = point
            }
        }
        return maxpoint.coordinate
    }
    /**
     If you project the curved surface of the globe onto a flat surface, what you get is a two-dimensional version of a map where longitude lines appear to be parallel. Such maps are often used to show the entire surface of the globe all at once. An MKMapRect data structure represents a rectangular area as seen on this two-dimensional map.
     **/
    var boundingMapRect: MKMapRect
    {
        guard let BeenCaculatedMapRect = CaculatedMapRect else {
            caculateMaprect()
            return CaculatedMapRect!
        }
        return BeenCaculatedMapRect
    }
    
    func caculateMaprect()
    {
        let mappoint = MKMapPointForCoordinate(coordinate)
        let rect = MKMapRectMake(mappoint.x, mappoint.y, 2000000, 2000000)
        CaculatedMapRect = rect
    }

    init(first Heatpoint:JDHeatPoint)
    {
        print(#function)
        HeatPointsArray.append(Heatpoint)
    }
    
}

class JDHeatOverlayRender:MKOverlayRenderer
{
    var rawdataproducer:JDRowDataProducer?
    var transferCGRect:CGRect{
        return rect(for: overlay.boundingMapRect)
    }
    var TransferCGPoint:[CGPoint] = []
   
    init(heat overlay: JDHeatOverlay) {
        super.init(overlay: overlay)
        self.alpha = 0.7
        //
        func caculateRowFormData()
        {
            var rowformArr:[RowFormHeatData] = []
            for heatpoint in overlay.HeatPointsArray
            {
                let mkmappoint = MKMapPointForCoordinate(heatpoint.coordinate)
                let GlobalCGpoint:CGPoint = self.point(for: mkmappoint)
                let localX = GlobalCGpoint.x - (transferCGRect.origin.x)
                let localY = GlobalCGpoint.y - (transferCGRect.origin.y)
                let loaclCGPoint = CGPoint(x: localX, y: localY)
                //
                let radiusinMKDistanse:Double = heatpoint.radiusInMKDistance
                let radiusmaprect = MKMapRect(origin: MKMapPoint.init(), size: MKMapSize(width: radiusinMKDistanse, height: radiusinMKDistanse))
                let radiusCGDistance = rect(for: radiusmaprect).width
                let newRow:RowFormHeatData = RowFormHeatData(heatlevel: heatpoint.HeatLevel, localCGpoint: loaclCGPoint, radius: radiusCGDistance)
                rowformArr.append(newRow)
            }
            let cgsize = rect(for: overlay.boundingMapRect)
            rawdataproducer = JDRowDataProducer(size: cgsize.size, rowHeatData: rowformArr)
        }
        caculateRowFormData()
    }
    
    /**
     drawMapRect is the real meat of this class; it defines how MapKit should render this view when given a specific MKMapRect, MKZoomScale, and the CGContextRef
     */
    
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let mapCGRect = transferCGRect
        let midPoint:CGPoint = CGPoint(x: mapCGRect.midX, y: mapCGRect.midY)
        
        context.saveGState()
        context.setBlendMode(CGBlendMode.exclusion)
        let colorspace:CGColorSpace = CGColorSpaceCreateDeviceRGB()
        func getHeatGredient()->CGGradient
        {
            let colors:[UIColor] = [UIColor.red,UIColor.white,UIColor.clear]
            let cgcolors:[CGColor] = colors.map { (uicolor) -> CGColor in
                
                return uicolor.cgColor
            }
            let gredientredf:CGGradient = CGGradient(colorsSpace: colorspace, colors: cgcolors as CFArray, locations: nil)!
            return gredientredf
        }
        func getGrediantContextImage()->CGImage?
        {
            if(context.alphaInfo.rawValue == 0)
            {
                context.drawRadialGradient(getHeatGredient(), startCenter: midPoint, startRadius: mapCGRect.width / 4, endCenter: midPoint, endRadius: mapCGRect.width / 2, options: .drawsBeforeStartLocation)
                return context.makeImage()
            }
            else
            {
                func CreateContextnewWay()->CGImage?
                {
                    let tempsize = CGSize(width: (mapCGRect.width)/40000, height: (mapCGRect.height)/40000)
                    UIGraphicsBeginImageContextWithOptions(tempsize, false, 1.0)
                    let graphicmidPoint:CGPoint = CGPoint(x: tempsize.width / 2, y: tempsize.height / 2)
                    if let contextlayer = UIGraphicsGetCurrentContext()
                    {
                        
                        contextlayer.drawRadialGradient(getHeatGredient(), startCenter: graphicmidPoint, startRadius: tempsize.width / 4, endCenter: graphicmidPoint, endRadius: tempsize.width / 2, options: .drawsBeforeStartLocation)
                        return contextlayer.makeImage()
                    }
                    return nil
                }
                //More Detail
                func CreateContextOldWay()->CGImage?
                {
                    guard let producer = rawdataproducer else {
                        return nil
                    }
                    let rgbColorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()
                    let alphabitmapinfo = CGImageAlphaInfo.premultipliedLast.rawValue
                    if let contextlayer:CGContext = CGContext(data: &rawdataproducer!.RowData, width: producer.cgsize.width, height: producer.cgsize.height, bitsPerComponent: 8, bytesPerRow: producer.BytesPerRow, space: rgbColorSpace, bitmapInfo: alphabitmapinfo)
                    {
                        return contextlayer.makeImage()
                    }
                    
                    print("alpha fail")
                    return nil
                }
                
                if let oldWayCGimage = CreateContextOldWay()
                {
                    UIGraphicsPopContext()
                    return oldWayCGimage
                }
                else if let newWayCGimage = CreateContextnewWay()
                {
                    UIGraphicsEndImageContext()
                    UIGraphicsPopContext()
                    return newWayCGimage
                }
                return nil
            }
        }
        
        
        if let mask = getGrediantContextImage()
        {
            context.draw(mask, in: mapCGRect)
            //context.clip(to: mapCGRect, mask: mask)
        }
    }
    
}

