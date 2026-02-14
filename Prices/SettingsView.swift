import SwiftData
import SwiftUI

struct SettingsView: View {
    @Binding var apiKey: String
    @AppStorage("usdToMxnRate") private var usdToMxnRate: Double = 18.5
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var isRefreshingSets = false
    @State private var refreshMessage: String?
    @State private var showAlert = false
    @State private var rateText: String = ""
    @State private var isUpdatingCards = false
    @State private var updateProgress: String?
    @State private var isUpdatingRate = false
    @State private var rateUpdateMessage: String?
    @Query private var cartas: [Carta]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("JustTCG API")) {
                    SecureField("API Key", text: $apiKey)
                        .autocorrectionDisabled()
                        .textFieldStyle(.plain)
                        .padding(.vertical, 8)
                }
                Section {
                    Text(
                        "Obtén tu clave en justtcg.com/dashboard/plans y guárdala aquí para usarla en las llamadas de red."
                    )
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
                }

                Section(header: Text("Tipo de Cambio")) {
                    HStack {
                        Text("USD a MXN:")
                        Spacer()
                        TextField("18.5", text: $rateText)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .onChange(of: rateText) { oldValue, newValue in
                                if let rate = Double(newValue) {
                                    usdToMxnRate = rate
                                }
                            }
                    }
                    .padding(.vertical, 4)

                    Button {
                        Task {
                            await updateExchangeRate()
                        }
                    } label: {
                        HStack {
                            if isUpdatingRate {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Obteniendo tasa...")
                            } else {
                                Label(
                                    "Actualizar Tasa Automáticamente",
                                    systemImage: "arrow.triangle.2.circlepath")
                            }
                        }
                    }
                    .disabled(isUpdatingRate)
                    .padding(.vertical, 4)

                    if let message = rateUpdateMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(message.hasPrefix("✅") ? .green : .orange)
                            .padding(.vertical, 4)
                    }

                    Text("Tasa de conversión de dólares a pesos mexicanos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Expansiones")) {
                    Button {
                        Task {
                            await refreshSets()
                        }
                    } label: {
                        HStack {
                            if isRefreshingSets {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Actualizando...")
                            } else {
                                Label("Actualizar Sets", systemImage: "arrow.clockwise")
                            }
                        }
                    }
                    .disabled(isRefreshingSets || apiKey.isEmpty)
                    .padding(.vertical, 4)

                    if let message = refreshMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                }

                Section(header: Text("Cartas")) {
                    Button {
                        Task {
                            await updateAllCards()
                        }
                    } label: {
                        HStack {
                            if isUpdatingCards {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Actualizando...")
                            } else {
                                Label(
                                    "Actualizar Todas las Cartas",
                                    systemImage: "arrow.triangle.2.circlepath")
                            }
                        }
                    }
                    .disabled(isUpdatingCards || apiKey.isEmpty || cartas.isEmpty)
                    .padding(.vertical, 4)

                    if let progress = updateProgress {
                        Text(progress)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }

                    Text("Total de cartas: \(cartas.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Guardar y Cerrar")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.vertical, 8)
                }
            }
            .formStyle(.grouped)
            .padding()
            .navigationTitle("Configuración")
            .onAppear {
                rateText = String(format: "%.2f", usdToMxnRate)
            }
        }
    }

    private func refreshSets() async {
        guard !apiKey.isEmpty else {
            refreshMessage = "Por favor, configura tu API key primero"
            return
        }

        isRefreshingSets = true
        refreshMessage = nil

        do {
            let service = CartaService()
            let dtos = try await service.fetchSets(game: "pokemon")

            // Convert DTOs to models and save to SwiftData
            for dto in dtos {
                let gameSet = dto.toModel()
                modelContext.insert(gameSet)
            }

            try modelContext.save()

            refreshMessage = "✅ \(dtos.count) sets actualizados"
        } catch {
            refreshMessage = "❌ Error: \(error.localizedDescription)"
        }

        isRefreshingSets = false
    }

    private func updateAllCards() async {
        guard !apiKey.isEmpty else {
            updateProgress = "Por favor, configura tu API key primero"
            return
        }

        guard !cartas.isEmpty else {
            updateProgress = "No hay cartas para actualizar"
            return
        }

        isUpdatingCards = true
        updateProgress = "Iniciando actualización..."

        var successCount = 0
        var errorCount = 0

        for (index, carta) in cartas.enumerated() {
            updateProgress = "Actualizando \(index + 1) de \(cartas.count)..."

            do {
                let service = CartaService()
                var fetchedCard: Carta? = nil

                // Si tenemos api_card_id, buscar por ID directamente (más preciso)
                if let apiCardId = carta.api_card_id, !apiCardId.isEmpty {
                    print("🔍 [SettingsView] Buscando por ID: \(apiCardId)")
                    fetchedCard = try await service.fetchCard(apiId: apiCardId)
                } else {
                    // Fallback: buscar por nombre y expansión
                    print("🔍 [SettingsView] Buscando por nombre: \(carta.name)")
                    let fetchedCards = try await service.fetchCardByName(
                        cardName: carta.name,
                        setId: carta.expansionCode
                    )
                    fetchedCard = fetchedCards.first
                }

                if let fetchedCard = fetchedCard {
                    // Actualizar información de la carta (mantener id y tagId originales)
                    carta.apiId = fetchedCard.apiId
                    carta.api_card_id = fetchedCard.api_card_id
                    carta.name = fetchedCard.name
                    carta.game = fetchedCard.game
                    carta.expansionName = fetchedCard.expansionName
                    carta.cardNumber = fetchedCard.cardNumber
                    carta.rarity = fetchedCard.rarity
                    carta.tcgplayerId = fetchedCard.tcgplayerId
                    carta.details = fetchedCard.details
                    carta.imageURL = fetchedCard.imageURL
                    carta.price = fetchedCard.price
                    carta.currency = fetchedCard.currency
                    // tagId se mantiene automáticamente

                    // Eliminar variantes antiguas del contexto
                    if let oldVariants = carta.variants {
                        for variant in oldVariants {
                            modelContext.delete(variant)
                        }
                    }

                    // Actualizar variantes
                    carta.variants = []
                    if let fetchedVariants = fetchedCard.variants {
                        for variant in fetchedVariants {
                            variant.carta = carta
                            carta.variants?.append(variant)
                            modelContext.insert(variant)
                        }
                    }

                    successCount += 1
                    print("✅ [SettingsView] Actualizada: \(carta.name)")
                } else {
                    errorCount += 1
                    print("⚠️ [SettingsView] No se encontró: \(carta.name)")
                }
            } catch {
                errorCount += 1
                print("❌ [SettingsView] Error actualizando \(carta.name): \(error)")
            }

            // Pequeña pausa para no saturar el API
            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 segundos
        }

        try? modelContext.save()

        updateProgress = "✅ Actualización completa: \(successCount) exitosas, \(errorCount) errores"
        isUpdatingCards = false
    }

    private func updateExchangeRate() async {
        isUpdatingRate = true
        rateUpdateMessage = "Consultando tasa de cambio..."

        do {
            let service = CurrencyService()
            let newRate = try await service.fetchUSDtoMXNRate()

            // Actualizar la tasa y el campo de texto
            usdToMxnRate = newRate
            rateText = String(format: "%.2f", newRate)

            rateUpdateMessage = "✅ Tasa actualizada: $\(String(format: "%.2f", newRate)) MXN"
            print("✅ [SettingsView] Exchange rate updated: \(newRate)")
        } catch {
            rateUpdateMessage = "❌ Error obteniendo tasa: \(error.localizedDescription)"
            print("❌ [SettingsView] Error updating exchange rate: \(error)")
        }

        isUpdatingRate = false
    }
}

#Preview {
    SettingsView(apiKey: .constant(""))
}
