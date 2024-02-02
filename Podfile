platform :ios, '13.0'
use_frameworks!
inhibit_all_warnings!

def common_pods
  # 'TangemWalletCore' dependency must be added via SPM

  pod 'TangemSdk', :git => 'https://github.com/Tangem/tangem-sdk-ios.git', :tag => 'develop-264'
  #pod 'TangemSdk', :path => '../tangem-sdk-ios'
  
  pod 'BitcoinCore.swift', :git => 'https://github.com/tangem/bitcoincore.git', :tag => '0.0.19'
  #pod 'BitcoinCore.swift', :path => '../bitcoincore'
end

target 'BlockchainSdk' do
  # 'Hedera' dependency must be added via SPM
  # 'CryptoSwift' dependency must be added via SPM
  # 'SwiftProtobuf' dependency must be added via SPM
  # 'secp256k1.swift' dependency must be added via SPM

  pod 'BigInt'
  pod 'SwiftyJSON'
  pod 'Alamofire'
  pod 'Moya'
  pod 'Sodium'
  pod 'SwiftCBOR'
  pod 'BinanceChain', :git => 'https://github.com/tangem/swiftbinancechain.git', :branch => 'feature/IOS-5792-SPM-dependencies-support'
  #pod 'BinanceChain', :path => '../SwiftBinanceChain'
  #pod 'HDWalletKit', :git => 'https://github.com/tangem/hdwallet.git', :tag => '0.3.12'
  #pod 'HDWalletKit', :path => '../HDWallet'
  pod 'AnyCodable-FlightSchool'
  pod 'stellar-ios-mac-sdk'
  
  pod 'Solana.Swift', :git => 'https://github.com/tangem/Solana.Swift', :branch => 'feature/IOS-5792-SPM-dependencies-support'
  #pod 'Solana.Swift', :path => '../Solana.Swift'

  pod 'ScaleCodec'
  
  common_pods
end

target 'BlockchainSdkTests' do
  common_pods
end

target 'BlockchainSdkExample' do
  pod 'Sodium'
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
    end

    if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
      target.build_configurations.each do |config|
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
   { :kind => "branch", :branch => "feature/IOS-5792-SPM-dependencies-support" }
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
