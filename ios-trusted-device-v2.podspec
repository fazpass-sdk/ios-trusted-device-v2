Pod::Spec.new do |spec|
spec.name       = "ios-trusted-device-v2"
spec.version    = "1.0.0"
spec.summary    = "IOS Trusted Device"
spec.description    = <<-DESC
IOS counterpart for trusted device.
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
spec.dependency 'DeviceKit'
end
