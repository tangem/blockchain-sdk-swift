platform :ios, '11.0'
use_frameworks!
inhibit_all_warnings!

target 'BlockchainSdk' do
    pod 'BigInt', '~> 4.0'
    pod 'SwiftyJSON'
    pod 'Moya'
    pod 'Sodium'
    pod 'SwiftCBOR'
    pod 'BinanceChain', :git => 'https://bitbucket.org/tangem/swiftbinancechain.git', :tag => '0.0.6'
    #pod 'BinanceChain', :path => '/Users/alexander.osokin/repos/tangem/SwiftBinanceChain'
    pod 'HDWalletKit', :git => 'https://bitbucket.org/tangem/hdwallet.git', :tag => '0.3.11'
		#pod 'HDWalletKit', :path => '../HDWallet'
    #pod 'HDWalletKit', :path => '/Users/alexander.osokin/repos/tangem/HDWallet'
    #pod 'web3swift', :path => '/Users/alexander.osokin/repos/tangem/web3swift'
    pod 'web3swift', :git => 'https://bitbucket.org/tangem/web3swift.git', :tag => '2.2.3'
    pod 'AnyCodable-FlightSchool'
    pod 'TangemSdk', :git => 'git@bitbucket.org:tangem/card-sdk-swift.git', :tag => 'build-58'
    pod 'stellar-ios-mac-sdk'
end

target 'BlockchainSdkTests' do
   pod 'TangemSdk', :git => 'git@bitbucket.org:tangem/card-sdk-swift.git', :tag => 'build-58'
end
