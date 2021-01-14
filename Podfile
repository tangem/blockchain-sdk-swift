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
  pod 'BinanceChain', :git => 'https://bitbucket.org/tangem/swiftbinancechain.git', :tag => '0.0.7'
  #pod 'BinanceChain', :path => '/Users/alexander.osokin/repos/tangem/SwiftBinanceChain'
  pod 'HDWalletKit', :git => 'https://bitbucket.org/tangem/hdwallet.git', :tag => '0.3.12'
  #pod 'HDWalletKit', :path => '../HDWallet'
  #pod 'HDWalletKit', :path => '/Users/alexander.osokin/repos/tangem/HDWallet'
  #pod 'web3swift', :path => '/Users/alexander.osokin/repos/tangem/web3swift'
  pod 'web3swift', :git => 'https://bitbucket.org/tangem/web3swift.git', :tag => '2.2.4'
  pod 'AnyCodable-FlightSchool'
  pod 'TangemSdk', :git => 'git@bitbucket.org:tangem/card-sdk-swift.git', :tag => 'build-79'
  pod 'stellar-ios-mac-sdk'
  pod 'BitcoinCore.swift', :git => 'https://bitbucket.org/tangem/bitcoincore.git', :tag => '0.0.11'
  #pod 'BitcoinCore.swift', :path => '../bitcoincore'
end

target 'BlockchainSdkTests' do
  pod 'TangemSdk', :git => 'git@bitbucket.org:tangem/card-sdk-swift.git', :tag => 'build-79'
end
