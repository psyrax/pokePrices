//
//  Carta.swift
//  Prices
//
//  Created by Copilot on 01/02/26.
//

import Foundation
import SwiftData

enum CartaListType: String, Codable, CaseIterable {
    case forSale = "forSale"
    case wantToBuy = "wantToBuy"
}

@Model
final class Carta: Identifiable {
    // Identificador único
    var id: UUID = UUID()

    // Tipo de lista: en venta o quiero comprar
    var listTypeRaw: String = CartaListType.forSale.rawValue

    var listType: CartaListType {
        get { CartaListType(rawValue: listTypeRaw) ?? .forSale }
        set { listTypeRaw = newValue.rawValue }
    }

    // ID de la carta en JustTCG API
    var apiId: String?

    // ID completo de la carta en el API (ej: "pokemon-me01-mega-evolution-celebi-uncommon")
    var api_card_id: String?

    // Nombre de la carta
    var name: String

    // Juego (Pokemon, Magic, etc.)
    var game: String?

    // Código de la expansión (p. ej. "SWSH", "SM", etc.)
    var expansionCode: String

    // Nombre de la expansión
    var expansionName: String?

    // Número de la carta dentro de la expansión (uso String por flexibilidad)
    var cardNumber: String

    // Rareza de la carta
    var rarity: String?

    // ID de TCGPlayer
    var tcgplayerId: String?

    // Detalles adicionales
    var details: String?

    // URL de imagen de la carta (pequeña o principal)
    var imageURL: URL?

    // Precio de la carta (uso Decimal para precisión monetaria). Opcional si no hay datos.
    var price: Decimal?

    // Moneda del precio (p.ej. "USD").
    var currency: String?

    // ID del tag NFC asociado (para deep linking ogl://card?id=X)
    var tagId: String?

    // Variantes de la carta (diferentes condiciones y printings con precios)
    @Relationship(deleteRule: .cascade, inverse: \CartaVariant.carta)
    var variants: [CartaVariant]? = []

    init(
        id: UUID = UUID(),
        apiId: String? = nil,
        api_card_id: String? = nil,
        name: String,
        game: String? = nil,
        expansionCode: String,
        expansionName: String? = nil,
        cardNumber: String,
        rarity: String? = nil,
        tcgplayerId: String? = nil,
        details: String? = nil,
        imageURL: URL? = nil,
        price: Decimal? = nil,
        currency: String? = "USD",
        tagId: String? = nil,
        variants: [CartaVariant]? = [],
        listType: CartaListType = .forSale
    ) {
        self.id = id
        self.apiId = apiId
        self.api_card_id = api_card_id
        self.name = name
        self.game = game
        self.expansionCode = expansionCode
        self.expansionName = expansionName
        self.cardNumber = cardNumber
        self.rarity = rarity
        self.tcgplayerId = tcgplayerId
        self.tagId = tagId
        self.details = details
        self.imageURL = imageURL
        self.price = price
        self.currency = currency
        self.variants = variants
        self.listTypeRaw = listType.rawValue
    }
}
