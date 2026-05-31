//
//  DashboardViewModel.swift
//  CryptoDashboard
//
//  Created by Jamie Wilhelm on 5/31/26.
//

import Foundation
import SwiftUI
internal import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var tickers: [CryptoSymbol: DisplaySnapshot] = [:]
    
    private let bufferActor = CryptoBufferActor()
    private var activeStreamTask: Task<Void, Never>?
    
    func startMonitoring() {
        activeStreamTask?.cancel()
        
        activeStreamTask = Task {
            let batchedStream = await bufferActor.startStreaming(for: CryptoSymbol.allCases)
            for await updatesSnapshot in batchedStream {
                // Ensure UI mutations are localized to the main actor
                for snapshot in updatesSnapshot {
                    self.tickers[snapshot.symbol] = snapshot
                }
            }
        }
    }
    
    func stopMonitoring() {
        activeStreamTask?.cancel()
        activeStreamTask = nil
    }
}
