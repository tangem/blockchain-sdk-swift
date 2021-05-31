platform :ios, '13.0'
use_frameworks!
inhibit_all_warnings!

target 'BlockchainSdk' do
  pod 'BigInt'
  pod 'SwiftyJSON'
  pod 'Alamofire'
  pod 'Moya'
  pod 'Sodium'
  pod 'SwiftCBOR'
  pod 'BinanceChain', :git => 'https://github.com/lazutkin-andrey/swiftbinancechain.git', :tag => '0.0.7'
  #pod 'BinanceChain', :path => '../SwiftBinanceChain'
  pod 'HDWalletKit', :git => 'https://github.com/lazutkin-andrey/hdwallet.git', :tag => '0.3.12'
  #pod 'HDWalletKit', :path => '../HDWallet'
#  pod 'web3swift', :path => '../web3swift'
  pod 'web3swift', :git => 'https://github.com/lazutkin-andrey/web3swift.git', :tag => '2.2.6'
  pod 'AnyCodable-FlightSchool'
  pod 'TangemSdk', :git => 'https://github.com/Tangem/tangem-sdk-ios.git', :tag => 'build-110'
  pod 'stellar-ios-mac-sdk'
  pod 'BitcoinCore.swift', :git => 'https://github.com/lazutkin-andrey/bitcoincore.git', :tag => '0.0.13'
  #pod 'BitcoinCore.swift', :path => '../bitcoincore'
end

target 'BlockchainSdkTests' do
  pod 'TangemSdk', :git => 'https://github.com/Tangem/tangem-sdk-ios.git', :tag => 'build-110'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if Gem::Version.new('9.0') > Gem::Version.new(config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'])
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
      end
    end
  end
end
