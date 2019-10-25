//
//  File.swift
//  JDSwiftHeatMap
//
//  Created by JamesDouble on 2019/10/24.
//

import Foundation
import CoreLocation

public protocol JDHeatMapDelegate {
    func heatmap(HeatPointCount heatmap: JDSwiftHeatMap) -> Int
    func heatmap(HeatLevelFor index:Int) -> Int
    func heatmap(RadiusInKMFor index:Int) -> Double
    func heatmap(CoordinateFor index:Int) -> CLLocationCoordinate2D
}

extension JDHeatMapDelegate
{
    func heatmap(RadiusInKMFor index:Int) -> Double
    {
        return 100
    }
}
