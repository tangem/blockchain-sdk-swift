platform :ios, '13.0'
use_frameworks!
inhibit_all_warnings!

def common_pods
  # 'TangemWalletCore' dependency must be added via SPM

  pod 'TangemSdk', :git => 'https://github.com/Tangem/tangem-sdk-ios.git', :tag => 'develop-264'
  #pod 'TangemSdk', :path => '../tangem-sdk-ios'
  
  pod 'BitcoinCore.swift', :git => 'https://github.com/tangem/bitcoincore.git', :tag => '0.0.20'
  #pod 'BitcoinCore.swift', :path => '../bitcoincore'
end

target 'BlockchainSdk' do
  # 'Hedera SDK' dependency must be added via SPM
  # 'CryptoSwift' dependency must be added via SPM
  # 'SwiftProtobuf' dependency must be added via SPM
  # 'secp256k1.swift' dependency must be added via SPM

  pod 'BigInt', '5.2.0'
  pod 'Moya', '15.0.0'
  pod 'Sodium', '0.9.1'
  pod 'SwiftCBOR', '0.4.5'
  pod 'AnyCodable-FlightSchool', '0.6.7'
  pod 'stellar-ios-mac-sdk', '2.5.4'
  pod 'ScaleCodec', '0.2.1'
  pod 'TonSwift', :git => 'https://github.com/tangem/ton-swift.git', :tag => '1.0.10-tangem1'

  pod 'BinanceChain', :git => 'https://github.com/tangem/swiftbinancechain.git', :tag => '0.0.11'
  #pod 'BinanceChain', :path => '../SwiftBinanceChain'

  pod 'Solana.Swift', :git => 'https://github.com/tangem/Solana.Swift', :tag => '1.2.0-tangem7'
  #pod 'Solana.Swift', :path => '../Solana.Swift'

  pod 'SwiftyJSON', :git => 'https://github.com/tangem/SwiftyJSON.git', :tag => '5.0.1-tangem1'

  common_pods
end

target 'BlockchainSdkTests' do
  common_pods
end

target 'BlockchainSdkExample' do
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
      if config.name.include?("Debug")
          config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
          config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
          config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
          config.build_settings['ENABLE_TESTABILITY'] = 'YES'
          config.build_settings['SWIFT_COMPILATION_MODE'] = 'Incremental'
      end

      config.build_settings['DEAD_CODE_STRIPPING'] = 'YES'
  end
  
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.5'

      if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      end
    end
  end

  # ============ SPM <-> CocoaPods interop ============

  # `SwiftProtobuf` SPM package for `BinanceChain` pod
  add_spm_package_to_target(
   installer.pods_project,
   "BinanceChain",
   "https://github.com/tangem/swift-protobuf-binaries.git",
   "SwiftProtobuf",
   { :kind => "exactVersion", :version => "1.25.2-tangem1" }
  )

  # `secp256k1.swift` SPM package for `Solana.Swift` pod
  add_spm_package_to_target(
   installer.pods_project,
   "Solana.Swift",
   "https://github.com/GigaBitcoin/secp256k1.swift.git",
   "secp256k1",
   { :kind => "upToNextMinorVersion", :minimumVersion => "0.12.0" }
  )

end

# Adds given SPM package as a dependency to a specific target in the `Pods` project.
# TODO: Extract this logic to a dedicated CocoaPods plugin (IOS-5855)
#
# Valid values for the `requirement` parameter are:
# - `{ :kind => "upToNextMajorVersion", :minimumVersion => "1.0.0" }`
# - `{ :kind => "upToNextMinorVersion", :minimumVersion => "1.0.0" }`
# - `{ :kind => "exactVersion", :version => "1.0.0" }`
# - `{ :kind => "versionRange", :minimumVersion => "1.0.0", :maximumVersion => "2.0.0" }`
# - `{ :kind => "branch", :branch => "some-feature-branch" }`
# - `{ :kind => "revision", :revision => "4a9b230f2b18e1798abbba2488293844bf62b33f" }`
def add_spm_package_to_target(project, target_name, url, product_name, requirement)
  project.targets.each do |target|
    if target.name == target_name
      pkg = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
      pkg.repositoryURL = url
      pkg.requirement = requirement
      ref = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
      ref.package = pkg
      ref.product_name = product_name
      target.package_product_dependencies << ref

      project_already_has_this_pkg = false

      project.root_object.package_references.each do |existing_ref|
        if existing_ref.display_name.downcase.eql?(url.downcase)
          project_already_has_this_pkg = true
          break
        end
      end

      unless project_already_has_this_pkg
        project.root_object.package_references << pkg
      end

      target.build_configurations.each do |config|
        config.build_settings['SWIFT_INCLUDE_PATHS'] = '$(inherited) ${PODS_BUILD_DIR}/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)'
      end
    end
  end

  project.save
end
