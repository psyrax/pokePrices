//
//  GameSet.swift
//  Prices
//
//  Model for JustTCG API sets
//

import Foundation
import SwiftData

@Model
final class GameSet {
    @Attribute(.unique) var id: String
    var name: String
    var gameId: String
    var game: String
    var releaseDate: String?
    var cardsCount: Int

    init(
        id: String, name: String, gameId: String, game: String, releaseDate: String?,
        cardsCount: Int
    ) {
        self.id = id
        self.name = name
        self.gameId = gameId
        self.game = game
        self.releaseDate = releaseDate
        self.cardsCount = cardsCount
    }
}

// DTO para decodificar del API
struct GameSetDTO: Codable {
    let id: String
    let name: String
    let gameId: String
    let game: String
    let releaseDate: String?
    let cardsCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case gameId = "game_id"
        case game
        case releaseDate = "release_date"
        case cardsCount = "cards_count"
    }

    func toModel() -> GameSet {
        GameSet(
            id: id, name: name, gameId: gameId, game: game, releaseDate: releaseDate,
            cardsCount: cardsCount)
    }
}

struct SetsResponse: Codable {
    let data: [GameSetDTO]
}
