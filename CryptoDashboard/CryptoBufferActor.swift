//
//  CryptoBufferActor.swift
//  CryptoDashboard
//
//  Created by Jamie Wilhelm on 5/31/26.

import Foundation

actor CryptoBufferActor {
    private let service = WebSocketService()
    private var pricesCache: [CryptoSymbol: Double] = [:]
    private var previousPricesCache: [CryptoSymbol: Double] = [:]
    
    func startStreaming(for symbols: [CryptoSymbol]) -> AsyncStream<[DisplaySnapshot]> {
        let rawStream = service.connect(for: symbols)
        
        return AsyncStream { continuation in
            continuation.onTermination = { _ in }
            
            Task {
                let decoder = JSONDecoder()
                for await rawData in rawStream {
                    // Drop the type restriction constraint so we catch both snapshot arrays and update packets
                    if let response = try? decoder.decode(KrakenTickerResponse.self, from: rawData),
                       response.channel == "ticker" {
                        
                        for item in response.data {
                            if let symbol = CryptoSymbol(rawValue: item.symbol) {
                                pricesCache[symbol] = item.price
                                print("🎯 Cached live price for \(symbol.rawValue): $\(item.price)")
                            }
                        }
                    }
                }
            }
            
            // Task 2: High-performance throttle timer loop running at 10Hz (0.1s updates)
            Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    
                    let snapshots = self.generateSnapshot(for: symbols)
                    if !snapshots.isEmpty {
                        continuation.yield(snapshots)
                    }
                }
                continuation.finish()
            }
        }
    }
    
    private func generateSnapshot(for symbols: [CryptoSymbol]) -> [DisplaySnapshot] {
        var updates: [DisplaySnapshot] = []
        
        for symbol in symbols {
            guard let currentPrice = pricesCache[symbol] else { continue }
            let oldPrice = previousPricesCache[symbol] ?? currentPrice
            
            let direction: PriceDirection
            if currentPrice > oldPrice { direction = .up }
            else if currentPrice < oldPrice { direction = .down }
            else { direction = .unchanged }
            
            updates.append(DisplaySnapshot(
                symbol: symbol,
                currentPrice: currentPrice,
                priceChangeDirection: direction,
                lastUpdated: Date()
            ))
            
            previousPricesCache[symbol] = currentPrice
        }
        
        return updates
    }
}
