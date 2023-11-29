#
# Be sure to run `pod lib lint BlockchainSdk.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BlockchainSdk'
  s.version          = '0.0.1'
  s.summary          = 'Use BlockchainSdk for Tangem wallet integration'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Use BlockchainSdk for Tangem wallet integration
                       DESC

  s.homepage         = 'https://github.com/TangemCash/tangem-sdk-ios'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  # s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tangem AG' => '' }
  s.source           = { :git => 'https://github.com/TangemCash/tangem-sdk-ios.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.source_files = 'BlockchainSdk/**/*'


  s.resource_bundles = { 'BlockchainSdk' => ['BlockchainSdk/Common/Localizations/*.lproj/*.strings']}

  s.exclude_files = 'BlockchainSdk/WalletManagers/XRP/XRPKit/README.md', 
		    'BlockchainSdk/WalletManagers/XRP/XRPKit/LICENSE',
		    'BlockchainSdk/WalletManagers/Tron/protobuf/Tron Protobuf.md',
		    'BlockchainSdk/WalletManagers/Tron/protobuf/Contracts.proto',
		    'BlockchainSdk/WalletManagers/Tron/protobuf/Tron.proto'

  s.dependency 'TangemSdk'
  s.dependency 'BigInt', '5.2.0'
  s.dependency 'SwiftyJSON', '5.0.1'
  s.dependency 'Moya', '15.0.0'
  s.dependency 'Sodium', '0.9.1'
  s.dependency 'SwiftCBOR', '0.4.5'
  s.dependency 'stellar-ios-mac-sdk', '2.3.2'
  s.dependency 'AnyCodable-FlightSchool', '0.6.7'
  s.dependency 'ScaleCodec', '0.2.1'
  s.dependency 'SwiftProtobuf', '1.21.0'

  s.dependency 'BinanceChain' # Fork https://github.com/tangem/swiftbinancechain.git
  s.dependency 'HDWalletKit' # Fork https://github.com/tangem/hdwallet.git
  s.dependency 'BitcoinCore.swift' # Fork https://github.com/tangem/bitcoincore.git
  s.dependency 'Solana.Swift' # Fork https://github.com/tangem/Solana.Swift.git
  s.dependency 'TangemWalletCore' # Fork https://github.com/tangem/wallet-core-binaries-ios.git

end
