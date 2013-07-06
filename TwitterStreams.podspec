Pod::Spec.new do |s|
  s.name     = 'TwitterStreams'
  s.version  = '0.1'
  s.license  = 'MIT'
  s.summary  = 'Twitter Streaming API client for iOS'
  s.homepage = 'https://github.com/Kabal/TwitterStreams'
  s.authors  = { 'Stuart Hall' => 'stuartkhall@gmail.com' }
  s.source   = { :git => 'https://github.com/Kabal/TwitterStreams.git' }
  s.source_files = 'TwitterStreams/**/*.{h,m}'
  s.requires_arc = true

  s.ios.deployment_target = '5.0'
  s.ios.frameworks = 'UIKit','Foundation','Twitter','Accounts'

end
