//
//  ColorMixer.swift
//  JDSwiftHeatMap
//
//  Created by JamesDouble on 2019/10/24.
//

import Foundation
import RxSwift

struct BytesRGB
{
    var redRow: UTF8Char = 0
    var greenRow: UTF8Char = 0
    var BlueRow: UTF8Char = 0
    var alpha: UTF8Char = 255
}

class ColorMixer: NSObject {
    
    let colorMode: ColorMixerMode
    let colorMixerThread = DispatchQueue(label: "ColorMixer.Thread")
    var mixedColorArray: [UIColor] = []
    //Rx
    var colorsPublishSubject: BehaviorSubject<[UIColor]> {
        guard let p = self._colorsPublishSubject else {
            let initP = BehaviorSubject<[UIColor]>.init(value: self.mixedColorArray)
            self._colorsPublishSubject = initP
            return initP
        }
        return p
    }
    private var _colorsPublishSubject: BehaviorSubject<[UIColor]>?
    
    init(basic colors: [UIColor], mode: ColorMixerMode, level: Int) {
        self.colorMode = mode
        super.init()
        self.startMixing(colors: colors, level: level)
    }
    
    /// Start mixing the color, it will send a signal when it done.
    ///
    /// - Parameters:
    ///   - color: main colors user defined
    ///   - level: amount of the color divide
    private func startMixing(colors: [UIColor], level: Int) {
        let fixedColors = colors.isEmpty ? [UIColor.red] : colors
        colorMixerThread.async { [weak self] in
            guard let firstColor = fixedColors.first, fixedColors.count > 1 else {
                self?.mixedColorArray = fixedColors
                self?.colorsPublishSubject.onNext(fixedColors)
                return
            }
            let lastColor = Array(fixedColors.dropFirst())
            let colorStairs: [UIColor] = lastColor.reduce([firstColor], { (arr, nextColor) -> [UIColor] in
                guard let lastColorRGB = arr.last?.rgb(), let nextColorRGB = nextColor.rgb() else { return arr }
                var colorsBetweenTwoColors: [UIColor] = []
                //
                let greenDiff = (nextColorRGB.green - lastColorRGB.green) / Float(level)
                let redDiff = (nextColorRGB.red - lastColorRGB.red) / Float(level)
                let blueDiff = (nextColorRGB.blue - lastColorRGB.blue) / Float(level)
                //Add All Color to array
                for color1toColor2 in 1...level
                {
                    let step:Float = Float(color1toColor2)
                    let red = CGFloat(lastColorRGB.red + (redDiff * step)) / 255.0
                    let green = CGFloat(lastColorRGB.green + (greenDiff * step)) / 255.0
                    let blue = CGFloat(lastColorRGB.blue + (blueDiff * step)) / 255.0
                    let color = UIColor(red:red, green: green, blue: blue, alpha: 1.0)
                    colorsBetweenTwoColors.append(color)
                }
                //
                var filledColors = arr
                filledColors.append(contentsOf: colorsBetweenTwoColors)
                return filledColors
            })
            self?.mixedColorArray = colorStairs
            self?.colorsPublishSubject.onNext(colorStairs)
        }
    }
    
    func getDestinyColorRGB(inDestiny D:Float)->BytesRGB
    {
        func getClearify(inDestiny D:Float)->BytesRGB
        {
            if(D == 0) //Only None Flat Data Type will Have 0 destiny
            {
                let rgb:BytesRGB = BytesRGB(redRow: 0,
                                            greenRow: 0,
                                            BlueRow: 0,
                                            alpha: 0)
                return rgb
            }
            //
            let colorCount = mixedColorArray.count
            if(colorCount < 2)
            {
                mixedColorArray.append(UIColor.clear)
            }
            
            var TargetColor:UIColor = UIColor()
            let AverageWeight:Float = 1.0 / Float(colorCount-1)
            var counter:Float = 0.0
            for color in mixedColorArray
            {
                let next = counter + AverageWeight
                if((counter <= D) && D<next)
                {
                    TargetColor = color
                    break
                }
                else
                {
                    counter = next
                }
            }
            //
            let rgb = TargetColor.rgb()
            
            let redRow:UTF8Char = UTF8Char(Int((rgb?.red)!))
            let GreenRow:UTF8Char = UTF8Char(Int((rgb?.green)!))
            let BlueRow:UTF8Char = UTF8Char(Int((rgb?.blue)!))
            
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
            
            let colorCount = mixedColorArray.count
            if(colorCount < 2)
            {
                mixedColorArray.append(UIColor.clear)
            }
            
            var TargetColor:[UIColor] = []
            let AverageWeight:Float = 1.0 / Float(colorCount-1)
            var counter:Float = 0.0
            var RDiff:Float = 0.0
            var Index = 0
            for color in mixedColorArray
            {
                if( ((D < (counter + AverageWeight)) && (D > counter))) //The Target is between this two color
                {
                    TargetColor.append(color)
                    let secondcolor = mixedColorArray[Index+1]
                    TargetColor.append(secondcolor)
                    //
                    RDiff = (D - counter)
                    break
                }
                else if(counter == D)
                {
                    TargetColor = [color,color]
                    break
                }
                Index += 1
                counter += AverageWeight
            }
            if(RDiff > 1) { fatalError("RDiff Error") }
            let LDiff = 1.0 - RDiff
            //
            func caculateRGB()->BytesRGB
            {
                if(TargetColor.count != 2) {fatalError("Color Mixer Problem")}
                let LCGColor = TargetColor[0].rgb()
                let LRed:Float = (LCGColor?.red)!
                let LGreen:Float = (LCGColor?.green)!
                let LBlue:Float = (LCGColor?.blue)!
                
                let RCGColor = TargetColor[1].rgb()
                let RRed:Float = (RCGColor?.red)!
                let RGreen:Float = (RCGColor?.green)!
                let RBlue:Float = (RCGColor?.blue)!
                
                //
                let redRow:UTF8Char = UTF8Char(Float(LRed * LDiff + RRed * RDiff) * D)
                let GreenRow:UTF8Char = UTF8Char(Float(LGreen * LDiff + RGreen * RDiff) * D)
                let BlueRow:UTF8Char = UTF8Char(Float(LBlue * LDiff + RBlue * RDiff) * D)
                
                return BytesRGB(redRow: redRow,
                                greenRow: GreenRow,
                                BlueRow: BlueRow,
                                alpha: UTF8Char(D * 255))
            }
            return caculateRGB()
        }
        
        if(colorMode == .blurryMode)
        {
            return getBlurryRGB(inDestiny: D)
        }
        else if(colorMode == .distinctMode)
        {
            return getClearify(inDestiny: D)
        }
        return BytesRGB(redRow: 0,
                        greenRow: 0,
                        BlueRow: 0,
                        alpha: 0)
    }
}

fileprivate extension UIColor {
    
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
