import Foundation

enum SampleData {
    static let cartas: [Carta] = [
        Carta(
            name: "Charizard",
            expansionCode: "Base Set",
            cardNumber: "4/102",
            imageURL: URL(string: "https://images.pokemontcg.io/base1/4.png"),
            price: Decimal(string: "12.50"),
            currency: "USD",
            tagId: "1"
        ),
        Carta(
            name: "Umbreon VMAX",
            expansionCode: "Evolving Skies",
            cardNumber: "TG15/TG30",
            imageURL: URL(string: "https://images.pokemontcg.io/swsh07/215.png"),
            price: Decimal(string: "32.90"),
            currency: "USD",
            tagId: "2"
        ),
        Carta(
            name: "Miraidon ex",
            expansionCode: "Scarlet & Violet",
            cardNumber: "201/198",
            imageURL: URL(string: "https://images.pokemontcg.io/sv01/244.png"),
            price: Decimal(string: "5.75"),
            currency: "USD",
            tagId: "3"
        ),
        Carta(
            name: "Charizard ex",
            expansionCode: "Obsidian Flames",
            cardNumber: "125/197",
            imageURL: URL(string: "https://images.pokemontcg.io/sv03/125.png"),
            price: Decimal(string: "1.20"),
            currency: "USD",
            tagId: "4"
        ),
    ]
}
