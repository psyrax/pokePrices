//
//  CartaService.swift
//  Prices
//
//  Service to query the JustTCG API and map results to `Carta`.
//

import Foundation
import SwiftData

enum CartaServiceError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
}

final class CartaService {
    private let apiKey: String?
    private let session: URLSession
    private let baseURL = "https://api.justtcg.com/v1"

    init(
        apiKey: String? = UserDefaults.standard.string(forKey: "justTcgApiKey"),
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.session = session
    }

    /// Search cards by name (simple q=name:<query>)
    func search(query: String, page: Int = 1, pageSize: Int = 20) async throws -> [Carta] {
        guard var components = URLComponents(string: "\(baseURL)/cards") else {
            throw CartaServiceError.invalidURL
        }

        // Build a simple query that searches by name with quotes around the term.
        let q = query

        components.queryItems = [
            URLQueryItem(name: "q", value: q),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
        ]

        guard let url = components.url else { throw CartaServiceError.invalidURL }

        var request = URLRequest(url: url)
        if let key = apiKey { request.setValue(key, forHTTPHeaderField: "X-Api-Key") }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode)
            else {
                throw CartaServiceError.invalidResponse
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let resp = try decoder.decode(CardsResponse.self, from: data)
            // Map DTOs to Carta instances
            return resp.data.map { dto in
                map(dto: dto)
            }
        } catch let err as CartaServiceError {
            throw err
        } catch {
            throw CartaServiceError.requestFailed(error)
        }
    }

    /// Fetch cards by name using search query - returns all matches
    func fetchCardByName(cardName: String, setId: String) async throws -> [Carta] {
        print("🔍 [CartaService] Buscando carta por nombre: \(cardName) en set: \(setId)")

        guard var components = URLComponents(string: "\(baseURL)/cards") else {
            print("❌ [CartaService] URL inválida")
            throw CartaServiceError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "q", value: cardName),
            URLQueryItem(name: "set", value: setId),
        ]

        guard let url = components.url else {
            print("❌ [CartaService] No se pudo construir la URL")
            throw CartaServiceError.invalidURL
        }

        print("🌐 [CartaService] URL: \(url.absoluteString)")

        var request = URLRequest(url: url)
        if let key = apiKey {
            request.setValue(key, forHTTPHeaderField: "x-api-key")
            print("🔑 [CartaService] API Key configurada: \(key.prefix(10))...")
        } else {
            print("⚠️ [CartaService] No hay API Key configurada")
        }

        do {
            print("📡 [CartaService] Realizando request...")
            let (data, response) = try await session.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("📥 [CartaService] Response status: \(httpResponse.statusCode)")
            }

            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode)
            else {
                if let httpResponse = response as? HTTPURLResponse {
                    print("❌ [CartaService] Error HTTP: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("❌ [CartaService] Response body: \(responseString)")
                    }
                }
                throw CartaServiceError.invalidResponse
            }

            print("📦 [CartaService] Decodificando respuesta...")
            let decoder = JSONDecoder()
            let resp = try decoder.decode(CardsResponse.self, from: data)

            print("✅ [CartaService] Cartas encontradas: \(resp.data.count)")

            // Return all cards found
            return resp.data.map { dto in
                print("✅ [CartaService] Mapeando carta: \(dto.name ?? "(sin nombre)")")
                return map(dto: dto)
            }
        } catch let err as CartaServiceError {
            print("❌ [CartaService] Error del servicio: \(err)")
            throw err
        } catch let decodingError as DecodingError {
            print("❌ [CartaService] Error de decodificación: \(decodingError)")
            throw CartaServiceError.decodingFailed(decodingError)
        } catch {
            print("❌ [CartaService] Error inesperado: \(error)")
            throw CartaServiceError.requestFailed(error)
        }
    }

    /// Fetch a single card by API id
    func fetchCard(apiId: String) async throws -> Carta? {
        guard let url = URL(string: "\(baseURL)/cards/\(apiId)") else {
            throw CartaServiceError.invalidURL
        }
        var request = URLRequest(url: url)
        if let key = apiKey { request.setValue(key, forHTTPHeaderField: "x-api-key") }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode)
            else {
                throw CartaServiceError.invalidResponse
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let single = try decoder.decode(SingleCardResponse.self, from: data)
            return map(dto: single.data)
        } catch {
            throw CartaServiceError.requestFailed(error)
        }
    }

    /// Fetch sets for a specific game (defaults to Pokemon)
    func fetchSets(game: String = "pokemon") async throws -> [GameSetDTO] {
        print("🔍 fetchSets: Iniciando para game: \(game)...")

        guard var components = URLComponents(string: "\(baseURL)/sets") else {
            print("❌ fetchSets: URL base inválida")
            throw CartaServiceError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "game", value: game),
            URLQueryItem(name: "orderBy", value: "release_date"),
            URLQueryItem(name: "order", value: "desc"),
        ]

        guard let url = components.url else {
            print("❌ fetchSets: No se pudo construir URL con query")
            throw CartaServiceError.invalidURL
        }

        print("🔍 fetchSets: URL completa: \(url.absoluteString)")

        var request = URLRequest(url: url)
        if let key = apiKey {
            request.setValue(key, forHTTPHeaderField: "x-api-key")
            print("🔍 fetchSets: API Key configurada")
        } else {
            print("⚠️ fetchSets: Sin API Key")
        }

        do {
            print("🔍 fetchSets: Enviando request...")
            let (data, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                print("❌ fetchSets: Respuesta no es HTTPURLResponse")
                throw CartaServiceError.invalidResponse
            }

            print("🔍 fetchSets: Status code: \(http.statusCode)")

            guard (200...299).contains(http.statusCode) else {
                print("❌ fetchSets: Status code inválido: \(http.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 fetchSets: Respuesta: \(responseString)")
                }
                throw CartaServiceError.invalidResponse
            }

            let decoder = JSONDecoder()

            do {
                let resp = try decoder.decode(SetsResponse.self, from: data)
                print("✅ fetchSets: Decodificado \(resp.data.count) sets exitosamente")
                return resp.data
            } catch {
                print("❌ fetchSets: Error al decodificar JSON: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 fetchSets: JSON recibido: \(responseString.prefix(500))")
                }
                throw CartaServiceError.decodingFailed(error)
            }
        } catch let err as CartaServiceError {
            print("❌ fetchSets: CartaServiceError: \(err)")
            throw err
        } catch {
            print("❌ fetchSets: Error general: \(error)")
            throw CartaServiceError.requestFailed(error)
        }
    }

    // MARK: - Mapping DTO -> Carta
    private func map(dto: CardDTO) -> Carta {
        // Prefer cardmarket averageSellPrice if available
        var priceDecimal: Decimal? = nil
        let currency: String? = "USD"

        // JustTCG: Get the first variant's price (typically Near Mint)
        if let variants = dto.variants, let firstVariant = variants.first,
            let price = firstVariant.price
        {
            priceDecimal = Decimal(price)
        }

        if priceDecimal == nil, let cp = dto.cardmarket?.prices {
            if let avg = cp.averageSellPrice {
                priceDecimal = Decimal(avg)
            } else if let trend = cp.trendPrice {
                priceDecimal = Decimal(trend)
            } else if let low = cp.lowPrice {
                priceDecimal = Decimal(low)
            }
        }

        // Fallback to other provider fields if needed
        if priceDecimal == nil {
            // try tcgplayer.price fields (if available) - the structure varies so we attempt a best-effort
            if let tcg = dto.tcgplayer, let prices = tcg.prices {
                // try common keys
                if let market = prices.market?.marketPrice {
                    priceDecimal = Decimal(market)
                } else if let average = prices.averageMarketPrice {
                    priceDecimal = Decimal(average)
                }
            }
        }

        let expansion = dto.set ?? ""
        let expansionName = dto.setName
        let number = dto.number ?? ""
        let name = dto.name ?? ""
        let imageURL = dto.images?.small

        // Map variants from DTO to CartaVariant objects
        var cartaVariants: [CartaVariant] = []
        if let variants = dto.variants {
            print("📦 [CartaService] Procesando \(variants.count) variantes")
            for variantDTO in variants {
                if let condition = variantDTO.condition,
                    let printing = variantDTO.printing,
                    let price = variantDTO.price,
                    let lastUpdated = variantDTO.lastUpdated
                {
                    let variant = CartaVariant(
                        condition: condition,
                        printing: printing,
                        price: Decimal(price),
                        lastUpdated: lastUpdated
                    )
                    cartaVariants.append(variant)
                    print("  ✅ Variante: \(condition) - \(printing) - $\(price)")
                }
            }
        }

        let carta = Carta(
            apiId: dto.id,
            api_card_id: dto.id,
            name: name,
            game: dto.game,
            expansionCode: expansion,
            expansionName: expansionName,
            cardNumber: number,
            rarity: dto.rarity,
            tcgplayerId: dto.tcgplayerId,
            details: dto.details,
            imageURL: imageURL,
            price: priceDecimal,
            currency: currency,
            variants: cartaVariants
        )
        return carta
    }
}

