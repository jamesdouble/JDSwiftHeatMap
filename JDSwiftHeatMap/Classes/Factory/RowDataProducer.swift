//
//  RowDataProducer.swift
//  JDSwiftHeatMap
//
//  Created by JamesDouble on 2019/10/24.
//

import Foundation
import RxSwift

struct RowFormHeatData {
    var heatlevel: Float = 0
    var localCGpoint: CGPoint = CGPoint.zero
    var radius: CGFloat = 0
}

struct IntSize {
    var width: Int = 0
    var height: Int = 0
    
    static let zero = IntSize(width: 0, height: 0)
}

class RowDataProducer {
    
    let rowformdatas: [RowFormHeatData]
    let fitnessIntSize: IntSize
    weak var colorMixer: ColorMixer?
    var rowData: [UTF8Char]
    var BytesPerRow:Int { return 4 * fitnessIntSize.width }
    //
    init(size: CGSize,
         rowHeatData: [RowFormHeatData],
         color mixer: ColorMixer,
         scale: CGFloat) {
        self.colorMixer = mixer
        /// Sould not Miss this or the image size will up to GB
        ///(All beacuse MKMapRect Has a high definetion)
        let bigScale = scale * 1.5
        let newWidth = Int(size.width * scale)
        let newHeight = Int(size.height * scale)
        self.fitnessIntSize = IntSize(width: newWidth, height: newHeight)
        //
        self.rowformdatas = rowHeatData.map({ (origindata) -> RowFormHeatData in
            let newCGPoint = CGPoint(x: origindata.localCGpoint.x * bigScale, y: origindata.localCGpoint.y * bigScale)
            let newRadius = origindata.radius * bigScale
            let modifiRowFormData = RowFormHeatData(heatlevel: origindata.heatlevel, localCGpoint: newCGPoint , radius: newRadius)
            return modifiRowFormData
        })
        ///4 means rgba
        self.rowData = Array.init(repeating: 0, count: 4 * fitnessIntSize.width * fitnessIntSize.height)
    }

    func produceRowData() { fatalError("Should implement in subclass") }
}

class RadiusPointRowDataProducer: RowDataProducer {
    
    override func produceRowData()
    {
        guard let colorMixer = self.colorMixer else { return }
        var ByteCount:Int = 0
        for h in 0..<self.fitnessIntSize.height
        {
            for w in 0..<self.fitnessIntSize.width
            {
                var destiny:Float = 0
                for heatpoint in self.rowformdatas
                {
                    let pixelCGPoint = CGPoint(x: w, y: h)
                    let bytesDistanceToPoint:Float = pixelCGPoint.distanceTo(another: heatpoint.localCGpoint)
                    let ratio:Float = 1 - (bytesDistanceToPoint / Float(heatpoint.radius))
                    if(ratio > 0)
                    {
                        destiny += ratio * heatpoint.heatlevel
                    }
                }
                if(destiny > 1)
                {
                    destiny = 1
                }
                let rgb = colorMixer.getDestinyColorRGB(inDestiny: destiny)
                
                let redRow:UTF8Char = rgb.redRow
                let greenRow:UTF8Char = rgb.greenRow
                let BlueRow:UTF8Char = rgb.BlueRow
                let alpha:UTF8Char = rgb.alpha
                
                self.rowData[ByteCount] = redRow
                self.rowData[ByteCount+1] = greenRow
                self.rowData[ByteCount+2] = BlueRow
                self.rowData[ByteCount+3] = alpha
                ByteCount += 4
            }
        }
    }
    
}

class FlatPointRowDataProducer: RowDataProducer {
    
    override func produceRowData()
    {
        guard let colorMixer = self.colorMixer else { return }
        var ByteCount:Int = 0
        for h in 0..<self.fitnessIntSize.height
        {
            for w in 0..<self.fitnessIntSize.width
            {
                var destiny:Float = 0
                for heatpoint in self.rowformdatas
                {
                    let pixelCGPoint = CGPoint(x: w, y: h)
                    let bytesDistanceToPoint:Float = pixelCGPoint.distanceTo(another: heatpoint.localCGpoint)
                    let ratio:Float = 1 - (bytesDistanceToPoint / Float(heatpoint.radius))
                    if(ratio > 0)
                    {
                        destiny += ratio * heatpoint.heatlevel
                    }
                }
                if(destiny == 0)
                {
                    destiny += 0.01
                }
                
                if(destiny > 1)
                {
                    destiny = 1
                }
                
                let rgb = colorMixer.getDestinyColorRGB(inDestiny: destiny)
                
                let redRow:UTF8Char = rgb.redRow
                let greenRow:UTF8Char = rgb.greenRow
                let BlueRow:UTF8Char = rgb.BlueRow
                let alpha:UTF8Char = UTF8Char(Int(destiny * 255))
                
                self.rowData[ByteCount] = redRow
                self.rowData[ByteCount+1] = greenRow
                self.rowData[ByteCount+2] = BlueRow
                self.rowData[ByteCount+3] = alpha
                ByteCount += 4
            }
        }
    }
}

fileprivate extension CGPoint {
    func distanceTo(another point:CGPoint)->Float
    {
        let diffx = (self.x - point.x) * (self.x - point.x)
        let diffy = (self.y - point.y) * (self.y - point.y)
        return sqrtf(Float(diffx + diffy))
    }
}
