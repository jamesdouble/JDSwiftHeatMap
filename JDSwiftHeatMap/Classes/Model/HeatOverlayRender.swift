//
//  HeatOverlayRender.swift
//  JDSwiftHeatMap
//
//  Created by JamesDouble on 2019/10/24.
//

import Foundation
import MapKit
import RxSwift


/// This Class Only Needs to know graphic stuff.
/// No need to know other map data.
class HeatOverlayRender: MKOverlayRenderer {
    
    var cacheImage: CGImage?
    var dataProducer: RowDataProducer?
    //
    var bitmapSize: IntSize { return self.dataProducer?.fitnessIntSize ?? .zero }
    var BitmapMemorySize: Int{ return bitmapSize.width * bitmapSize.height * 4 }
    var dataReference: [UTF8Char] { return self.dataProducer?.rowData ?? [] }
    var BytesPerRow: Int { return self.dataProducer?.BytesPerRow ?? 0 }
    
    override init(overlay: MKOverlay) {
        super.init(overlay: overlay)
        self.alpha = 0.6
    }
    
    func caculateRowFormData(maxHeat level: Int) -> Result<([RowFormHeatData], CGRect), MissonError> {
        return .success(([], CGRect(origin: .zero, size: .zero)))
    }
    
    /**
     drawMapRect is the real meat of this class; it defines how MapKit should render this view when given a specific MKMapRect, MKZoomScale, and the CGContextRef
     */
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        //Last Time Created image have more resolution, so keep using it
        if let lastTimeMoreHighSolutionImgae = self.cacheImage
        {
            let mapCGRect = self.rect(for: overlay.boundingMapRect)
            context.draw(lastTimeMoreHighSolutionImgae, in: mapCGRect)
            return
        }
        guard !dataReference.isEmpty else { return }    //data is not ready
        guard let contextImg = self.drawContextImage() else { return }
        
        let mapCGRect = rect(for: overlay.boundingMapRect)
        self.cacheImage = contextImg
        context.clear(mapCGRect)
        guard let cache = self.cacheImage else { return }
        context.draw(cache, in: mapCGRect)
    }
    
    private func drawContextImage() -> CGImage? {
        if let cgImage = self.getHeatMapCGImage() {
            let cgsize:CGSize = CGSize(width: bitmapSize.width, height: bitmapSize.height)
            UIGraphicsBeginImageContext(cgsize)
            if let contexts = UIGraphicsGetCurrentContext()
            {
                let rect = CGRect(origin: CGPoint.zero, size: cgsize)
                contexts.draw(cgImage, in: rect)
                return contexts.makeImage()
            }
        }
        return nil
    }
}

extension HeatOverlayRender {
    
    private func getHeatMapCGImage() -> CGImage? {
        let tempBuffer = malloc(BitmapMemorySize)
        var dataRefer = self.dataReference
        memcpy(tempBuffer, &dataRefer, BytesPerRow * bitmapSize.height)
        defer
        {
            free(tempBuffer)
        }
        let rgbColorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let alphabitmapinfo = CGImageAlphaInfo.premultipliedLast.rawValue
        if let contextlayer:CGContext = CGContext(data: tempBuffer, width: bitmapSize.width, height: bitmapSize.height, bitsPerComponent: 8, bytesPerRow: BytesPerRow, space: rgbColorSpace, bitmapInfo: alphabitmapinfo)
        {
            return contextlayer.makeImage()
        }
        return nil
    }
    
}

class RadiusHeatOvelayRender: HeatOverlayRender {
    
    init(overlay: HeatRadiusPointOverlay) {
        super.init(overlay: overlay)
    }
    
    override func caculateRowFormData(maxHeat level: Int) -> Result<([RowFormHeatData], CGRect), MissonError> {
        guard let radiusOvelay = self.overlay as? HeatRadiusPointOverlay else { return .failure(MissonError.misplaceOverlay) }
        let rowFormDatas = radiusOvelay.heatpoints.map { (heatpoint) -> RowFormHeatData in
            let mkmappoint = heatpoint.midMapPoint
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
            return newRow
        }
        let cgSize = self.rect(for: radiusOvelay.boundingMapRect)
        return .success((rowFormDatas, cgSize))
    }
}

class FlatHeatOverlayRender: HeatOverlayRender {
    
    init(overlay: HeatFlatPointOverlay) {
        super.init(overlay: overlay)
    }
    
    override func caculateRowFormData(maxHeat level: Int) -> Result<([RowFormHeatData], CGRect), MissonError> {
        guard let flatOverlay = self.overlay as? HeatFlatPointOverlay else { return .failure(MissonError.misplaceOverlay) }
        let overlayCGRect:CGRect = rect(for: flatOverlay.boundingMapRect)
        let rowFormDatas = flatOverlay.heatpoints.map { (heatpoint) -> RowFormHeatData in
            let mkmappoint = heatpoint.midMapPoint
            let GlobalCGpoint:CGPoint = self.point(for: mkmappoint)
            //
            let localX = GlobalCGpoint.x - (overlayCGRect.origin.x)
            let localY = GlobalCGpoint.y - (overlayCGRect.origin.y)
            let loaclCGPoint = CGPoint(x: localX, y: localY)
            //
            let radiusinMKDistanse:Double = heatpoint.radiusInMKDistance
            let radiusmaprect = MKMapRect(origin: MKMapPoint.init(), size: MKMapSize(width: radiusinMKDistanse, height: radiusinMKDistanse))
            let radiusCGDistance = rect(for: radiusmaprect).width
            //
            let newRow:RowFormHeatData = RowFormHeatData(heatlevel: Float(heatpoint.HeatLevel) / Float(level), localCGpoint: loaclCGPoint, radius: radiusCGDistance)
            return newRow
        }
        let cgsize = self.rect(for: flatOverlay.boundingMapRect)
        return .success((rowFormDatas, cgsize))
    }
    
}
