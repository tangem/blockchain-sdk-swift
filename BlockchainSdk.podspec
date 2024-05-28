#
# Be sure to run `pod lib lint BlockchainSdk.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name = 'BlockchainSdk'
  s.version = '0.0.1'
  s.summary = 'Use BlockchainSdk for Tangem wallet integration'
  s.description = <<-DESC
Use BlockchainSdk for Tangem wallet integration
                  DESC

  s.homepage = 'https://github.com/tangem/blockchain-sdk-swift'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'Tangem' => 'hello@tangem.com' }
  s.source = { :git => 'https://github.com/tangem/blockchain-sdk-swift.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Tangem'
  s.ios.deployment_target = '14.5'
  s.swift_version = '5.0'

  s.source_files = 'BlockchainSdk/**/*'

  s.resource_bundles = {
	'BlockchainSdk' => [
		'BlockchainSdk/Common/Localizations/*.lproj/*.strings',
      		'BlockchainSdk/PrivacyInfo.xcprivacy',
		]
  }

  s.exclude_files = 'BlockchainSdk/Blockchains/XRP/XRPKit/README.md',
                    'BlockchainSdk/Blockchains/XRP/XRPKit/LICENSE',
                    'BlockchainSdk/Blockchains/Tron/protobuf/Tron Protobuf.md',
                    'BlockchainSdk/Blockchains/Tron/protobuf/Contracts.proto',
                    'BlockchainSdk/Blockchains/Tron/protobuf/Tron.proto'

  # 'Hedera SDK' dependency must be added via SPM
  # 'CryptoSwift' dependency must be added via SPM
  # 'SwiftProtobuf' dependency must be added via SPM
  # 'TangemWalletCore' dependency must be added via SPM

  s.dependency 'TangemSdk'
  s.dependency 'BigInt'
  s.dependency 'SwiftyJSON', '5.0.1'
  s.dependency 'Moya', '15.0.0'
  s.dependency 'Sodium', '0.9.1'
  s.dependency 'SwiftCBOR', '0.4.5'
  s.dependency 'stellar-ios-mac-sdk', '2.5.4'
  s.dependency 'AnyCodable-FlightSchool', '0.6.7'
  s.dependency 'ScaleCodec', '0.2.1'
  s.dependency 'TonSwift'

  s.dependency 'BinanceChain' # Fork https://github.com/tangem/swiftbinancechain.git
  s.dependency 'BitcoinCore.swift' # Fork https://github.com/tangem/bitcoincore.git
  s.dependency 'Solana.Swift' # Fork https://github.com/tangem/Solana.Swift.git

end
