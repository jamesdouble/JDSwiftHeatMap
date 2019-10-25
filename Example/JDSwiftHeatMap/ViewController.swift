//
//  ViewController.swift
//  JDSwiftHeatMap
//
//  Created by 郭介騵 on 10/24/2019.
//  Copyright (c) 2019 郭介騵. All rights reserved.
//

import UIKit
import JDSwiftHeatMap
import MapKit

class ViewController: UIViewController {
    
    var testpointCoor = [CLLocationCoordinate2D(latitude: 27, longitude: 120),CLLocationCoordinate2D(latitude: 25.3, longitude: 119),CLLocationCoordinate2D(latitude: 27, longitude: 120),
                         CLLocationCoordinate2D(latitude: 27, longitude: 121)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addRandomData()
        let map = JDSwiftHeatMap(frame: self.view.frame, delegate: self)
        self.view.addSubview(map)
    }

    func addRandomData()
    {
        for _ in 0..<20
        {
            let loti:Double = Double(119) + Double(Float(arc4random()) / Float(UINT32_MAX))
            let lati:Double = Double(25 + arc4random_uniform(4)) + 2 * Double(Float(arc4random()) / Float(UINT32_MAX))
            testpointCoor.append(CLLocationCoordinate2D(latitude: lati, longitude: loti))
        }
    }
}

extension ViewController: JDHeatMapDelegate {
    
    func heatmap(HeatPointCount heatmap: JDSwiftHeatMap) -> Int {
        return testpointCoor.count
    }
    
    func heatmap(HeatLevelFor index: Int) -> Int {
        return index + 1
    }
    
    func heatmap(RadiusInKMFor index: Int) -> Double {
        return Double(20 + index * 2)
    }
    
    func heatmap(CoordinateFor index: Int) -> CLLocationCoordinate2D {
        return testpointCoor[index]
    }
}

