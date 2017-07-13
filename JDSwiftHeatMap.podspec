Pod::Spec.new do |s|
  s.name             = 'JDSwiftHeatMap'
  s.version          = '1.0.0'
  s.summary          = 'You can easily make a highly customized HeatMap'
 
  s.description      = <<-DESC
JDSwiftMap is an IOS Native MapKit Library.
You can easily make a highly customized HeatMap.
                       DESC
 
  s.homepage         = 'https://github.com/jamesdouble/JDSwiftHeatMap'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'JamesDouble' => 'jameskuo12345@gmail.com' }
  s.source           = { :git => 'https://github.com/jamesdouble/JDSwiftHeatMap.git', :tag => s.version.to_s }
 
  s.ios.deployment_target = '9.0'
  s.source_files = 'JDRealHeatMap/JDSwiftHeatMap/*'
 
end
