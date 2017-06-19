//
//  JDHMMissionController.swift
//  JDRealHeatMap
//
//  Created by 郭介騵 on 2017/6/16.
//  Copyright © 2017年 james12345. All rights reserved.
//

import Foundation
import MapKit

class JDHeatMapMissionController:NSObject
{
    typealias HeatRenderFor = [JDHeatOverlay:JDHeatOverlayRender]
    typealias ProducerFor = [JDHeatOverlayRender:JDRowDataProducer]
    //
    var Overlay_RenderPair:HeatRenderFor = [:]
    var Render_ProducerPair:ProducerFor = [:]
    var jdrealheatmap:JDRealHeatMap!
    var EstimateSizeInUIView:CGSize = CGSize.zero
    var Caculating:Bool = false
    var Datatype:DataPointType = .DotPoint
    var Mixertype:ColorMixerMode = .DistinctMode
    
    //
    var biggestRegion:MKMapRect = MKMapRect(origin: MKMapPoint(), size: MKMapSize(width: 0, height: 0))
    var MaxHeatLevelinWholeMap:Int = 0
    
    //
    let missionThread = DispatchQueue(label: "MissionThread")
    
    init(JDRealHeatMap map:JDRealHeatMap,datatype t:DataPointType,mode m:ColorMixerMode)
    {
        jdrealheatmap = map
        Datatype = t
        Mixertype = m
    }
    /**
        1.0 The User Change Data,so Call this Refresh to Recollect the Data
    **/
    func ExecuteRefreshMission()
    {
        /*
           1.1 Call the Delegate
         */
        guard let heatdelegate = jdrealheatmap.heatmapdelegate else {
            return
        }
        /*
           1.2 Collect New Data
        */
        let datacount = heatdelegate.heatmap(HeatPointCount: jdrealheatmap)
        var id:Int = 1
        for i in 0..<datacount
        {
            let coor = heatdelegate.heatmap(CoordinateFor: i)
            let heat = heatdelegate.heatmap(HeatLevelFor: i)
            MaxHeatLevelinWholeMap = (heat > MaxHeatLevelinWholeMap) ? heat : MaxHeatLevelinWholeMap
            let raius = heatdelegate.heatmap(RadiusInKMFor: i)
            let newHeatPoint:JDHeatPoint = JDHeatPoint(heat: heat, coor: coor, heatradius: raius)
            /* 
              1.3-1 type = Radius point  classification The Point
             */
            func CluseToOverlay()
            {
                for overlay in jdrealheatmap.overlays
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
                let render = JDHeatOverlayRender(heat: heatoverlay)
                self.Overlay_RenderPair[heatoverlay] = render
                jdrealheatmap.add(heatoverlay)
            }
            /*
             1.3-1 type = Radius point  classification The Point
             */
            func collectToOneOverlay()
            {
                
            }
            
            if(Datatype == .DotPoint)
            {
                collectToOneOverlay()
            }
            else if(Datatype == .RadiusPoint)
            {
                CluseToOverlay()
            }
        }
        /*
         1.3.2 Mapping First Round -> Update MapRect for overlay
         */
        for overlay in jdrealheatmap.overlays
        {
            if let jdheat = overlay as? JDHeatRadiusPointOverlay
            {
                jdheat.lauchBuffer()
            }
        }
        /*
         1.4  Reduce The Recover Overlay
         */
        func ReduceOverlay()
        {
            var ReduceBool:Bool = false
            repeat
            {
                ReduceBool = false
                for overlayX in jdrealheatmap.overlays
                {
                    guard let heatoverlayX = overlayX as? JDHeatRadiusPointOverlay
                    else{
                        break
                    }
                    for overlayY  in jdrealheatmap.overlays
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
                                heatoverlayX.lauchBuffer()
                                Overlay_RenderPair[heatoverlayY] = nil
                            }
                            jdrealheatmap.remove(overlayY)
                            break
                        }
                    }
                    if(ReduceBool) {break}
                }
            }while(ReduceBool)
        }
        ReduceOverlay()
        /*
            1.5 All Point have Been Classified to Overlay
            1.5.1 Caculate The Region where map should zoom
        */
        for overlay in jdrealheatmap.overlays
        {
            if let heatoverlay = overlay as? JDHeatOverlay
            {
                let heatoverlayRect = heatoverlay.boundingMapRect
                let size = heatoverlayRect.size.height * heatoverlayRect.size.width
                let biggestize = biggestRegion.size.height * biggestRegion.size.width
                biggestRegion = (size > biggestize) ? heatoverlayRect : biggestRegion
                //
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
        LastVisibleMapRect = jdrealheatmap.visibleMapRect
        func computing()
        {
            for overlay in jdrealheatmap.overlays
            {
                if let heatoverlay = overlay as? JDHeatOverlay
                {
                    func NotifyOverlayRender()
                    {
                        if let render = Overlay_RenderPair[heatoverlay]
                        {
                            if let SizeData = render.caculateRowFormData()
                            {
                                let rawdataproducer = JDRowDataProducer(size: (SizeData.rect.size), rowHeatData: (SizeData.data))
                                Render_ProducerPair[render] = rawdataproducer
                                //
                                let visibleMacRect = biggestRegion
                                let MapWidthInUIView = jdrealheatmap.frame.width
                                let scaleUIView_MapRect:Double = Double(MapWidthInUIView) / visibleMacRect.size.width
                                rawdataproducer.reduceSize(scales: scaleUIView_MapRect)
                                rawdataproducer.MaxHeatLevelInWholeMap = MaxHeatLevelinWholeMap
                            }
                            else
                            {
                                print("Size Error")
                            }
                        }
                    }
                    NotifyOverlayRender()
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
            for overlay in jdrealheatmap.overlays
            {
                if let heatoverlay = overlay as? JDHeatOverlay
                {
                    if let render = Overlay_RenderPair[heatoverlay]
                    {
                       if let producer = Render_ProducerPair[render]
                       {
                            producer.produceRowData()
                            render.Bitmapsize = producer.FitnessIntSize
                            render.BytesPerRow = producer.BytesPerRow
                            render.dataReference.append(contentsOf: producer.RowData)
                            producer.rowformdatas = []
                        }
                    }
                }
            }
            self.Caculating = false
            DispatchQueue.main.sync {
                jdrealheatmap.indicator?.stopAnimating()
                jdrealheatmap.setVisibleMapRect(biggestRegion, animated: true)
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
        let visibleMacRect = jdrealheatmap.visibleMapRect
        let RerenderNessceryCheck = LastVisibleMapRect.size.width / visibleMacRect.size.width
        //The map zoom doesn't change significant
        if(RerenderNessceryCheck > 0.7 && RerenderNessceryCheck < 1.66 ) {return}
        print(#function)
        LastVisibleMapRect = visibleMacRect
        jdrealheatmap.indicator?.startAnimating()
        //
        func compuing()
        {
            self.Caculating = true
            for overlay in jdrealheatmap.overlays
            {
                if let heatoverlay = overlay as? JDHeatOverlay
                {
                    func RecaculateOverlayRender()
                    {
                        if let render = Overlay_RenderPair[heatoverlay]
                        {
                            let MapWidthInUIView = jdrealheatmap.frame.width
                            let scaleUIView_MapRect:Double = Double(MapWidthInUIView) / visibleMacRect.size.width
                            if let rawdataproducer = Render_ProducerPair[render]
                            {
                                /*
                                    Exam the cgimage which draw in last time have more pixel?
                                */
                                let newWidth = Int(rawdataproducer.OriginSize.width * CGFloat(scaleUIView_MapRect) * 1.5)
                                if let lastimage = render.Lastimage
                                {
                                    if(lastimage.width > newWidth) { return }
                                    else { render.Lastimage = nil }
                                }
                                /*
                                    Recaculate new Size new Data to draw a new cgimage
                                    (Probably user zoom in.
                                */
                                rawdataproducer.reduceSize(scales: scaleUIView_MapRect) //Recaculate new FitnessSize
                                rawdataproducer.produceRowData()
                                render.Bitmapsize = rawdataproducer.FitnessIntSize
                                render.BytesPerRow = rawdataproducer.BytesPerRow
                                render.dataReference.removeAll()
                                render.dataReference.append(contentsOf: rawdataproducer.RowData)
                                render.setNeedsDisplay()
                                rawdataproducer.rowformdatas = []
                                print("Done Again")
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
                self.jdrealheatmap.indicator?.stopAnimating()
            })
            self.Caculating = false
        })
    }
}



























