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
    //
    var biggestRegion:MKMapRect = MKMapRect(origin: MKMapPoint(), size: MKMapSize(width: 0, height: 0))
    var MaxHeatLevelinWholeMap:Int = 0
    //
    let missionThread = DispatchQueue(label: "MissionThread")
    
    init(JDRealHeatMap map:JDRealHeatMap)
    {
        jdrealheatmap = map
    }
    /**
        1.0 The User Change Data,so Call this Refresh to Recollect the Data
    **/
    func ExecuteRefreshMission()
    {
       
        var HeatPointsBuffer:[JDHeatPoint] = []
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
            HeatPointsBuffer.append(newHeatPoint)
            /* 
              1.3  classification The Point
             */
            
            func CluseToOverlay()
            {
                for overlay in jdrealheatmap.overlays
                {
                    let overlaymaprect = overlay.boundingMapRect
                    //Cluse in Old Overlay
                    if(MKMapRectIntersectsRect(overlaymaprect, newHeatPoint.MapRect))
                    {
                        if let heatoverlay = overlay as? JDHeatOverlay
                        {
                            heatoverlay.insertHeatpoint(input: newHeatPoint)
                            return
                        }
                    }
                }
                //Create New Overlay,OverlayRender會一起創造
                let heatoverlay = JDHeatOverlay(first: newHeatPoint)
                heatoverlay.TestingID = id
                id += 1
                let render = JDHeatOverlayRender(heat: heatoverlay)
                self.Overlay_RenderPair[heatoverlay] = render
                jdrealheatmap.add(heatoverlay)
            }
            CluseToOverlay()
        }
        /*
         1.3.1 Mapping First Round -> Update MapRect for overlay
         */
        for overlay in jdrealheatmap.overlays
        {
            if let jdheat = overlay as? JDHeatOverlay
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
                print("repeat")
                ReduceBool = false
                for overlayX in jdrealheatmap.overlays
                {
                    guard let heatoverlayX = overlayX as? JDHeatOverlay
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
                            if let heatoverlayY = overlayY as? JDHeatOverlay
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
        func computing()
        {
            for overlay in jdrealheatmap.overlays
            {
                if let heatoverlay = overlay as? JDHeatOverlay
                {
                    if let render = Overlay_RenderPair[heatoverlay]
                    {
                        
                        let producer = Render_ProducerPair[render]
                        producer?.produceRowData()
                        render.Bitmapsize = (producer?.cgsize)!
                        render.BytesPerRow = (producer?.BytesPerRow)!
                        render.dataReference = producer?.RowData
                        render.CanDraw = true
                        print("Done")
                    }
                }
            }
        }
        computing()
        DispatchQueue.main.sync { 
            jdrealheatmap.setVisibleMapRect(biggestRegion, animated: true)
        }
    }
}
