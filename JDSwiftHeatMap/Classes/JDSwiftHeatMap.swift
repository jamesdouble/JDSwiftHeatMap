//
//  JDSwiftHeatMap.swift
//  JDSwiftHeatMap
//
//  Created by JamesDouble on 2019/10/24.
//

import Foundation
import MapKit
import RxSwift

public class JDSwiftHeatMap: MKMapView {
    
    var missonController: MissionController
    let indicatorView = UIActivityIndicatorView(style: .gray)
    let disposeBag = DisposeBag()
    var renders: [HeatOverlayRender] = []
    
    public var showindicator: Bool = true {
        didSet{
            if(!showindicator)
            {
                indicatorView.stopAnimating()
            }
        }
    }
    
    public init(frame: CGRect,
                delegate: JDHeatMapDelegate,
                mapType: JDMapType = .FlatDistinct,
                colors: [UIColor] = [UIColor.blue, UIColor.green, UIColor.red],
                devideLevel: Int = 2) {
        missonController = MissionController(delegate: delegate,
                                             dataType: mapType.dataType,
                                             colorMode: mapType.colorMode,
                                             basicColor: colors,
                                             level: devideLevel)
        super.init(frame: frame)
        missonController.heatmap = self
        self.showsScale = true
        self.delegate = self.missonController
        self.setupTrigger()
        self.reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupTrigger() {
        self.missonController.overlaysPublisSubject
            .observeOn(MainScheduler.asyncInstance).subscribe(onNext: { (overlays) in
            self.overlays.forEach({ self.removeOverlay($0) })
            self.addOverlays(overlays)
        }).disposed(by: self.disposeBag)
        ///
        ///
        self.missonController.biggestRegionPublishSubject
            .observeOn(MainScheduler.asyncInstance).subscribe(onNext: { biggestRegion in
            let ZoomOrigin = MKMapPoint(x: biggestRegion.origin.x - biggestRegion.size.width * 2, y: biggestRegion.origin.y - biggestRegion.size.height * 2)
            let zoomoutregion = MKMapRect(origin: ZoomOrigin, size: MKMapSize(width: biggestRegion.size.width * 4, height: biggestRegion.size.height * 4))
            self.setVisibleMapRect(zoomoutregion, animated: true)
        }).disposed(by: self.disposeBag)
    }
    
    public func setType(type: JDMapType) {
        
    }
    
    public func reloadData() {
        if showindicator { self.indicatorView.startAnimating() }
        missonController.executeMission()
    }
    
    public override func renderer(for overlay: MKOverlay) -> MKOverlayRenderer? {
        return self.renders.first(where: { $0.overlay.coordinate == overlay.coordinate })
    }
    
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
