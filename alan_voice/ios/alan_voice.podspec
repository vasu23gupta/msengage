#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'alan_voice'
  s.version          = '0.0.1'
  s.summary          = 'Alan voice plugin'
  s.description      = <<-DESC
Alan voice plugin
                       DESC
  s.homepage         = 'http://alan.app'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Alan AI, Inc' => 'sergey@alan.app' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.ios.vendored_frameworks = 'Frameworks/AlanSDK.framework'
  s.ios.deployment_target = '11.0'
end

