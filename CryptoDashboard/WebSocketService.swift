//
//  WebSocketService.swift
//  CryptoDashboard
//
//  Created by Jamie Wilhelm on 5/31/26.
//
import Foundation

final class WebSocketService: Sendable {
    
    private let url = URL(string: "wss://ws.kraken.com/v2")!
    
    func connect(for symbols: [CryptoSymbol]) -> AsyncStream<Data> {
        AsyncStream { continuation in
            let session = URLSession(configuration: .default)
            let task = session.webSocketTask(with: url)
            
            task.resume()
            print("🔌 Connecting to Kraken WebSocket...")
            
            // Format Kraken subscription JSON payload
            let symbolStrings = symbols.map { $0.rawValue }
            let payload: [String: Any] = [
                "method": "subscribe",
                "params": [
                    "channel": "ticker",
                    "symbol": symbolStrings
                ]
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                task.send(.string(jsonString)) { error in
                    if let error = error {
                        print("❌ Kraken subscription failed: \(error.localizedDescription)")
                    } else {
                        print("✅ Subscribed to Kraken pairs: \(symbolStrings.joined(separator: ", "))")
                    }
                }
            }
            
            Task {
                await listen(on: task, continuation: continuation)
            }
            
            continuation.onTermination = { _ in
                task.cancel(with: .goingAway, reason: nil)
                print("🔌 Connection Closed Cleanly.")
            }
        }
    }
    
    private func listen(on task: URLSessionWebSocketTask, continuation: AsyncStream<Data>.Continuation) async {
        do {
            let message = try await task.receive()
            switch message {
            case .string(let text):
                if let data = text.data(using: .utf8) { continuation.yield(data) }
            case .data(let data):
                continuation.yield(data)
            @unknown default: break
            }
            await listen(on: task, continuation: continuation)
        } catch {
            print("⚠️ Kraken Stream Disconnected: \(error.localizedDescription)")
            continuation.finish()
        }
    }
}
