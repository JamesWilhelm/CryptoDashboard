//
//  DashBoardView.swift
//  CryptoDashboard
//
//  Created by Jamie Wilhelm on 5/31/26.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
    let columns = [GridItem(.flexible())]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(CryptoSymbol.allCases, id: \.self) { symbol in
                        if let snapshot = viewModel.tickers[symbol] {
                            CryptoRowView(snapshot: snapshot)
                        } else {
                            CryptoLoadingRowView(symbol: symbol)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Live Crypto Feed")
            .onAppear {
                viewModel.startMonitoring()
            }
            .onDisappear {
                viewModel.stopMonitoring()
            }
        }
    }
}

struct CryptoRowView: View {
    let snapshot: DisplaySnapshot
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.symbol.displayName)
                    .font(.headline)
                Text(snapshot.symbol.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "$%.2f", snapshot.currentPrice))
                .font(.system(.body, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(priceColor(for: snapshot.priceChangeDirection))
                .animation(.easeOut(duration: 0.2), value: snapshot.currentPrice)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func priceColor(for direction: PriceDirection) -> Color {
        switch direction {
        case .up: return .green
        case .down: return .red
        case .unchanged: return .primary
        }
    }
}

struct CryptoLoadingRowView: View {
    let symbol: CryptoSymbol
    
    var body: some View {
        HStack {
            Text(symbol.displayName)
                .font(.headline)
            Spacer()
            ProgressView()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
