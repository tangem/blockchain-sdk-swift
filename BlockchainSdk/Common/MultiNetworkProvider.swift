//
//  MultiNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 12/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya

@available(iOS 13.0, *)
protocol MultiNetworkProvider: AnyObject, HostProvider {
    associatedtype Provider: HostProvider
    
    var providers: [Provider] { get }
    var currentProviderIndex: Int { get set }
}

extension MultiNetworkProvider {
    var provider: Provider {
        providers[currentProviderIndex]
    }
    
    var host: String { provider.host }
    
    func providerPublisher<T>(for requestPublisher: @escaping (_ provider: Provider) -> AnyPublisher<T, Error>) -> AnyPublisher<T, Error> {
        log("providing provider")
        return
        requestPublisher(provider)
            .catch { [weak self] error -> AnyPublisher<T, Error> in
                guard let self = self else { return .anyFail(error: error) }
                
                self.log("provider error")
                
                if let moyaError = error as? MoyaError, case let .statusCode(resp) = moyaError {
                    self.log("Switchable publisher catched error: \(moyaError). Response message: \(String(describing: String(data: resp.data, encoding: .utf8)))")
                    print("Switchable publisher catched error: \(moyaError). Response message: \(String(describing: String(data: resp.data, encoding: .utf8)))")
                }
                
                if case WalletError.noAccount = error {
                    self.log("no account, return error")
                    return .anyFail(error: error)
                }
                
                self.log("Switchable publisher catched error: \(error)")
                print("Switchable publisher catched error:", error)
                
                if self.needRetry() {
                    self.log("Switching to next publisher")
                    print("Switching to next publisher")
                    return self.providerPublisher(for: requestPublisher)
                }
                
                self.log("NOT switching, return error")
                
                return .anyFail(error: error)
            }
            .eraseToAnyPublisher()
    }
    
    private func needRetry() -> Bool {
        log("need retry enter")
        currentProviderIndex += 1
        log("need retry increment")
        if currentProviderIndex < providers.count {
            log("need retry return true")
            return true
        }
        resetProviders()
        log("need retry return false")
        return false
    }
    
    private func resetProviders() {
        log("resetting providers")
        currentProviderIndex = 0
    }
    
    func log(_ text: String) {
        MNPLogger.shared.log("MNP LOG: \(text) \(currentProviderIndex + 1)/\(providers.count) - \(host)", level: .error)
    }
}

protocol HostProvider {
    var host: String { get }
}




fileprivate var loggerDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss:SSS"
    return formatter
}()

fileprivate func logToConsole(_ message: String) {
    print(loggerDateFormatter.string(from: Date()) + ": " + message)
}

import TangemSdk

public class MNPLogger: TangemSdkLogger {
    
    public static let shared = MNPLogger()
    
    private let fileManager = FileManager.default
    
    public var scanLogFileData: Data? {
        try? Data(contentsOf: scanLogsFileUrl)
    }
    
    private var scanLogsFileUrl: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("mnpLogs.txt")
    }
    
    private var isRecordingLogs: Bool = false
    
    init() {
        try? fileManager.removeItem(at: scanLogsFileUrl)
    }
    
    public func log(_ message: String, level: Log.Level) {
        let formattedMessage = "\(loggerDateFormatter.string(from: Date())): \(message)\n"
        let messageData = formattedMessage.data(using: .utf8)!
//        logToConsole(message)
        if let handler = try? FileHandle(forWritingTo: scanLogsFileUrl) {
            handler.seekToEndOfFile()
            handler.write(messageData)
            handler.closeFile()
        } else {
            try? messageData.write(to: scanLogsFileUrl)
        }
    }
}
