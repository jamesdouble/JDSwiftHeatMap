![Alt text](https://raw.githubusercontent.com/jamesdouble/JDSwiftHeatMap/master/Readme_img/logo.png?token=AJBUU8PbfD_WRNgAB4UEqbt1vDhm2iS3ks5ZbgTowA%3D%3D)
**JDSwiftMap** is an IOS Native MapKit Library.

You can easily make a highly customized HeatMap.

![Alt text](https://img.shields.io/badge/SwiftVersion-3.0+-red.svg?link=http://left&link=http://right)
![Alt text](https://img.shields.io/badge/IOSVersion-8.0+-green.svg)
![Alt text](https://img.shields.io/badge/BuildVersion-1.0.0-green.svg)
![Alt text](https://img.shields.io/badge/Author-JamesDouble-blue.svg?link=http://https://jamesdouble.github.io/index.html&link=http://https://jamesdouble.github.io/index.html)







# Usage

To add JDBreaksLoading to your view, just give it a frame and addSubview.

```Swift
  let jdbreaksLoading:JDBreaksLoading = JDBreaksLoading(frame: frame)
  self.view.addSubview(jdbreaksLoading)
```

### Game Configuration 
The default [ Ball, Block , Paddle -> All white, Block count: 3 ]

If you want to chagnge some game setting (color, block...etc).

You will need to set 'JDBreaksGameConfiguration'

```Swift
  let config:JDBreaksGameConfiguration = JDBreaksGameConfiguration(paddle_color: UIColor.white, ball_color:  UIColor.white, block_color:  UIColor.white, blocks_count: 3)
  let jd:JDBreaksLoading = JDBreaksLoading(frame: frame, configuration: config)
  self.view.addSubview(jd)
```
