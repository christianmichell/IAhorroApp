//
//  IAhorroApp.swift
//  IAhorro
//
//  Created by Christian Michell on 24-09-25.
//

import SwiftUI

@main
struct IAhorroApp: App {
    @State private var environment: AppEnvironment?
    @State private var initializationError: Error?

    var body: some Scene {
        WindowGroup {
            Group {
                if let environment {
                    RootView(
                        answerService: environment.answerService,
                        processingService: environment.processingService,
                        receiptStore: environment.receiptStore
                    )
                    .environmentObject(environment.receiptStore)
                } else if let initializationError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                        Text("No se pudo inicializar la aplicación.")
                            .font(.headline)
                        Text(initializationError.localizedDescription)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Reintentar") {
                            Task { await loadEnvironment() }
                        }
                    }
                    .padding()
                } else {
                    ProgressView("Preparando IAhorro…")
                }
            }
            .task {
                if environment == nil && initializationError == nil {
                    await loadEnvironment()
                }
            }
        }
    }

    @MainActor
    private func loadEnvironment() async {
        do {
            environment = try await AppEnvironment.make()
            initializationError = nil
        } catch {
            initializationError = error
        }
    }
}
