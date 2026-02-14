//
//  WantToBuyListView.swift
//  Prices
//
//  Lista de cartas que queremos comprar.
//

import SwiftData
import SwiftUI

struct WantToBuyListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allCartas: [Carta]
    @State private var editingCarta: Carta?
    @State private var detailCarta: Carta?
    @AppStorage("usdToMxnRate") private var usdToMxnRate: Double = 18.5

    private var cartas: [Carta] {
        allCartas.filter { $0.listType == .wantToBuy }
    }

    var sortedCartas: [Carta] {
        cartas.sorted { carta1, carta2 in
            carta1.name < carta2.name
        }
    }

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(sortedCartas) { carta in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Text(carta.name)
                                .font(.headline)
                            if let expansionName = carta.expansionName {
                                Text("\(expansionName) #\(carta.cardNumber)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(carta.expansionCode) #\(carta.cardNumber)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formattedPrice(carta.price, currency: "USD"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(formattedPriceMXN(carta.price))
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        Button {
                            detailCarta = carta
                        } label: {
                            Image(systemName: "eye")
                        }
                        .buttonStyle(.borderless)
                        Button {
                            editingCarta = carta
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            #if os(macOS)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            #endif
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                #endif
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Agregar carta", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Quiero Comprar")
        } detail: {
            Text("Selecciona una carta")
        }
        .sheet(item: $editingCarta) { carta in
            CartaEditView(carta: carta)
        }
        .sheet(item: $detailCarta) { carta in
            NavigationStack {
                CartaDetailView(carta: carta)
            }
            #if os(macOS)
                .frame(minWidth: 550, minHeight: 650)
            #endif
        }
    }

    private func formattedPrice(_ price: Decimal?, currency: String?) -> String {
        guard let price = price else { return "Sin precio" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency ?? "USD"
        return formatter.string(from: price as NSDecimalNumber) ?? "Sin precio"
    }

    private func formattedPriceMXN(_ priceUSD: Decimal?) -> String {
        guard let priceUSD = priceUSD else { return "Sin precio" }
        let priceMXN = priceUSD * Decimal(usdToMxnRate)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: priceMXN as NSDecimalNumber) ?? "Sin precio"
    }

    private func addItem() {
        withAnimation {
            let newCarta = Carta(
                name: "Nueva carta",
                expansionCode: "SWSH",
                cardNumber: "1/202",
                imageURL: nil,
                price: Decimal(string: "0.0"),
                currency: "USD",
                listType: .wantToBuy
            )
            modelContext.insert(newCarta)
            editingCarta = newCarta
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            let sorted = sortedCartas
            for index in offsets {
                modelContext.delete(sorted[index])
            }
        }
    }
}

#Preview {
    WantToBuyListView()
        .modelContainer(for: Carta.self, inMemory: true)
}
