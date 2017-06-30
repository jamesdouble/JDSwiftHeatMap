//
//  JDColorMixer.swift
//  JDRealHeatMap
//
//  Created by 郭介騵 on 2017/6/30.
//  Copyright © 2017年 james12345. All rights reserved.
//

import UIKit

struct BytesRGB
{
    var redRow:UTF8Char = 0
    var greenRow:UTF8Char = 0
    var BlueRow:UTF8Char = 0
    var alpha:UTF8Char = 255
}

class JDHeatColorMixer:NSObject
{
    var colorArray:[UIColor]  = []
    var devideLevel:Int = 6
    
    init(array:[UIColor],level:Int)
    {
        for index in 0..<array.count
        {
            if(index == array.count-1) {break}
            if let rgb = array[index].rgb(),let rgb2 = array[index+1].rgb()
            {
                let greenDiff = (rgb2.green - rgb.green) / Float(devideLevel-1)
                let redDiff = (rgb2.red - rgb.red) / Float(devideLevel-1)
                let blueDiff = (rgb2.blue - rgb.blue) / Float(devideLevel-1)
                //
                for color1toColor2 in 0..<devideLevel
                {
                    let step:Float = Float(color1toColor2)
                    let red = CGFloat(rgb.red + (redDiff * step)) / 255.0
                    let green = CGFloat(rgb.green + (greenDiff * step)) / 255.0
                    let blue = CGFloat(rgb.blue + (blueDiff * step)) / 255.0
                    let color = UIColor(red:red, green: green, blue: blue, alpha: 1.0)
                    colorArray.append(color)
                }
            }
        }
        
    }
    
    func getClearify(inDestiny D:Float)->BytesRGB
    {
        if(D == 0) //Only Radius Data Type will Have 0 destiny
        {
            let rgb:BytesRGB = BytesRGB(redRow: 0,
                                        greenRow: 0,
                                        BlueRow: 0,
                                        alpha: 0)
            return rgb
        }
        //
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
            let next = counter + AverageWeight
            if((counter < D) && D<next)
            {
                TargetColor = color
                break
            }
            else if(D == next)
            {
                TargetColor = UIColor.brown
                break
            }
            else
            {
                counter = next
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
    
    
    func getBlurryRGB(inDestiny D:Float)->BytesRGB
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
