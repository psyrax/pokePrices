//
//  SearchView.swift
//  Prices
//
//  Vista de búsqueda rápida de precios sin guardar.
//

import SwiftData
import SwiftUI
import UIKit

struct SearchView: View {
    @AppStorage("justTcgApiKey") private var apiKey: String = ""
    @AppStorage("usdToMxnRate") private var usdToMxnRate: Double = 18.5
    @Query(sort: \GameSet.releaseDate, order: .reverse) private var storedSets: [GameSet]

    @State private var searchText: String = ""
    @State private var selectedSet: GameSet?
    @State private var isSearching = false
    @State private var results: [Carta] = []
    @State private var errorMessage: String?
    @State private var hasSearched = false
    @State private var selectedCarta: Carta?

    private var sortedSets: [GameSet] {
        storedSets.sorted { set1, set2 in
            switch (set1.releaseDate, set2.releaseDate) {
            case (let date1?, let date2?):
                return date1 > date2
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return set1.name < set2.name
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search form
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Nombre de la carta...", text: $searchText)
                            .textFieldStyle(.plain)
                            .submitLabel(.search)
                            .onSubmit {
                                Task { await performSearch() }
                            }
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    Picker("Expansión (opcional)", selection: $selectedSet) {
                        Text("Todas las expansiones").tag(nil as GameSet?)
                        ForEach(sortedSets) { set in
                            if let releaseDate = set.releaseDate {
                                Text("\(set.name) (\(releaseDate.prefix(4)))").tag(set as GameSet?)
                            } else {
                                Text(set.name).tag(set as GameSet?)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.blue)

                    Button {
                        Task { await performSearch() }
                    } label: {
                        HStack {
                            if isSearching {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                                Text("Buscando...")
                            } else {
                                Image(systemName: "magnifyingglass")
                                Text("Buscar Precios")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty || isSearching || apiKey.isEmpty)
                }
                .padding()

                if apiKey.isEmpty {
                    ContentUnavailableView(
                        "API Key requerida",
                        systemImage: "key.fill",
                        description: Text("Configura tu API key en la pestaña de Configuración para poder buscar.")
                    )
                } else if let error = errorMessage {
                    ContentUnavailableView(
                        "Error",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if hasSearched && results.isEmpty {
                    ContentUnavailableView(
                        "Sin resultados",
                        systemImage: "magnifyingglass",
                        description: Text("No se encontraron cartas para \"\(searchText)\"")
                    )
                } else if !hasSearched {
                    ContentUnavailableView(
                        "Busca una carta",
                        systemImage: "sparkle.magnifyingglass",
                        description: Text("Escribe el nombre de una carta para consultar sus precios.")
                    )
                } else {
                    // Results list
                    List(results) { carta in
                        Button {
                            selectedCarta = carta
                        } label: {
                            SearchResultRow(carta: carta, usdToMxnRate: usdToMxnRate)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Buscar Precios")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .sheet(item: $selectedCarta) { carta in
                NavigationStack {
                    CartaDetailView(carta: carta)
                }
                #if os(macOS)
                    .frame(minWidth: 550, minHeight: 650)
                #endif
            }
        }
    }

    private func performSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }

        isSearching = true
        errorMessage = nil
        results = []
        hasSearched = true

        do {
            let service = CartaService()

            if let set = selectedSet {
                results = try await service.fetchCardByName(cardName: query, setId: set.id)
            } else {
                results = try await service.search(query: query, pageSize: 30)
            }
        } catch {
            errorMessage = "Error al buscar: \(error.localizedDescription)"
        }

        isSearching = false
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let carta: Carta
    let usdToMxnRate: Double

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let url = carta.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    default:
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .frame(width: 50, height: 70)
                .cornerRadius(4)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(carta.name)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let expansionName = carta.expansionName {
                        Text(expansionName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text(carta.expansionCode)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("#\(carta.cardNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let rarity = carta.rarity {
                    Text(rarity)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }

                // Variants summary
                if let variants = carta.variants, !variants.isEmpty {
                    Text("\(variants.count) variante(s)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            // Price column
            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedPrice(carta.price, currency: "USD"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(formattedPriceMXN(carta.price))
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 4)
    }

    private func formattedPrice(_ price: Decimal?, currency: String?) -> String {
        guard let price = price else { return "Sin precio" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency ?? "USD"
        return formatter.string(from: price as NSDecimalNumber) ?? "Sin precio"
    }

    private func formattedPriceMXN(_ priceUSD: Decimal?) -> String {
        guard let priceUSD = priceUSD else { return "—" }
        let priceMXN = priceUSD * Decimal(usdToMxnRate)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: priceMXN as NSDecimalNumber) ?? "—"
    }
}

#Preview {
    SearchView()
        .modelContainer(for: [Carta.self, GameSet.self], inMemory: true)
}
