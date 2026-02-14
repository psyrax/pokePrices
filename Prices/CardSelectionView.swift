//
//  CardSelectionView.swift
//  Prices
//
//  Created by Psyrax on 01/02/26.
//

import SwiftUI

struct CardSelectionView: View {
    let cards: [Carta]
    @Binding var selectedCard: Carta?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(cards) { card in
                Button {
                    selectedCard = card
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(card.name)
                            .font(.headline)

                        HStack {
                            if let rarity = card.rarity {
                                Text(rarity)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if let price = card.price {
                                Text(formattedPrice(price))
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }

                        if let variants = card.variants, !variants.isEmpty {
                            Text("\(variants.count) variante(s)")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Selecciona una carta")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func formattedPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: price as NSDecimalNumber) ?? "Sin precio"
    }
}
