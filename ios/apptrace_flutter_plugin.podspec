#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint apptrace_flutter_plugin.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'apptrace_flutter_plugin'
  s.version          = '1.0.1'
  s.summary          = 'Apptrace flutter plugin.'
  s.description      = <<-DESC
Apptrace flutter plugin.
                       DESC
  s.homepage         = 'https://www.apptrace.cn/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { "Apptrace" => "dev@apptrace.cn" }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  s.dependency 'ApptraceSDK', "~> 1.1.8"

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
