# CryptoDashboard

A high-performance, real-time cryptocurrency ticker dashboard built using **SwiftUI** and **Swift 6 Concurrency**. The application establishes a low-latency, unauthenticated WebSocket connection to the Kraken API market data engine, ingesting high-frequency price shifts and streaming them smoothly to a decoupled UI grid layout without blocking the main execution thread.

---

## 🏛️ Architecture Overview

The codebase is built on an **Offline-First / Streaming-First** architecture designed to process high-throughput data streams smoothly. By separating low-level ingestion from the main actor, the app ensures fluid user interface experiences even during periods of extreme market volatility.

```text
┌──────────────────┐      AsyncStream<Data>       ┌────────────────────┐
│ WebSocketService │ ───────────────────────────> │ CryptoBufferActor  │
└──────────────────┘                              └────────────────────┘
                                                            │
                                             AsyncStream<[DisplaySnapshot]>
                                             (Throttled at 10Hz / 0.1s)
                                                            │
                                                            ▼
┌──────────────────┐     ObservableObject State   ┌────────────────────┐
│  DashboardView   │ <─────────────────────────── │ DashboardViewModel │
└──────────────────┘          (@MainActor)        └────────────────────┘


Key Architectural Components
WebSocketService (Network Layer): Conforms to Sendable. Manages a persistent lifecycle over URLSessionWebSocketTask. It connects to Kraken's unauthenticated market URL (wss://ws.kraken.com/v2), handles up-front subscriptions, and surfaces raw incoming JSON message packets as an asynchronous sequence via AsyncStream<Data>.

CryptoBufferActor (Data Buffer & Processing Layer): An isolated background actor that acts as a processing engine. It ingests the raw networking data sequence on a background thread, decodes payloads into memory caches, and employs a high-performance throttle timer running at 10Hz (0.1s intervals) to batch mutations out to the UI layer. This prevents thread starvation and UI choking.

DashboardViewModel (State Controller): Isolated to the @MainActor. It consumes the throttled snapshot sequences emitted by the actor and maps the values safely into @Published UI state dictionaries.

DashboardView (Presentation Layer): A modern SwiftUI layout structured around a lazy layout grid. It monitors directional ticks (.up, .down, .unchanged) and leverages native color transitions to highlight live price updates smoothly.

🚀 Features & Technical Highlights
Swift 6 Concurrency & Sendability: Zero data races. The multi-threaded data flow passes strictly through compiler-verified Sendable types, actors, and async streams.

No US Geofencing Restrictions: The pipeline uses Kraken's unauthenticated Public v2 WebSockets API, completely bypassing the strict domestic IP geofencing and handshake rejections (-1011 Bad Response) typical of global trade engines like Binance.

Resource Management & Clean Teardowns: The ingestion loop hooks into the AsyncStream.Continuation.onTermination lifecycle block. Navigating away or backgrounding the application automatically signals a graceful closure string (.goingAway) to the remote web socket, conserving battery, memory, and radio bandwidth.

Micro-Throttled Performance: Real-time asset feeds can emit dozens of ticks per second. Rather than flooding the main thread view hierarchy with every individual packet, updates are pooled in the actor cache and dispatched in structured 100ms micro-batches.
