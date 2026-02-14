import SwiftData
import SwiftUI

struct CartaEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GameSet.releaseDate, order: .reverse) private var storedSets: [GameSet]
    @Bindable var carta: Carta

    @State private var priceText: String
    @State private var imageURLText: String
    @State private var selectedSet: GameSet?
    @State private var isFetchingCardInfo = false
    @State private var fetchMessage: String?
    @State private var showCardSelection = false
    @State private var foundCards: [Carta] = []

    init(carta: Carta) {
        _carta = Bindable(wrappedValue: carta)
        _priceText = State(initialValue: carta.price?.description ?? "")
        _imageURLText = State(initialValue: carta.imageURL?.absoluteString ?? "")
    }

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
        Form {
            Section("Datos") {
                TextField("Nombre", text: $carta.name)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Expansión", selection: $selectedSet) {
                            Text("Selecciona una expansión").tag(nil as GameSet?)
                            ForEach(sortedSets) { set in
                                if let releaseDate = set.releaseDate {
                                    Text("\(set.name) (\(formatDate(releaseDate)))").tag(
                                        set as GameSet?)
                                } else {
                                    Text(set.name).tag(set as GameSet?)
                                }
                            }
                        }
                        .onChange(of: selectedSet) { _, newSet in
                            if let newSet = newSet {
                                carta.expansionCode = newSet.id
                                carta.expansionName = newSet.name
                            }
                        }

                        if let selected = selectedSet {
                            HStack {
                                Text("Código:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(selected.id)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    Text("Sets disponibles: \(sortedSets.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)

                TextField("Número de carta", text: $carta.cardNumber)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 4)

                Button {
                    Task {
                        await fetchCardInfo()
                    }
                } label: {
                    HStack {
                        if isFetchingCardInfo {
                            ProgressView()
                                .controlSize(.small)
                            Text("Obteniendo información...")
                        } else {
                            Label(
                                "Obtener Información del API", systemImage: "arrow.down.circle.fill"
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(selectedSet == nil || carta.name.isEmpty || isFetchingCardInfo)
                .padding(.vertical, 4)

                if let message = fetchMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(message.hasPrefix("✅") ? .green : .orange)
                        .padding(.vertical, 4)
                }
            }

            Section("Imagen") {
                TextField("URL de imagen", text: $imageURLText)
                    .autocorrectionDisabled()
                    .textFieldStyle(.plain)
                    .padding(.vertical, 4)
                    .onChange(of: imageURLText) { _, newValue in
                        carta.imageURL = URL(string: newValue)
                    }
                if let url = carta.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 160)
                                .padding(.vertical, 8)
                        case .failure:
                            Label("No se pudo cargar", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                                .padding()
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Section("Precio") {
                TextField("Precio", text: $priceText)
                    #if os(iOS)
                        .keyboardType(.decimalPad)
                    #endif
                    .textFieldStyle(.plain)
                    .padding(.vertical, 4)
                    .onChange(of: priceText) { _, newValue in
                        let normalized = newValue.replacingOccurrences(of: ",", with: ".")
                        carta.price = Decimal(string: normalized)
                    }
                TextField(
                    "Moneda",
                    text: Binding(
                        get: { carta.currency ?? "USD" },
                        set: { carta.currency = $0.isEmpty ? nil : $0 }
                    )
                )
                .textFieldStyle(.plain)
                .padding(.vertical, 4)
            }

            Section("Tag NFC") {
                TextField(
                    "Tag ID (para ogl://card?id=X)",
                    text: Binding(
                        get: { carta.tagId ?? "" },
                        set: { carta.tagId = $0.isEmpty ? nil : $0 }
                    )
                )
                .textFieldStyle(.plain)
                .padding(.vertical, 4)

                if let tagId = carta.tagId, !tagId.isEmpty {
                    Text("URL: ogl://card?id=\(tagId)")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.vertical, 2)
                }
            }

            Section {
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Cancelar")
                            Spacer()
                        }
                    }
                    .buttonStyle(.bordered)

                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Guardar")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 8)
            }
        }
        .formStyle(.grouped)
        .padding()
        .navigationTitle("Editar carta")
        .sheet(isPresented: $showCardSelection) {
            CardSelectionView(
                cards: foundCards,
                selectedCard: Binding(
                    get: { nil },
                    set: { selectedCard in
                        if let selectedCard = selectedCard {
                            applyCardData(from: selectedCard)
                        }
                    }
                ))
        }
        .task {
            // Match the current expansion code to a stored set
            if let current = sortedSets.first(where: { $0.id == carta.expansionCode }) {
                selectedSet = current
            }
        }
    }

    private func fetchCardInfo() async {
        guard let selectedSet = selectedSet else {
            fetchMessage = "⚠️ Selecciona una expansión primero"
            return
        }

        guard !carta.name.isEmpty else {
            fetchMessage = "⚠️ Ingresa un nombre de carta primero"
            return
        }

        print("🔍 [CartaEditView] Iniciando búsqueda de carta")
        print("🔍 [CartaEditView] Nombre: \(carta.name)")
        print("🔍 [CartaEditView] Set: \(selectedSet.id)")

        isFetchingCardInfo = true
        fetchMessage = nil

        do {
            let service = CartaService()

            let fetchedCards = try await service.fetchCardByName(
                cardName: carta.name,
                setId: selectedSet.id
            )

            print("✅ [CartaEditView] Cartas encontradas: \(fetchedCards.count)")

            if fetchedCards.isEmpty {
                print("⚠️ [CartaEditView] No se encontraron cartas")
                fetchMessage = "⚠️ No se encontraron cartas"
            } else if fetchedCards.count == 1 {
                // Solo una carta encontrada, usarla directamente
                let fetchedCard = fetchedCards[0]
                print("✅ [CartaEditView] Carta única: \(fetchedCard.name)")
                applyCardData(from: fetchedCard)
                fetchMessage =
                    "✅ Información actualizada y guardada (\(fetchedCard.variants?.count ?? 0) variantes)"
            } else {
                // Múltiples cartas encontradas, mostrar selección
                print(
                    "🔍 [CartaEditView] Múltiples cartas encontradas (\(fetchedCards.count)), mostrando selección"
                )
                foundCards = fetchedCards
                showCardSelection = true
                fetchMessage = "🔍 Se encontraron \(fetchedCards.count) cartas, selecciona una"
            }
        } catch {
            print("❌ [CartaEditView] Error: \(error)")
            print("❌ [CartaEditView] Error localizado: \(error.localizedDescription)")
            fetchMessage = "❌ Error: \(error.localizedDescription)"
        }

        isFetchingCardInfo = false
    }

    private func applyCardData(from fetchedCard: Carta) {
        print("✅ [CartaEditView] Aplicando datos de: \(fetchedCard.name)")
        print("✅ [CartaEditView] Precio: \(fetchedCard.price?.description ?? "nil")")
        print("✅ [CartaEditView] Imagen: \(fetchedCard.imageURL?.absoluteString ?? "nil")")
        print("✅ [CartaEditView] Variantes: \(fetchedCard.variants?.count ?? 0)")

        // Update all card information from API
        carta.apiId = fetchedCard.apiId
        carta.api_card_id = fetchedCard.api_card_id
        carta.name = fetchedCard.name
        carta.game = fetchedCard.game
        carta.expansionCode = fetchedCard.expansionCode
        carta.expansionName = fetchedCard.expansionName
        carta.cardNumber = fetchedCard.cardNumber
        carta.rarity = fetchedCard.rarity
        carta.tcgplayerId = fetchedCard.tcgplayerId
        carta.details = fetchedCard.details
        carta.imageURL = fetchedCard.imageURL
        carta.price = fetchedCard.price
        carta.currency = fetchedCard.currency

        // Remove old variants and add new ones
        carta.variants?.removeAll()
        if let fetchedVariants = fetchedCard.variants {
            for variant in fetchedVariants {
                variant.carta = carta
                carta.variants?.append(variant)
                modelContext.insert(variant)
                print("  💾 Variante guardada: \(variant.condition) - \(variant.printing)")
            }
        }

        // Update UI fields
        imageURLText = fetchedCard.imageURL?.absoluteString ?? ""
        if let price = fetchedCard.price {
            priceText = price.description
        }

        fetchMessage =
            "✅ Información actualizada y guardada (\(fetchedCard.variants?.count ?? 0) variantes)"
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        displayFormatter.locale = Locale(identifier: "es_ES")

        return displayFormatter.string(from: date)
    }
}

extension CartaEditView {
    fileprivate static var previewContainer: ModelContainer {
        let schema = Schema([Carta.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        SampleData.cartas.forEach { context.insert($0) }
        return container
    }
}

#Preview {
    NavigationStack {
        CartaEditView(carta: SampleData.cartas.first!)
    }
    .modelContainer(CartaEditView.previewContainer)
}
