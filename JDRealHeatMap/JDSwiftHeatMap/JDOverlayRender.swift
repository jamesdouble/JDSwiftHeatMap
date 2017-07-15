//
//  JDOverlayRender.swift
//  JDSwiftHeatMap
//
//  Created by 郭介騵 on 2017/6/19.
//  Copyright © 2017年 james12345. All rights reserved.
//

import Foundation
import MapKit

/**
 這個類別只需要知道畫圖相關的，不用記住任何點Data
 只要交給Producer製造還給他一個RowData
 */
class JDHeatOverlayRender:MKOverlayRenderer
{
    var Lastimage:CGImage?
    var Bitmapsize:IntSize = IntSize()
    var BitmapMemorySize:Int{
        return Bitmapsize.width * Bitmapsize.height * 4
    }
    var dataReference:[UTF8Char] = []
    var BytesPerRow:Int = 0
    
    init(heat overlay: JDHeatOverlay) {
        super.init(overlay: overlay)
        self.alpha = 0.6
    }

    func caculateRowFormData(maxHeat level:Int)->(data:[RowFormHeatData],rect:CGRect)?
    {
        return nil
    }
    
    /**
     drawMapRect is the real meat of this class; it defines how MapKit should render this view when given a specific MKMapRect, MKZoomScale, and the CGContextRef
     */
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        
        guard let overlay = overlay as? JDHeatOverlay else {
            return
        }
        //Last Time Created image have more resolution, so keep using it
        if let lastTimeMoreHighSolutionImgae = Lastimage
        {
            let mapCGRect = rect(for: overlay.boundingMapRect)
            context.draw(lastTimeMoreHighSolutionImgae, in: mapCGRect)
            return
        }
        else if(dataReference.count == 0 )
        {
            //The Data is not ready
            return
        }
        //
        func getHeatMapContextImage()->CGImage?
        {
            //More Detail
            func CreateContextOldWay()->CGImage?
            {
                func heatMapCGImage()->CGImage?
                {
                    let tempBuffer = malloc(BitmapMemorySize)
                    memcpy(tempBuffer, &dataReference, BytesPerRow * Bitmapsize.height)
                    defer
                    {
                        free(tempBuffer)
                    }
                    let rgbColorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()
                    let alphabitmapinfo = CGImageAlphaInfo.premultipliedLast.rawValue
                    if let contextlayer:CGContext = CGContext(data: tempBuffer, width: Bitmapsize.width, height: Bitmapsize.height, bitsPerComponent: 8, bytesPerRow: BytesPerRow, space: rgbColorSpace, bitmapInfo: alphabitmapinfo)
                    {
                        return contextlayer.makeImage()
                    }
                    return nil
                }
                
                if let cgimage = heatMapCGImage()
                {
                    let cgsize:CGSize = CGSize(width: Bitmapsize.width, height: Bitmapsize.height)
                    UIGraphicsBeginImageContext(cgsize)
                    if let contexts = UIGraphicsGetCurrentContext()
                    {
                        let rect = CGRect(origin: CGPoint.zero, size: cgsize)
                        contexts.draw(cgimage, in: rect)
                        return contexts.makeImage()
                    }
                }
                print("Create fail")
                return nil
            }
            let img = CreateContextOldWay()
            UIGraphicsEndImageContext()
            return img
        }
        if let tempimage = getHeatMapContextImage()
        {
            let mapCGRect = rect(for: overlay.boundingMapRect)
            Lastimage = tempimage
            context.clear(mapCGRect)
            self.dataReference.removeAll()
            context.draw(Lastimage!, in: mapCGRect)
        }
        else{
            print("cgcontext error")
        }
    }
}

class JDRadiusPointOverlayRender:JDHeatOverlayRender
{
    override func caculateRowFormData(maxHeat level:Int)->(data:[RowFormHeatData],rect:CGRect)?
    {
        guard let overlay = overlay as? JDHeatRadiusPointOverlay else {
            return nil
        }
        var rowformArr:[RowFormHeatData] = []
        //
        for heatpoint in overlay.HeatPointsArray
        {
            let mkmappoint = heatpoint.MidMapPoint
            let GlobalCGpoint:CGPoint = self.point(for: mkmappoint)
            let OverlayCGRect = rect(for: overlay.boundingMapRect)
            let localX = GlobalCGpoint.x - (OverlayCGRect.origin.x)
            let localY = GlobalCGpoint.y - (OverlayCGRect.origin.y)
            let loaclCGPoint = CGPoint(x: localX, y: localY)
            //
            let radiusinMKDistanse:Double = heatpoint.radiusInMKDistance
            let radiusmaprect = MKMapRect(origin: MKMapPoint.init(), size: MKMapSize(width: radiusinMKDistanse, height: radiusinMKDistanse))
            let radiusCGDistance = rect(for: radiusmaprect).width
            //
            let newRow:RowFormHeatData = RowFormHeatData(heatlevel: Float(heatpoint.HeatLevel) / Float(level), localCGpoint: loaclCGPoint, radius: radiusCGDistance)
            rowformArr.append(newRow)
        }
        let cgsize = rect(for: overlay.boundingMapRect)
        return (rect:cgsize,data:rowformArr)
    }
}

class JDFlatPointOverlayRender:JDHeatOverlayRender
{    
    override func caculateRowFormData(maxHeat level:Int)->(data:[RowFormHeatData],rect:CGRect)?
    {
        guard let FlatPointoverlay = overlay as? JDHeatFlatPointOverlay else {
            return nil
            
        }
        //
        var rowformArr:[RowFormHeatData] = []
        let OverlayCGRect:CGRect = rect(for: FlatPointoverlay.boundingMapRect)
        for heatpoint in FlatPointoverlay.HeatPointsArray
        {
            let mkmappoint = heatpoint.MidMapPoint
            let GlobalCGpoint:CGPoint = self.point(for: mkmappoint)
            
            let localX = GlobalCGpoint.x - (OverlayCGRect.origin.x)
            let localY = GlobalCGpoint.y - (OverlayCGRect.origin.y)
            let loaclCGPoint = CGPoint(x: localX, y: localY)
            //
            let radiusinMKDistanse:Double = heatpoint.radiusInMKDistance
            let radiusmaprect = MKMapRect(origin: MKMapPoint.init(), size: MKMapSize(width: radiusinMKDistanse, height: radiusinMKDistanse))
            let radiusCGDistance = rect(for: radiusmaprect).width
            //
            let newRow:RowFormHeatData = RowFormHeatData(heatlevel: Float(heatpoint.HeatLevel) / Float(level), localCGpoint: loaclCGPoint, radius: radiusCGDistance)
            rowformArr.append(newRow)
        }
        let cgsize = rect(for: overlay.boundingMapRect)
        return (rect:cgsize,data:rowformArr)
    }
}



