//
//  URLSessionWebSocketDelegateWrapper.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 14.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class URLSessionWebSocketDelegateWrapper: NSObject, URLSessionWebSocketDelegate {
    private let webSocketTaskDidOpen: (URLSessionWebSocketTask) -> Void?
    private let webSocketTaskDidClose: (URLSessionWebSocketTask, URLSessionWebSocketTask.CloseCode) -> Void
    
    init(
        webSocketTaskDidOpen: @escaping (URLSessionWebSocketTask) -> Void?,
        webSocketTaskDidClose: @escaping (URLSessionWebSocketTask, URLSessionWebSocketTask.CloseCode) -> Void
    ) {
        self.webSocketTaskDidOpen = webSocketTaskDidOpen
        self.webSocketTaskDidClose = webSocketTaskDidClose
    }
    
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        webSocketTaskDidOpen(webSocketTask)
    }
    
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        webSocketTaskDidClose(webSocketTask, closeCode)
    }
}
