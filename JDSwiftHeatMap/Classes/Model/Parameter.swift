//
//  Parameter.swift
//  JDSwiftHeatMap
//
//  Created by JamesDouble on 2019/10/24.
//

import Foundation

public enum JDMapType
{
    case RadiusDistinct
    case FlatDistinct
    case RadiusBlurry
    
    var dataType: DataPointType {
        switch self {
        case .RadiusDistinct:
            return .radiusPoint
        case .FlatDistinct:
            return .flatPoint
        case .RadiusBlurry:
            return .radiusPoint
        }
    }
    
    var colorMode: ColorMixerMode {
        switch self {
        case .RadiusDistinct:
            return .distinctMode
        case .FlatDistinct:
            return .distinctMode
        case .RadiusBlurry:
            return .blurryMode
        }
    }
}

enum DataPointType
{
    case flatPoint
    case radiusPoint
}

enum ColorMixerMode
{
    case blurryMode
    case distinctMode
}
