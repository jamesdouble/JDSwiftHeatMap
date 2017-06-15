//
//  ViewController.swift
//  JDRealHeatMap
//
//  Created by 郭介騵 on 2017/6/12.
//  Copyright © 2017年 james12345. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {

    var map:JDRealHeatMap?
    let testpointCoor = [CLLocationCoordinate2D(latitude: 23.0, longitude: 120),
        CLLocationCoordinate2D(latitude: 25.0, longitude: 121)
        ]
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        map = JDRealHeatMap(frame: self.view.frame,delegate: self)
        self.view.addSubview(map!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


extension ViewController:JDHeatMapDelegate
{
    func heatmap(HeatPointCount heatmap:JDRealHeatMap) -> Int
    {
        return testpointCoor.count
    }
    
    func heatmap(HeatLevelFor index:Int) -> Int
    {
        return 2
    }
    
    func heatmap(CoordinateFor index:Int) -> CLLocationCoordinate2D
    {
        return testpointCoor[index]
    }
}
