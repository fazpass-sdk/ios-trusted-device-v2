Pod::Spec.new do |spec|
spec.name       = "ios-trusted-device-v2"
spec.version    = "1.1.8"
spec.summary    = "IOS Trusted Device"
spec.description    = <<-DESC
IOS counterpart for fazpass trusted device.
DESC
spec.license    = { :type => "MIT", :file => "LICENSE" }
spec.author	= { "Citcall Indonesia" => "citcall.dev@gmail.com" }
spec.homepage	= "https://fazpass.com"
spec.documentation_url = "https://doc.fazpass.com"
spec.platforms	= { :ios => "13.0" }
spec.swift_version = "5.7"
spec.source	= { :git => "https://github.com/fazpass-sdk/ios-trusted-device-v2.git", :tag => "#{spec.version}" }
spec.source_files = "Sources/Fazpass/**/*.swift"
spec.xcconfig	= { "SWIFT_VERSION" => "#{spec.swift_version}" }
spec.static_framework = true
spec.dependency 'DeviceKit'
spec.dependency 'Firebase/Analytics'
spec.dependency 'Firebase/Messaging'
end
