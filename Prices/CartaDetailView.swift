import SwiftData
import SwiftUI

struct CartaDetailView: View {
    let carta: Carta
    @AppStorage("usdToMxnRate") private var usdToMxnRate: Double = 18.5
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let url = carta.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 240)
                        case .failure:
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                Group {
                    Text(carta.name)
                        .font(.title2)
                        .bold()
                    Text("Expansión: \(carta.expansionCode)")
                    Text("Número: \(carta.cardNumber)")

                    if let game = carta.game {
                        Text("Juego: \(game)")
                    }

                    if let rarity = carta.rarity {
                        Text("Rareza: \(rarity)")
                    }

                    if let apiCardId = carta.api_card_id {
                        Text("API ID: \(apiCardId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Precio USD: \(formattedPrice(carta.price, currency: "USD"))")
                        Text("Precio MXN: \(formattedPriceMXN(carta.price))")
                            .foregroundColor(.green)
                    }
                }

                // Sección de variantes
                if let variants = carta.variants, !variants.isEmpty {
                    Divider()

                    Text("Variantes (\(variants.count))")
                        .font(.headline)
                        .padding(.top, 8)

                    ForEach(variants) { variant in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(variant.condition)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(formattedPrice(variant.price, currency: "USD"))
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                    Text(formattedPriceMXN(variant.price))
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            Text("\(variant.printing)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Actualizado: \(formattedDate(variant.lastUpdated))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Detalle")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cerrar") {
                    dismiss()
                }
            }
        }
        #if os(macOS)
            .frame(minWidth: 500, minHeight: 600)
        #endif
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

    private func formattedDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
}

extension CartaDetailView {
    fileprivate static var previewContainer: ModelContainer {
        let schema = Schema([Carta.self, CartaVariant.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        SampleData.cartas.forEach { context.insert($0) }
        return container
    }
}

#Preview {
    NavigationStack {
        CartaDetailView(carta: SampleData.cartas.first!)
    }
    .modelContainer(CartaDetailView.previewContainer)
}
