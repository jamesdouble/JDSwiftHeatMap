//
//  JDRowDataProducer.swift
//  JDRealHeatMap
//
//  Created by 郭介騵 on 2017/6/14.
//  Copyright © 2017年 james12345. All rights reserved.
//

import Foundation
import MapKit

struct RowFormHeatData {
    var heatlevel:Int = 0
    var localCGpoint:CGPoint = CGPoint.zero
    var radius:CGFloat = 0
}

struct IntSize {
    var width:Int = 0
    var height:Int = 0
}

/**
  All this class needs to know is relative position & CGSize
 **/
class JDRowDataProducer:NSObject
{
    var RowData:[UTF8Char] = []
    var rowformdatas:[RowFormHeatData] = []
    var cgsize:IntSize!
    var BytesPerRow:Int
    {
        return 4 * cgsize.width
    }
    
    init(size:CGSize,rowHeatData:[RowFormHeatData])
    {
        super.init()
        self.rowformdatas = rowHeatData
        self.cgsize = reduceSize(input: size)
        produceRowData()
    }
    
    func reduceSize(input:CGSize)->IntSize
    {
        let newWidth = Int(input.width) / 10000
        let newHeight = Int(input.height) / 10000
        
        func reduceRowData()
        {
            for i in 0..<rowformdatas.count
            {
                rowformdatas[i].localCGpoint.x /= 10000
                rowformdatas[i].localCGpoint.y /= 10000
                rowformdatas[i].radius /= 10000
            }
        }
        reduceRowData()
        return IntSize(width: newWidth, height: newHeight)
    }
    
    func produceRowData()
    {
        print(#function + "w:\(cgsize.width),w:\(cgsize.height)")
        
        for h in 0..<cgsize.height
        {
            for w in 0..<cgsize.width
            {
                var destiny:Float = 0
                for heatpoint in rowformdatas
                {
                    let bytesDistanceToPoint:Float = CGPoint(x: w, y: h).distanceTo(anther: heatpoint.localCGpoint)
                    let ratio:Float = 1 - (bytesDistanceToPoint / Float(heatpoint.radius))
                    
                    if(ratio > 0)
                    {
                        destiny += ratio * 255
                    }
                    else
                    {
                        destiny += 0
                    }
                }
                let redRow:UTF8Char = UTF8Char(Int(destiny))
                let greenRow:UTF8Char = 0
                let BlueRow:UTF8Char = 0
                let alpha:UTF8Char = redRow
                let aByte:[UTF8Char] = [redRow,greenRow,BlueRow,alpha]
                RowData.append(contentsOf: aByte)
            }
        }
    }
    
}

extension CGPoint
{
    func distanceTo(anther point:CGPoint)->Float
    {
        let diffx = (self.x - point.x) * (self.x - point.x)
        let diffy = (self.y - point.y) * (self.y - point.y)
        return sqrtf(Float(diffx + diffy))
    }
}
