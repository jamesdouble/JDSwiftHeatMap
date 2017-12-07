//
//  JDHMMissionController.swift
//  JDSwiftHeatMap
//
//  Created by 郭介騵 on 2017/6/16.
//  Copyright © 2017年 james12345. All rights reserved.
//

import Foundation
import MapKit

class JDHeatMapMissionController:NSObject
{
    typealias ProducerFor = [JDHeatOverlayRender:JDRowDataProducer]
    //
    var Render_ProducerPair:ProducerFor = [:]
    weak var jdswiftheatmap:JDSwiftHeatMap!
    var Caculating:Bool = false
    var Datatype:DataPointType = .RadiusPoint
    let MapWidthInUIView:CGFloat
    //
    var biggestRegion:MKMapRect = MKMapRect(origin: MKMapPoint(), size: MKMapSize(width: 0, height: 0))
    var MaxHeatLevelinWholeMap:Int = 0
    //
    let missionThread = DispatchQueue(label: "MissionThread")
    
    init(JDSwiftHeatMap map:JDSwiftHeatMap,datatype t:DataPointType,mode m:ColorMixerMode)
    {
        jdswiftheatmap = map
        Datatype = t
        MapWidthInUIView  = map.frame.width
        JDRowDataProducer.theColorMixer.mixerMode = m
    }
    
    func renderFor(overlay:JDHeatOverlay)->JDHeatOverlayRender?
    {
        let render = self.jdswiftheatmap.renderer(for: overlay)
        let heartrender = render as? JDHeatOverlayRender
        return heartrender
    }
    
