//
//  MainTabView.swift
//  Prices
//
//  Vista principal con barra de navegación por tabs.
//

import SwiftUI

struct MainTabView: View {
    @Binding var deepLinkCardId: String?
    @AppStorage("justTcgApiKey") private var apiKey: String = ""

    var body: some View {
        TabView {
            ContentView(deepLinkCardId: $deepLinkCardId)
                .tabItem {
                    Label("En Venta", systemImage: "tag.fill")
                }

            WantToBuyListView()
                .tabItem {
                    Label("Quiero Comprar", systemImage: "cart.fill")
                }

            SearchView()
                .tabItem {
                    Label("Buscar", systemImage: "magnifyingglass")
                }

            NavigationStack {
                SettingsView(apiKey: $apiKey)
            }
            .tabItem {
                Label("Configuración", systemImage: "gearshape.fill")
            }
        }
    }
}

#Preview {
    MainTabView(deepLinkCardId: .constant(nil))
        .modelContainer(for: Carta.self, inMemory: true)
}
