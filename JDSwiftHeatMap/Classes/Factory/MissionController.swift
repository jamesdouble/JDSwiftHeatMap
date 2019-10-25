//
//  MissionController.swift
//  JDSwiftHeatMap
//
//  Created by JamesDouble on 2019/10/24.
//

import Foundation
import RxSwift
import MapKit

enum MissonError: Error {
    case heatmapDeinit
    case maxHeatEqualsZero
    case misplaceOverlay
}

class MissionController: NSObject {
    
    let heatDelegate: JDHeatMapDelegate
    let dataType: DataPointType
    let colorMixer: ColorMixer
    //
    weak var heatmap: JDSwiftHeatMap? = nil
    var lastVisibleMapRect: MKMapRect = .init()
    var overlays: [HeatOverlay] = []
    //
    let missionThread = DispatchQueue(label: "MissionThread")
    let overlaysPublisSubject = PublishSubject<[HeatOverlay]>()
    let biggestRegionPublishSubject = PublishSubject<MKMapRect>()
    
    init(delegate: JDHeatMapDelegate,
         dataType: DataPointType,
         colorMode: ColorMixerMode,
         basicColor: [UIColor],
         level: Int) {
        self.heatDelegate = delegate
        self.dataType = dataType
        self.colorMixer = ColorMixer(basic: basicColor, mode: colorMode, level: level)
    }
    
    func executeMission() {
        let mapFramewidth: CGFloat = self.heatmap?.frame.width ?? 0
        self.lastVisibleMapRect = self.heatmap?.visibleMapRect ?? MKMapRect.init()
        missionThread.async {
            let ob = self.collectionDatas()
                .map({ self.produceOverlay($0, maxHeat: $1) })
                .map({ (overlays, maxHeat) -> ([HeatOverlay], Int) in self.overlaysPublisSubject.onNext(overlays); return (overlays, maxHeat) })
                .flatMap({ (newOverlays, maxHeat) -> Observable<([HeatOverlayRender], MKMapRect)> in
                    return self.computeRowFormData(newOverlays, maxHeat: maxHeat, mapFrameWidth: mapFramewidth)
                })
                .map({ (computedRenders, biggestRegion) -> ([HeatOverlayRender], MKMapRect) in
                    return self.startRendering(in: computedRenders, biggestRegion: biggestRegion)
                })
                .flatMap({ (renderedRenders, biggestRegion) -> Observable<Void> in
                    self.biggestRegionPublishSubject.onNext(biggestRegion)
                    return .just(())
                }).catchError({ (err) -> Observable<Void> in
                    guard let error = err as? MissonError else { return .just(()) }
                    print(error.localizedDescription)
                    return .just(())
                })
            let _ = ob.subscribe(onNext: nil)
        }
    }
}

extension MissionController {
    
