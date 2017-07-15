![Alt text](https://raw.githubusercontent.com/jamesdouble/JDSwiftHeatMap/master/Readme_img/logo.png?token=AJBUU8PbfD_WRNgAB4UEqbt1vDhm2iS3ks5ZbgTowA%3D%3D)

**JDSwiftMap** is an IOS Native MapKit Library.

You can easily make a highly customized HeatMap.

![Alt text](https://img.shields.io/badge/SwiftVersion-3.0+-red.svg?link=http://left&link=http://right)
![Alt text](https://img.shields.io/badge/IOSVersion-9.0+-green.svg)
![Alt text](https://img.shields.io/badge/BuildVersion-1.0.0-green.svg)
![Alt text](https://img.shields.io/badge/Author-JamesDouble-blue.svg?link=http://https://jamesdouble.github.io/index.html&link=http://https://jamesdouble.github.io/index.html)


![Alt text](https://raw.githubusercontent.com/jamesdouble/JDSwiftHeatMap/master/Readme_img/jdheatmapDemo.png?token=AJBUU1UA_L_wx5f_E3iRsaUGAh_xg3pCks5Zb1yIwA%3D%3D)

# Installation
* Cocoapods

```
	pod 'JDSWiftHeatMap'
```


# Usage

JDSwiftHeatMap is based on **IOS native MKMapView**, 

so you must familiar with.

## Init

*  Give a frame. 
*  Follow JDHeatMapDelegate.
*  Choose a MapType Below

```Swift
  map = JDRealHeatMap(frame: self.view.frame, delegate: self, maptype: .FlatDistinct)
  self.view.addSubview(map!)
```

### With ColorSetting
```Swift
  map = JDSwiftHeatMap(frame: mapsView.frame, delegate: self, maptype: .FlatDistinct, BasicColors: [UIColor.yellow,UIColor.red], devideLevel: 2)
  self.view.addSubview(map!)
```
BasicColors is element color array.

Devide Level = How Many Middle Colors between Basic Colors.

## Delegate - Most Important

There are two delegate you need to pay close.
 
1. ***MKMapViewDelegate*** - (Optional)

	This is the delegate you familiar,( AnnoationView For.., Render For...) You sure can use this delegate in old way, or not to follow this delegate.
		
	 **But if you do, you may need to follow two essential function.**
	 
	 ```Swift
	extension ViewController:MKMapViewDelegate
	{
		func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
		 {
        	if let heatoverlay = map?.heatmapView(mapView, rendererFor: overlay)
        	{
          	  return heatoverlay
        	}
        	else
        	{
        	    var yourownRender = yourownRenderClass()
        	    return yourownRender
        	}
    	}
    
   		func mapViewWillStartRenderingMap(_ mapView: MKMapView)
   		 {
        	map?.heatmapViewWillStartRenderingMap(mapView)
    	}
	}
  	map.delegate = self
  	
	```
	
2. ***JDHeatMapDelegate***
	
	When we talk to Heat Map, the most important thing is ***"Data"*** ! You should provide the data you want to display in this delegate.
	
	```Swift
	public protocol JDHeatMapDelegate {
    func heatmap(HeatPointCount heatmap:JDRealHeatMap) -> Int
    func heatmap(HeatLevelFor index:Int) -> Int
    @Optional func heatmap(RadiusInKMFor index:Int) -> Double
    func heatmap(CoordinateFor index:Int) -> CLLocationCoordinate2D
	}
	```
	*The default radius in km is 100KM.*

### Notice

More data will cause **large memory using**, should be notice.

## Setting

1. public func setType(type:JDMapType) 

	change the display type, it will refresh automatically.
	
2. public func refresh()

	Call this function when data changed.
	
3. public var showindicator:Bool
	 
	Set the loading indicator showing or not.
	 
	 