// MARK: - DTOs for decoding PokéTcg API

private struct CardsResponse: Decodable {
    let data: [CardDTO]
}

private struct SingleCardResponse: Decodable {
    let data: CardDTO
}

private struct CardDTO: Decodable {
    let id: String
    let name: String?
    let game: String?
    let number: String?
    let rarity: String?
    let tcgplayerId: String?
    let details: String?
    let set: String?  // JustTCG returns set as a string (the set ID)
    let setName: String?  // set_name in snake_case
    let variants: [VariantDTO]?  // JustTCG pricing is in variants array
    let images: ImageDTO?
    let cardmarket: CardMarketDTO?
    let tcgplayer: TcgPlayerDTO?

    private enum CodingKeys: String, CodingKey {
        case id, name, game, number, rarity, details, set, variants, images, cardmarket, tcgplayer
        case setName = "set_name"
        case tcgplayerId
    }
}

private struct VariantDTO: Decodable {
    let condition: String?
    let printing: String?
    let price: Double?
    let lastUpdated: Int?

    private enum CodingKeys: String, CodingKey {
        case condition, printing, price
        case lastUpdated = "lastUpdated"
    }
}

private struct ImageDTO: Decodable {
    let small: URL?
    let large: URL?
}

private struct CardMarketDTO: Decodable {
    let prices: CardMarketPrices?
}

private struct CardMarketPrices: Decodable {
    let averageSellPrice: Double?
    let lowPrice: Double?
    let trendPrice: Double?
}

// TcgPlayer structures are variable; here's a conservative attempt
private struct TcgPlayerDTO: Decodable {
    let prices: TcgPlayerPrices?
}

private struct TcgPlayerPrices: Decodable {
    // Common fields (best-effort). Some responses embed different structure; keep optional
    let market: MarketPriceContainer?
    let averageMarketPrice: Double?

    private enum CodingKeys: String, CodingKey {
        case market
        case averageMarketPrice
    }
}

private struct MarketPriceContainer: Decodable {
    let marketPrice: Double?
}