    /// Collect Delegate datas to 'HeatPoint'
    ///
    /// - Returns: HeatPoint Array, And MaxHeatLevelinWholeMap in Observable
    private func collectionDatas() -> Observable<([HeatPoint], Int)> {
        print(#function)
        guard let map = self.heatmap else { return Observable.error(MissonError.heatmapDeinit) }
        let dataCount = self.heatDelegate.heatmap(HeatPointCount: map)
        var maxHeat: Int = 0
        let heatpoints = (0..<dataCount).map { (idx) -> HeatPoint in
            let coor = heatDelegate.heatmap(CoordinateFor: idx)
            let heat = heatDelegate.heatmap(HeatLevelFor: idx)
            maxHeat = max(maxHeat, heat)
            let raius = heatDelegate.heatmap(RadiusInKMFor: idx)
            let newHeatPoint = HeatPoint(heat: heat, coor: coor, heatradius: raius)
            return newHeatPoint
        }
        guard maxHeat > 0 else { return Observable.error(MissonError.maxHeatEqualsZero) }
        return Observable.just((heatpoints, maxHeat))
    }
    
    /// Transfer HeatPoints to mapoverlay
    ///
    /// - Parameters:
    ///   - points: user provided heat points
    ///   - maxHeat: max heat level in this map
    /// - Returns: Overlays Array, max Heat in Observable
    private func produceOverlay(_ points: [HeatPoint], maxHeat: Int) -> ([HeatOverlay], Int) {
        print(#function)
        let overlays = points.reduce(Array<HeatOverlay>.init()) { (overlays, point) -> [HeatOverlay] in
            var newOverlays = overlays
            switch self.dataType {
            case .flatPoint:
                //Flat point  there will Only be one overlay
                if newOverlays.isEmpty {
                    let onlyOverlay = HeatFlatPointOverlay(firstPoint: point)
                    return [onlyOverlay]
                } else if let flatOverlay = newOverlays.first as? HeatFlatPointOverlay {
                    flatOverlay.addPoint(point)
                }
            case .radiusPoint:
                for overlay in newOverlays {
                    let layRect = overlay.boundingMapRect
                    if layRect.intersects(point.MapRect) {
                        overlay.addPoint(point)
                        return newOverlays
                    }
                }
                let newOverlay = HeatRadiusPointOverlay(firstPoint: point)
                newOverlays.append(newOverlay)
            }
            return newOverlays
        }
        let lessOverlays = self.reduceOverlays(overlays)
        return (lessOverlays, maxHeat)
    }
    
    
    /// Fall through all overlay to reduce redudant cover
    ///
    /// - Parameter overlays: All Overlay
    /// - Returns: without redudant cover
    private func reduceOverlays(_ overlays: [HeatOverlay]) -> [HeatOverlay] {
        print(#function)
        var anyMerge = false
        let lessOverlays: [HeatOverlay] = overlays.reduce(Array<HeatOverlay>.init()) { (arr, overlay) -> [HeatOverlay] in
            guard !arr.isEmpty else { return [overlay] }
            var merge = false
            for oldLay in arr where oldLay.boundingMapRect.intersects(overlay.boundingMapRect) {
                for p in overlay.heatpoints {
                    oldLay.addPoint(p)
                }
                merge = true
                anyMerge = true
                break
            }
            return merge ? arr : (arr + [overlay])
        }
        return anyMerge ? self.reduceOverlays(lessOverlays) : lessOverlays
    }
}

extension MissionController {
    
    
    /// Create a HeatOverlayRender for everyoverlays
    ///
    /// - Parameters:
    ///   - overlays: overlays
    ///   - maxHeat: maxHeat in this map
    ///   - mapFrameWidth: mapView frame width
    /// - Returns: connected Renders
    private func computeRowFormData(_ overlays: [HeatOverlay], maxHeat: Int, mapFrameWidth: CGFloat) -> Observable<([HeatOverlayRender], MKMapRect)> {
        print(#function)
        let (renders, biggestRegion) = self.produceRenders(overlays)
        return self.connectDataProducer(renders, biggestRegion: biggestRegion, mapFrameWidth: mapFrameWidth, maxHeat: maxHeat)
    }
    
    /// Convert overlays to overlayrenders
    ///
    /// - Parameter overlays: caculated overlays
    /// - Returns: render without raw data, and biggest Region in the map
    private func produceRenders(_ overlays: [HeatOverlay]) -> ([HeatOverlayRender], MKMapRect) {
        print(#function)
        var biggestRegion: MKMapRect = MKMapRect(origin: .init(), size: .init(width: 0, height: 0))
        let renders = overlays.compactMap({ overlay -> HeatOverlayRender? in
            biggestRegion = (overlay.boundingMapRect.flatSize > biggestRegion.flatSize) ? overlay.boundingMapRect : biggestRegion
            //
            let render: HeatOverlayRender
            if let r = overlay as? HeatRadiusPointOverlay {
                render = RadiusHeatOvelayRender(overlay: r)
            } else if let f = overlay as? HeatFlatPointOverlay {
                render = FlatHeatOverlayRender(overlay: f)
            } else { return nil }
            return render
        })
        return (renders, biggestRegion)
    }
    
    /// Create a data producer for every render
    ///
    /// - Parameters:
    ///   - renders: all renders
    ///   - maxHeat: maxHeat Level in the map
    ///   - biggestRegion: biggest Region in the map
    /// - Returns: Data producer which have been setup
    private func connectDataProducer(_ renders: [HeatOverlayRender],
                                     biggestRegion: MKMapRect,
                                     mapFrameWidth: CGFloat,
                                     maxHeat: Int) -> Observable<([HeatOverlayRender], MKMapRect)> {
        let rendersObservable = self.checkTheColorMixer()
            .map { (colorMixer) -> [HeatOverlayRender] in
                let connectedRenders = renders.map({ self.pairADataProducer(for: $0,
                                                                            maxHeat: maxHeat,
                                                                            biggestRegion: biggestRegion,
                                                                            mapFrameWidth: mapFrameWidth,
                                                                            colorMixer: colorMixer) })
                    .map({ try? $0.get()  }).compactMap({ $0 })
                return connectedRenders
        }
        return rendersObservable.map({ ($0, biggestRegion) })
    }
    
    private func checkTheColorMixer() -> Observable<ColorMixer> {
        return self.colorMixer.colorsPublishSubject.filter({ !$0.isEmpty }).map({  _ in print(#function); return self.colorMixer })
    }
    
    /// Link a data producer for every render
    ///
    /// - Parameters:
    ///   - render: OverlayRender
    ///   - maxHeat: maxHeat level in this map
    ///   - biggestRegion: biggest Overlay Cover
    ///   - colorMixer: mixed Color Mixer
    /// - Returns: Render's producer has Linked
    private func pairADataProducer(for render: HeatOverlayRender,
                                   maxHeat: Int,
                                   biggestRegion: MKMapRect,
                                   mapFrameWidth: CGFloat,
                                   colorMixer: ColorMixer) -> Result<HeatOverlayRender, MissonError> {
        let scale: CGFloat = mapFrameWidth / CGFloat(biggestRegion.size.width)
        let result = render.caculateRowFormData(maxHeat: maxHeat)
        switch result {
        case .success(let localFormData, let overlayCGRect):
            let dataProducer: RowDataProducer
            switch self.dataType {
            case .flatPoint:
                dataProducer = RadiusPointRowDataProducer(size: overlayCGRect.size,
                                                          rowHeatData: localFormData,
                                                          color: colorMixer,
                                                          scale: scale)
            case .radiusPoint:
                dataProducer = FlatPointRowDataProducer(size: overlayCGRect.size,
                                                        rowHeatData: localFormData,
                                                        color: colorMixer,
                                                        scale: scale)
            }
            render.dataProducer = dataProducer
            return .success(render)
        case .failure(let err):
            return .failure(err)
        }
    }
}

extension MissionController {
    
    private func startRendering(in renders: [HeatOverlayRender], biggestRegion: MKMapRect) -> ([HeatOverlayRender], MKMapRect) {
        print(#function)
        let productFinish = self.startProducetEngine(in: renders)
        return (productFinish, biggestRegion)
    }
    
    private func startProducetEngine(in renders: [HeatOverlayRender]) -> [HeatOverlayRender] {
        renders.forEach { (render) in
            render.dataProducer?.produceRowData()
            render.setNeedsDisplay()
        }
        return renders
    }
}

extension MissionController: MKMapViewDelegate {
    
    public func mapView(_ mapView: MKMapView, didAdd renderers: [MKOverlayRenderer]) {
        print(#function)
    }
    
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return self.renders.first(where: { $0.overlay.coordinate == overlay.coordinate }) ?? MKOverlayRenderer(overlay: overlay)
    }
    
    public func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
        print(#function)
    }
}

private extension MKMapRect {
    var flatSize: Double {
        return self.size.height * self.size.width
    }
}
