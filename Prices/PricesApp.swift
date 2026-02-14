//
//  PricesApp.swift
//  Prices
//
//  Created by Psyrax on 01/02/26.
//

import SwiftData
import SwiftUI

@main
struct PricesApp: App {
    @State private var deepLinkCardId: String?

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Carta.self,
            CartaVariant.self,
            GameSet.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView(deepLinkCardId: $deepLinkCardId)
                .onOpenURL { url in
                    handleDeepLink(url: url)
                }
                .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }

    private func handleDeepLink(url: URL) {
        print("🔗 [DeepLink] URL recibida: \(url.absoluteString)")
        print(
            "🔗 [DeepLink] Scheme: \(url.scheme ?? "nil"), Host: \(url.host() ?? "nil"), Path: \(url.path())"
        )

        // Manejar ogl://card?id=X
        guard url.scheme == "ogl",
            let host = url.host(),
            host == "card"
        else {
            print("❌ [DeepLink] Esquema no reconocido")
            return
        }

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems,
            let idItem = queryItems.first(where: { $0.name == "id" }),
            let cardId = idItem.value
        {
            print("✅ [DeepLink] Card ID encontrado: \(cardId)")
            deepLinkCardId = cardId
        } else {
            print("❌ [DeepLink] No se encontró el parámetro 'id'")
        }
    }
}
