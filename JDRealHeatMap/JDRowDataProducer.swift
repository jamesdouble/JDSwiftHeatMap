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
    var heatlevel:Float = 0
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
    static var theColorMixer:JDHeatColorMixer = JDHeatColorMixer()
    var MaxHeatLevelInWholeMap:Int = 0
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
        RowData = Array.init(repeating: 0, count: 4 * cgsize.width * cgsize.height)
    }
    
    func reduceSize(input:CGSize)->IntSize
    {
        let byteLimitForAOverlay:CGFloat = 5000000000.0
        let caculateByte = input.height * input.width * 4
        if(caculateByte < byteLimitForAOverlay)
        {
            return IntSize(width: Int(input.height), height: Int(input.width))
        }
        let scale:CGFloat = caculateByte / byteLimitForAOverlay
        let newWidth = Int(input.width) / Int(scale)
        let newHeight = Int(input.height) / Int(scale)
        
        func reduceRowData()
        {
            for i in 0..<rowformdatas.count
            {
                rowformdatas[i].localCGpoint.x /= scale
                rowformdatas[i].localCGpoint.y /= scale
                rowformdatas[i].radius /= scale
            }
        }
        reduceRowData()
        return IntSize(width: newWidth, height: newHeight)
    }
    
    func produceRowData()
    {
        print(#function + "w:\(cgsize.width),w:\(cgsize.height)")
        var ByteCount:Int = 0
        for h in 0..<self.cgsize.height
        {
            for w in 0..<self.cgsize.width
            {
                var destiny:Float = 0
                var involveCount:Int = 0
                for heatpoint in self.rowformdatas
                {
                    let bytesDistanceToPoint:Float = CGPoint(x: w, y: h).distanceTo(anther: heatpoint.localCGpoint)
                    let ratio:Float = 1 - (bytesDistanceToPoint / Float(heatpoint.radius))
                    if(ratio > 0)
                    {
                        involveCount += 1
                        destiny += ratio * heatpoint.heatlevel
                    }
                }
                if(MaxHeatLevelInWholeMap != 0)
                {
                    destiny /= Float(MaxHeatLevelInWholeMap)
                }
                if(destiny > 1)
                {
                    destiny = 1
                }
                //let rgb = JDRowDataProducer.theColorMixer.getRGB(inDestiny: destiny)
                let rgb = JDRowDataProducer.theColorMixer.getClearify(inDestiny: destiny)
                let redRow:UTF8Char = rgb.redRow
                let greenRow:UTF8Char = rgb.greenRow
                let BlueRow:UTF8Char = rgb.BlueRow
                let alpha:UTF8Char = UTF8Char(Int(destiny * 255))
                self.RowData[ByteCount] = redRow
                self.RowData[ByteCount+1] = greenRow
                self.RowData[ByteCount+2] = BlueRow
                self.RowData[ByteCount+3] = alpha
                ByteCount += 4
            }
        }
    }
}

fileprivate struct BytesRGB
{
    var redRow:UTF8Char = 0
    var greenRow:UTF8Char = 0
    var BlueRow:UTF8Char = 0
    var alpha:UTF8Char = 255

}

class JDHeatColorMixer:NSObject
{
    var colorArray:[UIColor]  = [UIColor.yellow,UIColor.blue,UIColor.red]
    var devideLevel:Int = 6
    
    override init()
    {
        colorArray = []
        for bluetogreen in 0..<devideLevel
        {
            let color = UIColor(red: 0, green: CGFloat((255/(devideLevel-1)) * bluetogreen)/255.0, blue: CGFloat(255 - (255/(devideLevel-1)) * bluetogreen)/255.0, alpha: 1.0)
            colorArray.append(color)
        }
        for greentored in 0..<devideLevel
        {
            let color = UIColor(red: CGFloat((255/(devideLevel-1)) * greentored)/255.0, green:CGFloat(255 - (255/(devideLevel-1)) * greentored)/255.0, blue:0 , alpha: 1.0)
            colorArray.append(color)
        }
    }
    
