#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'speech_recognition_web'
  s.version          = '0.0.1'
  s.summary          = 'No-op implementation of speech_recognition_web web plugin to avoid build issues on iOS'
  s.description      = <<-DESC
temp fake speech_recognition_web plugin
                       DESC
  s.homepage         = 'https://github.com/deckerst/flutter_speech_recognition/speech_recognition_web'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Thibault Deckers' => 'thibault.deckers@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '8.0'
end
