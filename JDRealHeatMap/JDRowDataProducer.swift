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
        self.cgsize = reduceSize(input: size)
        self.rowformdatas = rowHeatData
        produceRowData()
    }
    
    func reduceSize(input:CGSize)->IntSize
    {
        let newWidth = Int(input.width) / 10000
        let newHeight = Int(input.height) / 10000
        return IntSize(width: newWidth, height: newHeight)
    }
    
    func produceRowData()
    {
        print(#function + (cgsize.width * cgsize.height).description)
        for h in 0..<cgsize.height
        {
            for w in 0..<cgsize.width
            {
                let redRow:UTF8Char = 255
                let greenRow:UTF8Char = 150
                let BlueRow:UTF8Char = 150
                let alpha:UTF8Char = 255
                let aByte:[UTF8Char] = [redRow,greenRow,BlueRow,alpha]
                RowData.append(contentsOf: aByte)
            }
        }
    }
    
}
