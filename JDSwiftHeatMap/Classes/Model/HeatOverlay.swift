//
//  HeatOverlay.swift
//  JDSwiftHeatMap
//
//  Created by JamesDouble on 2019/10/24.
//

import MapKit

class HeatOverlay: NSObject {
    
    var heatpoints: [HeatPoint]
    var caculatedMapRect: MKMapRect?
    
    init(firstPoint: HeatPoint) {
        self.heatpoints = [firstPoint]
    }
    
    /// Add New Point to this overlay
    ///
    /// - Parameter point: new point
    func addPoint(_ point: HeatPoint) {
        self.caculateMaprect(point)
        self.heatpoints.append(point)
    }
    
    /// Recaculate overlay cover
    ///
    /// - Parameter newPoint: new point
    func caculateMaprect(_ newPoint: HeatPoint)
    {
        let pointRect = newPoint.MapRect
        guard let caculated = self.caculatedMapRect else { self.caculatedMapRect = pointRect; return }
        let maxX = max(caculated.maxX, pointRect.maxX)
        let maxY = max(caculated.maxY, pointRect.maxY)
        let minX = max(caculated.minX, pointRect.minX)
        let minY = max(caculated.minY, pointRect.minY)
        let rect = MKMapRect(x: maxY, y: maxY, width: maxX - minX, height: maxY - minY)
        self.caculatedMapRect = rect
    }
}

extension HeatOverlay: MKOverlay {
    
    /// The Center of this overlay
    var coordinate: CLLocationCoordinate2D {
        let midMKPoint = MKMapPoint(x: boundingMapRect.midX, y: boundingMapRect.midY)
        return midMKPoint.coordinate
    }
    
    /// Overlay's cover area
    var boundingMapRect: MKMapRect {
        guard let caculated = caculatedMapRect else { fatalError("boundingMapRect Error") }
        return caculated
    }
}

class HeatRadiusPointOverlay: HeatOverlay { }

class HeatFlatPointOverlay: HeatOverlay { }
