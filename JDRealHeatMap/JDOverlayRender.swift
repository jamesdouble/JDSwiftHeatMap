//
//  JDOverlayRender.swift
//  JDRealHeatMap
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
    //var Lastimage:CGImage? = UIImage(named: "13607804_1138031072920408_645704923_n")?.cgImage
    var Lastimage:CGImage?
    var CanDraw:Bool{
        get{
            return (dataReference.count != 0)
        }
    }
    var Bitmapsize:IntSize = IntSize()
    var dataReference:[UTF8Char] = []
    var BytesPerRow:Int = 0
    
    init(heat overlay: JDHeatOverlay) {
        super.init(overlay: overlay)
        self.alpha = 0.7
    }
    
    func caculateRowFormData()->(data:[RowFormHeatData],rect:CGRect)?
    {
        guard let overlay = overlay as? JDHeatOverlay else {
            return nil
        }
        var rowformArr:[RowFormHeatData] = []
        //
        for heatpoint in overlay.HeatPointsArray
        {
            let mkmappoint = MKMapPointForCoordinate(heatpoint.coordinate)
            let GlobalCGpoint:CGPoint = self.point(for: mkmappoint)
            let localX = GlobalCGpoint.x - (rect(for: overlay.boundingMapRect).origin.x)
            let localY = GlobalCGpoint.y - (rect(for: overlay.boundingMapRect).origin.y)
            let loaclCGPoint = CGPoint(x: localX, y: localY)
            //
            let radiusinMKDistanse:Double = heatpoint.radiusInMKDistance
            let radiusmaprect = MKMapRect(origin: MKMapPoint.init(), size: MKMapSize(width: radiusinMKDistanse, height: radiusinMKDistanse))
            let radiusCGDistance = rect(for: radiusmaprect).width
            //
            let newRow:RowFormHeatData = RowFormHeatData(heatlevel: Float(heatpoint.HeatLevel), localCGpoint: loaclCGPoint, radius: radiusCGDistance)
            rowformArr.append(newRow)
        }
        let cgsize = rect(for: overlay.boundingMapRect)
        return (rect:cgsize,data:rowformArr)
    }
    
    /**
     drawMapRect is the real meat of this class; it defines how MapKit should render this view when given a specific MKMapRect, MKZoomScale, and the CGContextRef
     */
    override func canDraw(_ mapRect: MKMapRect, zoomScale: MKZoomScale) -> Bool {
        return CanDraw
    }
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        if(!CanDraw)
        {
            return
        }
        guard let overlay = overlay as? JDHeatOverlay else {
            return
        }
        if let lastTimeMoreHighSolutionImgae = Lastimage
        {
            let mapCGRect = rect(for: overlay.boundingMapRect)
            context.scaleBy(x: 1, y: -1.0)
            context.translateBy(x: 0.0, y: -mapCGRect.size.height)
            context.draw(lastTimeMoreHighSolutionImgae, in: mapCGRect)
            return
        }
        //
        func getGrediantContextImage()->CGImage?
        {
            //More Detail
            func CreateContextOldWay()->CGImage?
            {
                let tempBuffer = malloc(Bitmapsize.width * Bitmapsize.height * 4)
                memcpy(tempBuffer, &dataReference, BytesPerRow * Bitmapsize.height)
                defer {
                    free(tempBuffer)
                }
                let rgbColorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()
                let alphabitmapinfo = CGImageAlphaInfo.premultipliedLast.rawValue
                if let contextlayer:CGContext = CGContext(data: tempBuffer, width: Bitmapsize.width, height: Bitmapsize.height, bitsPerComponent: 8, bytesPerRow: BytesPerRow, space: rgbColorSpace, bitmapInfo: alphabitmapinfo)
                {
                    
                    return contextlayer.makeImage()
                }
                print("Create fail")
                return nil
            }
            if let oldWayCGimage = CreateContextOldWay()
            {
                return oldWayCGimage
            }
            return nil
        }
        if let tempimage = getGrediantContextImage()
        {
            let mapCGRect = rect(for: overlay.boundingMapRect)
            Lastimage = tempimage
            context.scaleBy(x: 1, y: -1.0)
            context.translateBy(x: 0.0, y: -mapCGRect.size.height)
            context.draw(tempimage, in: mapCGRect)
        }
    }
    
}

