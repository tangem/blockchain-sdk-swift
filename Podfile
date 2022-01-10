platform :ios, '13.0'
use_frameworks!
inhibit_all_warnings!

def common_pods
  pod 'TangemSdk', :git => 'https://github.com/Tangem/tangem-sdk-ios.git', :tag => 'develop-123'
  #pod 'TangemSdk', :path => '../tangem-sdk-ios'
end


target 'BlockchainSdk' do
  pod 'BigInt'
  pod 'SwiftyJSON'
  pod 'Alamofire'
  pod 'Moya'
  pod 'Sodium'
  pod 'SwiftCBOR'
  pod 'BinanceChain', :git => 'https://github.com/lazutkin-andrey/swiftbinancechain.git', :tag => '0.0.9'
  #pod 'BinanceChain', :path => '../SwiftBinanceChain'
  pod 'HDWalletKit', :git => 'https://github.com/lazutkin-andrey/hdwallet.git', :tag => '0.3.12'
  #pod 'HDWalletKit', :path => '../HDWallet'
  #pod 'web3swift', :path => '../web3swift'
  pod 'web3swift', :git => 'https://github.com/lazutkin-andrey/web3swift.git', :tag => '2.2.7'
  pod 'AnyCodable-FlightSchool'
  pod 'stellar-ios-mac-sdk'
  pod 'BitcoinCore.swift', :git => 'https://github.com/lazutkin-andrey/bitcoincore.git', :tag => '0.0.15'
  #pod 'BitcoinCore.swift', :path => '../bitcoincore'

  common_pods
end

target 'BlockchainSdkTests' do
  common_pods
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