    /**
        1.0 The User Change Data,so Call this Refresh to Recollect the Data
    **/
    func ExecuteRefreshMission()
    {
        Render_ProducerPair = [:]
        /*
           1.1 Call the Delegate
         */
        guard let heatdelegate = jdswiftheatmap.heatmapdelegate else {
            return
        }
        /*
           1.2 Collect New Data
        */
        jdswiftheatmap.removeOverlays(jdswiftheatmap.overlays)
        let datacount = heatdelegate.heatmap(HeatPointCount: jdswiftheatmap)
        var id:Int = 1
        for i in 0..<datacount
        {
            let coor = heatdelegate.heatmap(CoordinateFor: i)
            let heat = heatdelegate.heatmap(HeatLevelFor: i)
            MaxHeatLevelinWholeMap = (heat > MaxHeatLevelinWholeMap) ? heat : MaxHeatLevelinWholeMap
            let raius = heatdelegate.heatmap(RadiusInKMFor: i)
            let newHeatPoint:JDHeatPoint = JDHeatPoint(heat: heat, coor: coor, heatradius: raius)
            if(Datatype == .FlatPoint)
            {
                /*
                 1.3-1 type = Flat point  there will Only be one overlay
                 */
                func collectToOneOverlay()
                {
                    if(jdswiftheatmap.overlays.count == 1) ///Haved Overlay
                    {
                        if let Flatoverlay = jdswiftheatmap.overlays.first as? JDHeatFlatPointOverlay
                        {
                            Flatoverlay.insertHeatpoint(input: newHeatPoint)
                        }
                        return
                    }
                    else if(jdswiftheatmap.overlays.count == 0) ///First Overlay
                    {
                        let BigOverlay = JDHeatFlatPointOverlay(first: newHeatPoint)
                        jdswiftheatmap.add(BigOverlay, level: MKOverlayLevel.aboveLabels)
                        return
                    }
                }
                collectToOneOverlay()
            }
            else if(Datatype == .RadiusPoint)
            {
                /*
                 1.3-1 type = Radius point  classification The Point
                 */
                func CluseToOverlay()
                {
                    for overlay in jdswiftheatmap.overlays
                    {
                        let overlaymaprect = overlay.boundingMapRect
                        //Cluse in Old Overlay
                        if(MKMapRectIntersectsRect(overlaymaprect, newHeatPoint.MapRect))
                        {
                            if let heatoverlay = overlay as? JDHeatRadiusPointOverlay
                            {
                                heatoverlay.insertHeatpoint(input: newHeatPoint)
                                return
                            }
                        }
                    }
                    //Create New Overlay,OverlayRender會一起創造
                    let heatoverlay = JDHeatRadiusPointOverlay(first: newHeatPoint)
                    jdswiftheatmap.add(heatoverlay, level: MKOverlayLevel.aboveLabels)
                }
                CluseToOverlay()
            }
        }
        
        if(MaxHeatLevelinWholeMap == 0) { fatalError("Max Heat level should not be 0") }
        
        /*
         1.3.3  Reduce The Recover Overlay
         */
        func ReduceOverlay(){
            var ReduceBool:Bool = false
            repeat
            {
                ReduceBool = false
                for overlayX in jdswiftheatmap.overlays
                {
                    guard let heatoverlayX = overlayX as? JDHeatRadiusPointOverlay
                        else{
                            break
                    }
                    for overlayY  in jdswiftheatmap.overlays
                    {
                        if(overlayY.isEqual(overlayX)){continue}
                        let overlayXmaprect = overlayX.boundingMapRect
                        let overlayYmaprect = overlayY.boundingMapRect
                        if(MKMapRectIntersectsRect(overlayXmaprect, overlayYmaprect))
                        {
                            ReduceBool = true
                            if let heatoverlayY = overlayY as? JDHeatRadiusPointOverlay
                            {
                                for point in heatoverlayY.HeatPointsArray
                                {
                                    heatoverlayX.insertHeatpoint(input: point)
                                }
                            }
                            jdswiftheatmap.remove(overlayY)
                            break
                        }
                    }
                    if(ReduceBool) {break}
                }
            }while(ReduceBool)
        }
        ReduceOverlay()
        
        /*
            1.4 All Point have Been Classified to Overlay
            1.4.1 Caculate The Region where map should zoom later
        */
        for overlay in jdswiftheatmap.overlays
        {
            if let heatoverlay = overlay as? JDHeatRadiusPointOverlay
            {
                let heatoverlayRect = heatoverlay.boundingMapRect
                let size = heatoverlayRect.size.height * heatoverlayRect.size.width
                let biggestize = biggestRegion.size.height * biggestRegion.size.width
                biggestRegion = (size > biggestize) ? heatoverlayRect : biggestRegion
                //
            }
            else if let heatoverlay = overlay as? JDHeatFlatPointOverlay
            {
               biggestRegion = heatoverlay.boundingMapRect
            }
        }
        StartComputRowFormData()
    }
    /**
     2.0 Caculate HeatPoint data to a CGFormat
     **/
    func StartComputRowFormData()
    {
        print(#function)
        LastVisibleMapRect = jdswiftheatmap.visibleMapRect
        func computing()
        {
            func OverlayRender(heatoverlay:JDHeatOverlay)
            {
                if let render = renderFor(overlay: heatoverlay)
                {
                    if let CaculatedRowFormData = render.caculateRowFormData(maxHeat: MaxHeatLevelinWholeMap)
                    {
                        var rawdataproducer:JDRowDataProducer!
                        let OverlayCGRect = CaculatedRowFormData.rect
                        let LocalFormData = CaculatedRowFormData.data
                        if(Datatype == .RadiusPoint)
                        {
                            rawdataproducer  = JDRadiusPointRowDataProducer(size: (OverlayCGRect.size), rowHeatData: LocalFormData)
                        }
                        else if(Datatype == .FlatPoint)
                        {
                            rawdataproducer = JDFlatPointRowDataProducer(size: (OverlayCGRect.size), rowHeatData: LocalFormData)
                        }
                        Render_ProducerPair[render] = rawdataproducer
                        //
                        let visibleMacRect = biggestRegion 
                        
                        let scaleUIView_MapRect:Double = Double(MapWidthInUIView) / visibleMacRect.size.width
                        rawdataproducer?.reduceSize(scales: scaleUIView_MapRect)
                        return
                    }
                }
                //Nil in iphone 8 & ios11
               // fatalError("RenderPair may be wrong")
            }
            //
            if(Datatype == .RadiusPoint)
            {
                for overlay in jdswiftheatmap.overlays
                {
                    if let heatoverlay = overlay as? JDHeatRadiusPointOverlay
                    {
                        OverlayRender(heatoverlay: heatoverlay)
                    }
                }
            }
            else if(Datatype == .FlatPoint)
            {
                if(jdswiftheatmap.overlays.count == 1)
                {
                    if let Flatoverlay = jdswiftheatmap.overlays[0] as? JDHeatFlatPointOverlay
                    {
                        OverlayRender(heatoverlay: Flatoverlay)
                    }
                }
            }
        }
        missionThread.async(execute: {
            computing()
            self.caculateStart()
        })
    }
    /**
     3.0 Most Take time task
     **/
    func caculateStart()
    {
        print(#function)
        self.Caculating = true
        func computing()
        {
            for overlay in jdswiftheatmap.overlays
            {
                if let heatoverlay = overlay as? JDHeatOverlay
                {
                    if let render = renderFor(overlay: heatoverlay)
                    {
                       if let producer = Render_ProducerPair[render]
                       {
                            producer.produceRowData()
                            render.Bitmapsize = producer.FitnessIntSize
                            render.BytesPerRow = producer.BytesPerRow
                            render.dataReference.append(contentsOf: producer.RowData)
                            render.setNeedsDisplay()
                            producer.rowformdatas = []
                        }
                    }
                }
            }
            self.Caculating = false
            DispatchQueue.main.sync {
                if(jdswiftheatmap.showindicator)
                {
                    jdswiftheatmap.indicator?.stopAnimating()
                }
                let ZoomOrigin = MKMapPoint(x: biggestRegion.origin.x - biggestRegion.size.width * 2, y: biggestRegion.origin.y - biggestRegion.size.height * 2)
                let zoomoutregion = MKMapRect(origin: ZoomOrigin, size: MKMapSize(width: biggestRegion.size.width * 4, height: biggestRegion.size.height * 4))
                jdswiftheatmap.setVisibleMapRect(zoomoutregion, animated: true)
            }
        }
        computing()
    }
    
    var LastVisibleMapRect:MKMapRect = MKMapRect.init()
}

extension JDHeatMapMissionController
{
    func mapViewWillStartRenderingMap()
    {
        if(Caculating) {return} //If last time rendering not finishe yet...
        let visibleMacRect = jdswiftheatmap.visibleMapRect
        if(visibleMacRect.size.width == biggestRegion.size.width &&
            visibleMacRect.origin.x == biggestRegion.origin.x &&
            visibleMacRect.origin.y == biggestRegion.origin.y) {return}
        let RerenderNessceryCheck = LastVisibleMapRect.size.width / visibleMacRect.size.width
        //The map zoom doesn't change significant
        if(RerenderNessceryCheck > 0.7 && RerenderNessceryCheck < 1.66 ) {return}
        print(#function)
        self.Caculating = true
        LastVisibleMapRect = visibleMacRect
        if(jdswiftheatmap.showindicator)
        {
            jdswiftheatmap.indicator?.startAnimating()
        }
        //
        func compuing()
        {
            for overlay in jdswiftheatmap.overlays
            {
                if let heatoverlay = overlay as? JDHeatOverlay
                {
                    func RecaculateOverlayRender()
                    {
                        if let render = renderFor(overlay: heatoverlay)
                        {
                            let scaleUIView_MapRect:Double = Double(MapWidthInUIView) / visibleMacRect.size.width
                            if let rawdataproducer = Render_ProducerPair[render]
                            {
                                /*
                                    Exam the cgimage which draw in last time have more pixel?
                                */
                                let newWidth = Int(rawdataproducer.OriginCGSize.width * CGFloat(scaleUIView_MapRect) * 1.5)
                                if let lastimage = render.Lastimage
                                {
                                    if(lastimage.width > newWidth) { return }
                                    else { render.Lastimage = nil } //Make it can draw
                                }
                                /*
                                    Recaculate new Size new Data to draw a new cgimage
                                    (Probably user zoom in.
                                */
                                rawdataproducer.reduceSize(scales: scaleUIView_MapRect) //Recaculate new FitnessSize
                                rawdataproducer.produceRowData()
                                render.Bitmapsize = rawdataproducer.FitnessIntSize
                                render.BytesPerRow = rawdataproducer.BytesPerRow
                                render.dataReference.append(contentsOf: rawdataproducer.RowData)
                                render.setNeedsDisplay()
                                rawdataproducer.rowformdatas = []
                            }
                        }
                    }
                    RecaculateOverlayRender()
                }
            }
        }
        //
        missionThread.async(execute: {
            compuing()
            DispatchQueue.main.sync(execute: {
                if(self.jdswiftheatmap.showindicator)
                {
                    self.jdswiftheatmap.indicator?.stopAnimating()
                }
                self.Caculating = false
            })
        })
    }
}



























