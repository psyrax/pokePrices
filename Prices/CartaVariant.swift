//
//  CartaVariant.swift
//  Prices
//
//  Created by Copilot on 01/02/26.
//

import Foundation
import SwiftData

@Model
final class CartaVariant: Identifiable {
    // Identificador único
    var id: UUID = UUID()

    // Condición de la carta (e.g., "Near Mint", "Lightly Played", "Moderately Played")
    var condition: String

    // Tipo de impresión (e.g., "Normal", "Reverse Holofoil")
    var printing: String

    // Precio de esta variante
    var price: Decimal

    // Última actualización (timestamp Unix)
    var lastUpdated: Int

    // Relación inversa con Carta
    var carta: Carta?

    init(
        id: UUID = UUID(),
        condition: String,
        printing: String,
        price: Decimal,
        lastUpdated: Int
    ) {
        self.id = id
        self.condition = condition
        self.printing = printing
        self.price = price
        self.lastUpdated = lastUpdated
    }
}