    fileprivate func getClearify(inDestiny D:Float)->BytesRGB
    {
        if(D == 0)
        {
            let rgb:BytesRGB = BytesRGB(redRow: 0,
                                        greenRow: 0,
                                        BlueRow: 0,
                                        alpha: 0)
            return rgb
        }
        
        let colorCount = colorArray.count
        if(colorCount < 2)
        {
            colorArray.append(UIColor.clear)
        }
        
        var TargetColor:UIColor = colorArray.last!
        let AverageWeight:Float = 1.0 / Float(colorCount)
        var counter:Float = 0.0
        for color in colorArray
        {
            if((counter < D) && D<=(counter + AverageWeight))
            {
                TargetColor = color
                break
            }
            else
            {
                counter += AverageWeight
            }
        }
        //
        let rgb = TargetColor.rgb()
        var redRow:UTF8Char = UTF8Char(Int((rgb?.red)!))
        var GreenRow:UTF8Char = UTF8Char(Int((rgb?.green)!))
        var BlueRow:UTF8Char = UTF8Char(Int((rgb?.blue)!))
    
        let Crgb:BytesRGB = BytesRGB(redRow: redRow,
                                    greenRow: GreenRow,
                                    BlueRow: BlueRow,
                                    alpha: 255)
        return Crgb
    }
    
    
    fileprivate func getRGB(inDestiny D:Float)->BytesRGB
    {
        if(D == 0)
        {
            let rgb:BytesRGB = BytesRGB(redRow: 0,
                                        greenRow: 0,
                                        BlueRow: 0,
                                        alpha: 0)
            return rgb
        }
        
        let colorCount = colorArray.count
        if(colorCount < 2)
        {
            colorArray.append(UIColor.clear)
        }
        
        var TargetColor:[UIColor] = []
        let AverageWeight:Float = 1.0 / Float(colorCount-1)
        var counter:Float = 0.0
        var Index:Int = 0
        var LDiff:Float = 0.0
        for color in colorArray
        {
            counter  += AverageWeight
            if(counter > D)
            {
                TargetColor.append(color)
                if(TargetColor.count == 2)
                {
                    break
                }
                LDiff = AverageWeight-(counter - D)
            }
            else if(counter == D)
            {
                TargetColor = [color,color]
                break
            }
            else
            {
               Index += 1
              
            }
        }
        LDiff = 1.0 - LDiff
        let RDiff:Float = 1.0 - LDiff
        //
        let LCGColor = TargetColor[0].rgb()
        let LRed:Float = (LCGColor?.red)!
        let LGreen:Float = (LCGColor?.green)!
        let LBlue:Float = (LCGColor?.blue)!
        let RCGColor = TargetColor[1].rgb()
        let RRed:Float = (RCGColor?.red)!
        let RGreen:Float = (RCGColor?.green)!
        let RBlue:Float = (RCGColor?.blue)!
        //
        var redRow:UTF8Char = UTF8Char(Int(LRed * LDiff + RRed * RDiff))
        var GreenRow:UTF8Char = UTF8Char(Int(LGreen * LDiff + RGreen * RDiff))
        var BlueRow:UTF8Char = UTF8Char(Int(LBlue * LDiff + RBlue * RDiff))
        
        
        let rgb:BytesRGB = BytesRGB(redRow: redRow,
                                    greenRow: GreenRow,
                                    BlueRow: BlueRow,
                                    alpha: 255)
        return rgb
    }
    
    
}

extension UIColor {
    
    func rgb() -> (red:Float, green:Float, blue:Float, alpha:Float)? {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            let iRed = Float(fRed * 255.0)
            let iGreen = Float(fGreen * 255.0)
            let iBlue = Float(fBlue * 255.0)
            let iAlpha = Float(fAlpha * 255.0)
            
            return (red:iRed, green:iGreen, blue:iBlue, alpha:iAlpha)
        } else {
            // Could not extract RGBA components:
            return nil
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
