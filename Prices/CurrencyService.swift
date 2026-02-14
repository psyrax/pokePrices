//
//  CurrencyService.swift
//  Prices
//
//  Service to fetch current USD to MXN exchange rate
//

import Foundation

enum CurrencyServiceError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
}

final class CurrencyService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetch current USD to MXN exchange rate from exchangerate-api.com
    func fetchUSDtoMXNRate() async throws -> Double {
        // Using exchangerate-api.com free API (no key required)
        guard let url = URL(string: "https://open.er-api.com/v6/latest/USD")
        else {
            throw CurrencyServiceError.invalidURL
        }

        print("🔍 [CurrencyService] Fetching USD to MXN rate...")

        do {
            let (data, response) = try await session.data(from: url)

            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode)
            else {
                print("❌ [CurrencyService] Invalid response")
                throw CurrencyServiceError.invalidResponse
            }

            let decoder = JSONDecoder()
            let rateResponse = try decoder.decode(ExchangeRateResponse.self, from: data)

            guard let mxnRate = rateResponse.rates["MXN"] else {
                print("❌ [CurrencyService] MXN rate not found in response")
                throw CurrencyServiceError.invalidResponse
            }

            print("✅ [CurrencyService] Rate fetched: 1 USD = \(mxnRate) MXN")
            return mxnRate

        } catch let err as CurrencyServiceError {
            throw err
        } catch let decodingError as DecodingError {
            print("❌ [CurrencyService] Decoding error: \(decodingError)")
            throw CurrencyServiceError.decodingFailed(decodingError)
        } catch {
            print("❌ [CurrencyService] Request failed: \(error)")
            throw CurrencyServiceError.requestFailed(error)
        }
    }
}

// MARK: - DTOs

private struct ExchangeRateResponse: Decodable {
    let rates: [String: Double]
}
