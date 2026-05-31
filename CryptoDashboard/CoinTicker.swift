//
//  CoinTicker.swift
//  CryptoDashboard
//
//  Created by Jamie Wilhelm on 5/31/26.
//

import Foundation

/// Kraken specific asset pairs
enum CryptoSymbol: String, Codable, CaseIterable, Hashable {
    case btc = "XBT/USD"
    case eth = "ETH/USD"
    case sol = "SOL/USD"
    case ada = "ADA/USD"
    
    var displayName: String {
        switch self {
        case .btc: return "Bitcoin"
        case .eth: return "Ethereum"
        case .sol: return "Solana"
        case .ada: return "Cardano"
        }
    }
}

/// Matches Kraken's top-level ticker message payload
struct KrakenTickerResponse: Codable {
    let channel: String
    let type: String
    let data: [KrakenTickerData]
}

struct KrakenTickerData: Codable {
    let symbol: String
    let price: Double
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case price = "last" // Maps directly from Kraken's floating point primitive
    }
}

/// Clean UI representation
struct DisplaySnapshot: Identifiable, Hashable {
    var id: String { symbol.rawValue }
    let symbol: CryptoSymbol
    let currentPrice: Double
    let priceChangeDirection: PriceDirection
    let lastUpdated: Date
}

enum PriceDirection {
    case up
    case down
    case unchanged
}
